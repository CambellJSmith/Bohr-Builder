class_name CampaignSystem # Recreates automatic campaign reactant matching, reaction animation, and progression.
extends RefCounted # Keeps campaign rules independent from native UI layout.

var state: BohrGameState # References shared gameplay state.
var controller: BohrBuilderController # References the native controller for direct refresh calls without signals.
var physics: BohrPhysicsSystem # References native atom lookup helpers.
var campaign: Array[Dictionary] # Caches generated campaign level definitions.

func _init(game_state: BohrGameState, game_controller: BohrBuilderController, physics_system: BohrPhysicsSystem) -> void: # Binds campaign logic to the active game.
	state = game_state # Retains shared simulation state.
	controller = game_controller # Retains the owning native controller.
	physics = physics_system # Retains atom lookup helpers.
	campaign = CampaignData.levels() # Caches the deterministic two-hundred-level campaign.

func current_level() -> Dictionary: # Returns the active campaign level definition.
	return campaign[state.current_level_index] # Resolves the current zero-based level index.

func atom_matches(atom: AtomState, atom_key: String) -> bool: # Tests exact isotope and electron-count equality for a requested species.
	var required: Dictionary = ChemistryData.ATOMS[atom_key] # Reads the requested campaign atom or ion definition.
	return atom.protons == int(required["protons"]) and atom.neutrons == int(required["neutrons"]) and atom.electrons == int(required["electrons"]) # Requires exact proton, neutron, and electron totals.

func requirement_groups() -> Array[Dictionary]: # Collapses repeated campaign species into concise requirement counters.
	var counts: Dictionary = {} # Maps atom keys to requested multiplicities.
	for atom_key: String in current_level()["atom_keys"] as Array[String]: # Counts every ordered target species.
		counts[atom_key] = int(counts.get(atom_key, 0)) + 1 # Increments its requested count.
	var groups: Array[Dictionary] = [] # Converts counts into stable row dictionaries.
	for atom_key: String in counts: # Preserves first-insertion ordering from the level target.
		groups.append({"atom_key": atom_key, "count": int(counts[atom_key])}) # Adds one requirement row definition.
	return groups # Returns the grouped requirements.

func check_reaction_ready() -> void: # Starts automatic campaign combination as soon as every requested species exists.
	if state.game_mode == &"freeplay" or state.reaction != null or state.molecule_active: # Rejects campaign reactions outside active campaign construction.
		return # Leaves world state unchanged.
	var reactants: Array[AtomState] = _find_reactants() # Attempts to assign one unique world atom to every ordered requirement.
	if reactants.is_empty(): # Treats an empty result as incomplete requirements.
		return # Waits for further construction.
	var reaction: ReactionState = ReactionState.new() # Allocates native reaction animation state.
	reaction.duration = 2.35 # Preserves the browser combination duration exactly.
	for atom: AtomState in reactants: # Snapshots every participating world atom.
		reaction.atom_ids.append(atom.id) # Stores the unique atom identifier.
		reaction.start_positions.append(atom.position) # Stores its pre-reaction world position.
	state.reaction = reaction # Activates campaign reaction processing.
	state.particles.clear() # Removes stray projectiles exactly as the browser does when reaction begins.
	state.selected_atom_id = -1 # Clears atom inspection while species combine.
	controller.set_status("Reaction Ready — Atoms Are Combining", 0.0) # Displays persistent combination feedback.
	controller.refresh_inspector() # Clears the inspector display.

