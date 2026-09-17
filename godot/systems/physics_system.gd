class_name BohrPhysicsSystem # Recreates the browser particle, capture, atom, and Bohr-shell simulation natively.
extends RefCounted # Keeps deterministic physics logic separate from scene rendering.

var state: BohrGameState # References the shared mutable gameplay state.
var controller: BohrBuilderController # References the native controller for direct UI refresh calls without signals.

func _init(game_state: BohrGameState, game_controller: BohrBuilderController) -> void: # Binds the physics system to shared state and its owning controller.
	state = game_state # Retains shared simulation state.
	controller = game_controller # Retains the direct controller callback target.

func fire_particle(now_ms: float) -> void: # Launches one selected subatomic particle at the original fixed skill-based speed.
	if state.game_mode.is_empty() or state.mode_prompt_open or state.reaction != null or state.freeplay_reaction != null or state.scrap_mode or state.freeplay_select_mode or state.freeplay_verifying: # Blocks firing while another interaction owns the workspace.
		return # Leaves simulation state unchanged.
	if state.molecule_active and state.game_mode != &"freeplay": # Blocks further campaign shots after a product has formed.
		return # Leaves the completed level untouched.
	if now_ms - state.last_shot_time_ms < 115.0: # Preserves the browser build's fire-rate limit.
		return # Rejects a shot that arrives too soon.
	var targeted_atom: AtomState = pick_atom_at(state.pointer_position) if state.selected_particle == &"proton" else null # Preserves proton footprint targeting for existing atoms.
	var direction: Vector2 = state.pointer_position - ChemistryData.CANNON_POSITION # Calculates the intended launch direction.
	var length: float = direction.length() # Measures distance from cannon to aim point.
	if length < 8.0: # Rejects degenerate aim directly on top of the cannon.
		return # Avoids normalizing a near-zero vector.
	direction /= length # Converts the aim direction to a unit vector.
	var particle: ParticleState = ParticleState.new(state.selected_particle) # Allocates one native projectile state object.
	particle.position = ChemistryData.CANNON_POSITION + direction * 34.0 # Starts the projectile just beyond the cannon barrel.
	particle.velocity = direction * ChemistryData.FIXED_LAUNCH_SPEED # Applies the fixed launch speed exactly.
	particle.radius = 5.0 if state.selected_particle == &"electron" else 9.0 # Preserves browser projectile radii.
	particle.target_position = state.pointer_position # Stores the aim point for uncaptured proton nucleus seeding.
	particle.target_atom_id = targeted_atom.id if targeted_atom != null else -1 # Stores the targeted atom for proton footprint capture.
	state.particles.append(particle) # Adds the projectile to active simulation state.
	state.last_shot_time_ms = now_ms # Records the shot timestamp for rate limiting.

func update_particles(delta: float, assist: float) -> void: # Advances projectile motion, forces, wall collisions, and capture tests.
	for particle: ParticleState in state.particles: # Updates every currently active projectile.
		if not particle.alive: # Skips projectiles already consumed earlier in this frame.
			continue # Leaves dead state untouched until compaction.
		particle.age += delta # Advances projectile lifetime.
		_apply_particle_forces(particle, delta) # Applies simplified electrostatic behavior around every atom.
		particle.position += particle.velocity * delta # Integrates projectile position using the original explicit-Euler step.
		if particle.position.x < particle.radius or particle.position.x > ChemistryData.WORLD_SIZE.x - particle.radius: # Detects horizontal boundary contact.
			particle.position.x = clampf(particle.position.x, particle.radius, ChemistryData.WORLD_SIZE.x - particle.radius) # Keeps the projectile inside the workspace.
			particle.velocity.x *= -0.72 # Preserves the browser wall-bounce damping.
		if particle.position.y < particle.radius or particle.position.y > ChemistryData.WORLD_SIZE.y - particle.radius: # Detects vertical boundary contact.
			particle.position.y = clampf(particle.position.y, particle.radius, ChemistryData.WORLD_SIZE.y - particle.radius) # Keeps the projectile inside the workspace.
			particle.velocity.y *= -0.72 # Preserves the browser wall-bounce damping.
		var captured: bool = false # Tracks whether this projectile has been absorbed during the frame.
		for atom: AtomState in state.atoms: # Tests capture against every constructed atom.
			var distance: float = particle.position.distance_to(atom.position) # Measures projectile distance from the atom centre.
			var speed: float = particle.velocity.length() # Measures projectile speed for electron capture rules.
			if particle.kind == &"electron": # Uses shell capture behavior for electrons.
				var shell: int = next_electron_shell(atom) # Determines the principal shell receiving the next electron.
				var shell_radius: float = ChemistryData.SHELL_RADII[shell] # Reads the target Bohr radius.
				var shell_error: float = absf(distance - shell_radius) # Measures radial error from the capture shell.
				var max_capture_speed: float = 780.0 + 120.0 * (assist - 1.0) + float(atom.protons) * 2.2 # Preserves the browser speed tolerance.
				if shell_error < 10.0 * assist and speed > 55.0 and speed < max_capture_speed: # Applies the original shell and velocity capture conditions.
					_capture_electron(particle, atom) # Adds the electron to the atom.
					captured = true # Marks the projectile as consumed.
					break # Stops checking other atoms after capture.
			else: # Uses nucleus capture behavior for protons and neutrons.
				var capture_radius: float = nucleus_radius(atom) + particle.radius + 5.0 + (assist - 1.0) * 11.0 # Preserves the browser nucleus tolerance.
				if distance <= capture_radius: # Detects nucleus overlap within assistance tolerance.
					captured = _capture_nucleon(particle, atom) # Attempts proton or neutron capture.
					break # Stops testing after nucleus contact, including element-cap rebounds.
		if not captured and particle.kind == &"proton" and particle.target_atom_id >= 0: # Applies the special proton footprint rule when a target atom was chosen at firing time.
			var target_atom: AtomState = find_atom_by_id(particle.target_atom_id) # Resolves the targeted atom if it still exists.
			if target_atom != null: # Continues footprint capture only for a live target.
				var outer_shell: float = ChemistryData.SHELL_RADII[maxi(0, next_electron_shell(target_atom))] + 18.0 # Recreates the browser's clickable Bohr footprint.
				if particle.position.distance_to(target_atom.position) <= outer_shell: # Detects entry anywhere inside the target atom footprint.
					captured = _capture_nucleon(particle, target_atom) # Adds the proton to that atom instead of seeding a new one.
			else: # Clears a target that has been scrapped since firing.
				particle.target_atom_id = -1 # Restores ordinary proton seeding behavior.
		if not captured and particle.kind == &"proton" and particle.target_atom_id < 0 and particle.age > 0.03: # Handles uncaptured protons intended to seed a new nucleus.
			if particle.position.distance_to(particle.target_position) < 16.0 * assist: # Detects arrival at the original aim point.
				_create_atom_from_proton(particle) # Creates the new hydrogen nucleus seed.
				particle.alive = false # Consumes the seeding projectile.
		if particle.age > 7.5: # Preserves the browser projectile lifetime limit.
			particle.alive = false # Expires old projectiles that never captured.
	for index: int in range(state.particles.size() - 1, -1, -1): # Compacts dead projectiles in reverse without reallocating a filtered array.
		if not state.particles[index].alive: # Finds one consumed or expired projectile.
			state.particles.remove_at(index) # Removes it from active simulation state.