func update_reaction(delta: float) -> void: # Animates matched campaign reactants into their target product layout.
	if state.reaction == null: # Ignores updates when no campaign reaction exists.
		return # Leaves state unchanged.
	state.reaction.elapsed += delta # Advances reaction time.
	var ratio: float = clampf(state.reaction.elapsed / state.reaction.duration, 0.0, 1.0) # Normalizes reaction progress.
	var eased: float = 1.0 - pow(1.0 - ratio, 3.0) # Preserves the browser cubic ease-out interpolation.
	var targets: Array[Vector2] = reaction_world_targets() # Resolves absolute workspace targets from the current level layout.
	for index: int in state.reaction.atom_ids.size(): # Moves every participating atom independently.
		var atom: AtomState = physics.find_atom_by_id(state.reaction.atom_ids[index]) # Resolves the live world atom.
		if atom == null: # Tolerates an unexpected missing atom defensively.
			continue # Leaves the missing slot unchanged.
		atom.position = state.reaction.start_positions[index].lerp(targets[index], eased) # Interpolates into the product layout.
		atom.velocity = Vector2.ZERO # Stops atom drift during deterministic combination.
	if ratio >= 1.0: # Finalizes the product when interpolation completes.
		var consumed: Dictionary = {} # Builds a set of participating atom identifiers.
		for atom_id: int in state.reaction.atom_ids: # Reads every reactant identifier.
			consumed[atom_id] = true # Marks it for removal.
		for index: int in range(state.atoms.size() - 1, -1, -1): # Removes consumed atoms in reverse.
			if consumed.has(state.atoms[index].id): # Detects a participating world atom.
				state.atoms.remove_at(index) # Removes it from active atom state.
		state.molecule_active = true # Enables completed campaign molecule rendering.
		state.molecule_position = ChemistryData.WORLD_SIZE * Vector2(0.5, 0.42) # Matches the original product centre.
		state.reaction = null # Clears reaction animation state.
		complete_level() # Unlocks progression and refreshes UI.

func reaction_world_targets() -> Array[Vector2]: # Converts current product-local coordinates into fixed workspace positions.
	var center: Vector2 = ChemistryData.WORLD_SIZE * Vector2(0.5, 0.42) # Matches the browser product centre.
	var targets: Array[Vector2] = [] # Holds absolute target positions.
	for local_position: Vector2 in current_level()["layout"] as Array[Vector2]: # Reads every generated product-local coordinate.
		targets.append(center + local_position) # Converts it into workspace coordinates.
	return targets # Returns the ordered absolute targets.

func complete_level() -> void: # Marks the current campaign level complete and unlocks progression.
	if state.current_level_index < campaign.size() - 1: # Handles every level except the final campaign target.
		state.unlocked_level = maxi(state.unlocked_level, state.current_level_index + 1) # Unlocks at least the immediately following level.
		controller.save_progress() # Persists the highest unlocked level to user storage.
		controller.populate_level_select() # Rebuilds the native level selector with the new option enabled.
		controller.set_next_button_visible(true) # Exposes native next-level progression.
		controller.set_status("%s Formed — Level Complete — Next Level Unlocked" % String(current_level()["formula"]), 0.0) # Preserves persistent completion feedback.
	else: # Handles completion of the final generated campaign target.
		controller.set_next_button_visible(false) # Hides progression because there is no later level.
		controller.set_status("%s Formed — Campaign Complete" % String(current_level()["formula"]), 0.0) # Displays final campaign completion feedback.
	controller.refresh_requirement_ui() # Updates guided counters to their completed state.

func _find_reactants() -> Array[AtomState]: # Selects one unique completed world species for each ordered campaign requirement.
	var used: Dictionary = {} # Tracks atom identifiers already assigned to a requirement.
	var reactants: Array[AtomState] = [] # Collects matching atoms in target-layout order.
	for atom_key: String in current_level()["atom_keys"] as Array[String]: # Resolves every required campaign species in order.
		var matched_atom: AtomState = null # Stores the first unused exact match.
		for atom: AtomState in state.atoms: # Searches active world atoms.
			if not used.has(atom.id) and atom_matches(atom, atom_key): # Requires uniqueness and exact particle counts.
				matched_atom = atom # Retains the matching world atom.
				break # Stops after the first ordered match.
		if matched_atom == null: # Detects any still-missing requirement.
			return [] # Reports that automatic reaction is not ready.
		used[matched_atom.id] = true # Reserves this atom for the current requirement.
		reactants.append(matched_atom) # Preserves target-layout order.
	return reactants # Returns the complete unique reactant assignment.