func update_atoms(delta: float) -> void: # Applies atom drift, damping, pulse decay, and workspace boundaries.
	for atom: AtomState in state.atoms: # Updates every constructed atom or ion.
		atom.position += atom.velocity * delta # Integrates residual atom motion.
		atom.velocity *= pow(0.12, delta) # Preserves browser exponential damping.
		atom.pulse = maxf(0.0, atom.pulse - delta * 2.2) # Fades the capture pulse at the original rate.
		var margin: float = ChemistryData.SHELL_RADII[mini(ChemistryData.SHELL_RADII.size() - 1, next_electron_shell(atom))] + 14.0 # Keeps the complete Bohr model on-screen.
		if atom.position.x < margin: # Detects the left atom boundary.
			atom.position.x = margin # Clamps the atom inside the workspace.
			atom.velocity.x = absf(atom.velocity.x) * 0.3 # Applies the original soft rebound.
		if atom.position.x > ChemistryData.WORLD_SIZE.x - margin: # Detects the right atom boundary.
			atom.position.x = ChemistryData.WORLD_SIZE.x - margin # Clamps the atom inside the workspace.
			atom.velocity.x = -absf(atom.velocity.x) * 0.3 # Applies the original soft rebound.
		if atom.position.y < margin: # Detects the top atom boundary.
			atom.position.y = margin # Clamps the atom inside the workspace.
			atom.velocity.y = absf(atom.velocity.y) * 0.3 # Applies the original soft rebound.
		if atom.position.y > ChemistryData.WORLD_SIZE.y - 90.0 - margin: # Detects the lower construction boundary above the cannon.
			atom.position.y = ChemistryData.WORLD_SIZE.y - 90.0 - margin # Clamps the atom above the cannon zone.
			atom.velocity.y = -absf(atom.velocity.y) * 0.3 # Applies the original soft rebound.

func pick_atom_at(world_position: Vector2) -> AtomState: # Returns the topmost atom whose Bohr footprint contains a world point.
	for index: int in range(state.atoms.size() - 1, -1, -1): # Searches newest/topmost atoms first just like reverse canvas hit testing.
		var atom: AtomState = state.atoms[index] # Reads one candidate atom.
		var outer_shell: float = ChemistryData.SHELL_RADII[maxi(0, next_electron_shell(atom))] # Reads the next relevant Bohr radius.
		if world_position.distance_to(atom.position) <= outer_shell + 18.0: # Tests against the browser atom interaction footprint.
			return atom # Returns the first topmost hit.
	return null # Reports no atom under the point.

func find_atom_by_id(atom_id: int) -> AtomState: # Resolves one live atom from its unique identifier.
	for atom: AtomState in state.atoms: # Searches the small active atom list linearly.
		if atom.id == atom_id: # Matches the requested identifier.
			return atom # Returns the live atom reference.
	return null # Reports that the atom no longer exists.

func nucleus_radius(atom: AtomState) -> float: # Compresses large nuclei so all real elements remain playable and readable.
	return clampf(14.0 + sqrt(float(maxi(1, atom.protons + atom.neutrons))) * 1.25, 15.0, 38.0) # Preserves the browser radius equation exactly.

func next_electron_shell(atom: AtomState) -> int: # Returns the principal Bohr shell receiving the next electron under the browser filling model.
	if atom.electrons >= ChemistryData.MAX_ELECTRONS: # Handles the sandbox electron ceiling.
		return ChemistryData.SHELL_RADII.size() - 1 # Uses the outermost supported shell.
	var before: Array[int] = electron_shell_distribution(atom.electrons) # Calculates shell occupancy before the next electron.
	var after: Array[int] = electron_shell_distribution(atom.electrons + 1) # Calculates shell occupancy after the next electron.
	for shell: int in after.size(): # Finds the first shell whose occupancy increased.
		var before_count: int = before[shell] if shell < before.size() else 0 # Safely reads the previous occupancy.
		if after[shell] > before_count: # Detects the receiving shell.
			return shell # Returns its zero-based shell index.
	return maxi(0, after.size() - 1) # Falls back to the outermost occupied shell.

func electron_shell_distribution(electron_total: int) -> Array[int]: # Converts an electron count into simplified Bohr shells using the original Aufbau order.
	var total: int = clampi(electron_total, 0, ChemistryData.MAX_ELECTRONS) # Constrains electron count to supported sandbox limits.
	var distribution: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0] # Allocates occupancy for all supported principal shells.
	const ORBITALS: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(2, 6), Vector2i(3, 2), Vector2i(3, 6), Vector2i(4, 2), Vector2i(3, 10), Vector2i(4, 6), Vector2i(5, 2), Vector2i(4, 10), Vector2i(5, 6), Vector2i(6, 2), Vector2i(4, 14), Vector2i(5, 10), Vector2i(6, 6), Vector2i(7, 2), Vector2i(5, 14), Vector2i(6, 10), Vector2i(7, 6), Vector2i(8, 2), Vector2i(5, 6)] # Preserves the browser orbital sequence and capacities.
	var remaining: int = total # Tracks electrons still waiting to be placed.
	for orbital: Vector2i in ORBITALS: # Fills orbitals in the original order.
		if remaining <= 0: # Stops once every electron has been placed.
			break # Leaves later orbitals empty.
		var placed: int = mini(orbital.y, remaining) # Places up to the orbital capacity.
		distribution[orbital.x - 1] += placed # Adds placed electrons to the corresponding principal shell.
		remaining -= placed # Removes them from the unplaced total.
	while distribution.size() > 1 and distribution[distribution.size() - 1] == 0: # Removes unused trailing shells for rendering parity.
		distribution.remove_at(distribution.size() - 1) # Trims one empty outer shell.
	return distribution # Returns principal-shell occupancies.

func shell_of_last_electron(atom: AtomState) -> int: # Reports the one-based principal shell occupied by the most recently captured electron.
	if atom.electrons <= 0: # Handles an atom with no captured electrons.
		return 1 # Uses the first shell as a safe display fallback.
	var before: Array[int] = electron_shell_distribution(atom.electrons - 1) # Calculates occupancy before the last electron.
	var after: Array[int] = electron_shell_distribution(atom.electrons) # Calculates current occupancy.
	for shell: int in after.size(): # Finds the shell whose occupancy increased.
		var before_count: int = before[shell] if shell < before.size() else 0 # Safely reads prior occupancy.
		if after[shell] > before_count: # Detects the changed shell.
			return shell + 1 # Returns conventional one-based shell numbering.
	return after.size() # Falls back to the outermost occupied shell.

func valence_electrons(electron_total: int) -> int: # Returns population of the outer occupied simplified Bohr shell.
	var distribution: Array[int] = electron_shell_distribution(electron_total) # Calculates principal-shell occupancy.
	return distribution[distribution.size() - 1] if not distribution.is_empty() else 0 # Returns the outer shell population safely.

func _create_atom_from_proton(particle: ParticleState) -> void: # Turns an uncaptured proton into a seed hydrogen nucleus at the aim point.
	var atom: AtomState = AtomState.new(state.next_atom_id, Vector2(clampf(particle.position.x, 70.0, ChemistryData.WORLD_SIZE.x - 70.0), clampf(particle.position.y, 70.0, ChemistryData.WORLD_SIZE.y - 110.0))) # Creates a bounded native atom state.
	state.next_atom_id += 1 # Reserves the next unique atom identifier.
	atom.velocity = particle.velocity * 0.08 # Preserves the browser seed momentum transfer.
	atom.protons = 1 # Seeds a hydrogen nucleus with one proton.
	atom.neutrons = 0 # Starts the nucleus without neutrons.
	atom.electrons = 0 # Starts the atom without captured electrons.
	atom.electron_phase = randf() * TAU # Randomizes orbit phase exactly as the browser did.
	atom.pulse = 1.0 # Starts the creation highlight.
	state.atoms.append(atom) # Adds the new atom to world state.
	state.selected_atom_id = atom.id # Selects the newly created nucleus for inspection.
	controller.set_status("New Hydrogen Nucleus Started") # Reports the same construction event in native UI formatting.
	controller.refresh_inspector() # Updates native inspector content immediately.
	controller.refresh_freeplay_ui() # Updates manual reaction controls if freeplay is active.

func _capture_nucleon(particle: ParticleState, atom: AtomState) -> bool: # Adds a proton or neutron while enforcing the recognised-element proton limit.
	if particle.kind == &"proton" and atom.protons >= ChemistryData.MAX_ATOMIC_NUMBER: # Rejects a proton beyond element one hundred eighteen.
		particle.velocity *= -0.72 # Preserves the browser rebound response.
		controller.set_status("Oganesson Is Element 118 — No Known Element Has More Protons") # Explains the atomic-number limit.
		return false # Reports that no capture occurred.
	if particle.kind == &"proton": # Handles proton capture.
		atom.protons += 1 # Increases atomic number by one.
	else: # Handles neutron capture.
		atom.neutrons += 1 # Increases isotope mass by one.
	atom.velocity += particle.velocity * 0.012 # Transfers the original small fraction of projectile momentum.
	atom.pulse = 1.0 # Restarts the capture highlight.
	state.selected_atom_id = atom.id # Selects the changed atom for inspection.
	particle.alive = false # Consumes the captured projectile.
	controller.set_status("%s Captured — Nucleus Is Now %s" % [String(particle.kind).capitalize(), ChemistryData.element_symbol(atom.protons)]) # Reports the updated nucleus identity.
	controller.refresh_inspector() # Refreshes native inspector values.
	controller.refresh_freeplay_ui() # Refreshes any selected freeplay composition.
	return true # Reports successful capture.

func _capture_electron(particle: ParticleState, atom: AtomState) -> bool: # Adds an electron to the appropriate Bohr shell up to the sandbox limit.
	if atom.electrons >= ChemistryData.MAX_ELECTRONS: # Rejects electrons beyond the supported sandbox occupancy.
		particle.velocity *= -0.72 # Preserves the browser rebound response.
		controller.set_status("Electron Limit Reached For This Sandbox (%d)" % ChemistryData.MAX_ELECTRONS) # Reports the electron ceiling.
		return false # Reports that no capture occurred.
	atom.electrons += 1 # Adds the captured electron to the atom.
	atom.pulse = 1.0 # Restarts the capture highlight.
	state.selected_atom_id = atom.id # Selects the changed atom for inspection.
	particle.alive = false # Consumes the captured projectile.
	controller.set_status("Electron Captured Into Shell %d" % shell_of_last_electron(atom)) # Reports the receiving principal shell.
	controller.refresh_inspector() # Refreshes native inspector values.
	controller.refresh_freeplay_ui() # Refreshes any selected freeplay composition.
	return true # Reports successful capture.

func _apply_particle_forces(particle: ParticleState, delta: float) -> void: # Applies the browser's simplified electrostatic attraction or repulsion around nuclei.
	if particle.kind == &"neutron": # Neutrons are unaffected by the simplified electric field.
		return # Leaves neutron velocity unchanged.
	for atom: AtomState in state.atoms: # Applies contribution from every live atom.
		var offset: Vector2 = particle.position - atom.position # Points from the atom centre to the projectile.
		var distance_squared: float = maxf(950.0, offset.length_squared()) # Prevents singular acceleration near the nucleus.
		var distance: float = sqrt(distance_squared) # Calculates normalized direction denominator.
		var direction_sign: float = 1.0 if particle.kind == &"proton" else -1.0 # Repels protons and attracts electrons.
		var charge_strength: float = 98000.0 * float(maxi(1, atom.protons)) # Scales field strength by proton count.
		var acceleration: float = direction_sign * charge_strength / distance_squared # Applies inverse-square strength.
		particle.velocity += (offset / distance) * acceleration * delta # Integrates the electrostatic acceleration.
