class_name BohrWorkspace # Draws and maps the original 1100×700 Bohr Builder world using native Godot CanvasItem APIs.
extends Control # Uses a real focusable Control so mouse, keyboard, and controller can target the workspace natively.

const COLOR_BACKGROUND: Color = Color(0.0667, 0.0745, 0.0902, 1.0) # Matches the browser canvas background.
const COLOR_PROTON: Color = Color(0.7843, 0.3608, 0.3608, 1.0) # Matches proton fill.
const COLOR_NEUTRON: Color = Color(0.4667, 0.4980, 0.5373, 1.0) # Matches neutron fill.
const COLOR_ELECTRON: Color = Color(0.3333, 0.4980, 0.7804, 1.0) # Matches electron fill.
const COLOR_TEXT: Color = Color(0.9294, 0.9412, 0.9529, 1.0) # Matches primary browser text.
const COLOR_MUTED: Color = Color(0.6157, 0.6471, 0.6824, 1.0) # Matches muted browser text.

var state: BohrGameState # References shared simulation state.
var physics: BohrPhysicsSystem # References shell and nucleus calculations.
var campaign: CampaignSystem # References active campaign layout and bond data.
var _font: Font # Caches Godot's fallback UI font for native world labels.

func configure(game_state: BohrGameState, physics_system: BohrPhysicsSystem, campaign_system: CampaignSystem) -> void: # Binds rendering to the active native simulation.
	state = game_state # Retains shared gameplay state.
	physics = physics_system # Retains native shell and hit calculations.
	campaign = campaign_system # Retains active campaign data.
	_font = ThemeDB.fallback_font # Uses the engine's native fallback font without bundling web fonts.
	queue_redraw() # Requests the first native world frame.

func world_from_local(local_position: Vector2) -> Vector2: # Converts displayed Control coordinates into fixed browser-equivalent world coordinates.
	var transform_data: Vector3 = _world_transform_data() # Reads world scale and centered offsets.
	var offset: Vector2 = Vector2(transform_data.y, transform_data.z) # Reconstructs the display offset.
	return (local_position - offset) / transform_data.x # Converts to fixed 1100×700 simulation space.

func local_from_world(world_position: Vector2) -> Vector2: # Converts fixed simulation coordinates into displayed Control coordinates.
	var transform_data: Vector3 = _world_transform_data() # Reads world scale and centered offsets.
	return Vector2(transform_data.y, transform_data.z) + world_position * transform_data.x # Applies centered world scaling.

func local_point_is_world(local_position: Vector2) -> bool: # Tests whether a displayed point lies inside the rendered fixed world rectangle.
	var transform_data: Vector3 = _world_transform_data() # Reads world scale and centered offsets.
	var world_rect: Rect2 = Rect2(Vector2(transform_data.y, transform_data.z), ChemistryData.WORLD_SIZE * transform_data.x) # Builds the rendered world bounds.
	return world_rect.has_point(local_position) # Reports whether the point belongs to the simulation surface.

func _draw() -> void: # Draws one complete native simulation frame.
	if state == null or physics == null or campaign == null: # Avoids drawing before the controller finishes configuration.
		return # Leaves the Control empty until state is available.
	var transform_data: Vector3 = _world_transform_data() # Calculates the fixed-world display transform once.
	draw_set_transform(Vector2(transform_data.y, transform_data.z), 0.0, Vector2.ONE * transform_data.x) # Makes all following commands use original browser world coordinates.
	var now_ms: float = float(Time.get_ticks_msec()) # Uses millisecond timing to preserve browser orbit and bob rates.
	_draw_background() # Draws the dark grid and lower construction boundary.
	_draw_aim_assist() # Draws shell/nucleus capture guidance when appropriate.
	_draw_cannon() # Draws current aim and particle cannon.
	_draw_campaign_reaction_bonds() # Draws campaign bonds fading in during combination.
	_draw_freeplay_reaction_bonds() # Draws schematic freeplay bonds during manual combination.
	for atom: AtomState in state.atoms: # Draws every live atom or ion.
		_draw_atom(atom, now_ms) # Renders nucleus, shells, electrons, selection, and charge.
	for particle: ParticleState in state.particles: # Draws every active fired projectile.
		_draw_particle(particle) # Renders particle circle and label.
	_draw_campaign_molecule(now_ms) # Draws the retained completed campaign product when present.
	_draw_freeplay_products(now_ms) # Draws every retained freeplay product.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE) # Restores native Control drawing coordinates.

func _world_transform_data() -> Vector3: # Calculates uniform scale plus centered X/Y offset for the fixed simulation world.
	var scale_factor: float = minf(size.x / ChemistryData.WORLD_SIZE.x, size.y / ChemistryData.WORLD_SIZE.y) # Preserves world aspect ratio at any Control size.
	var rendered_size: Vector2 = ChemistryData.WORLD_SIZE * scale_factor # Calculates displayed world dimensions.
	var offset: Vector2 = (size - rendered_size) * 0.5 # Centers any letterboxed world inside the Control.
	return Vector3(scale_factor, offset.x, offset.y) # Packs scale and offsets without allocating a dictionary.

func _draw_background() -> void: # Draws the restrained browser grid and playfield boundary.
	draw_rect(Rect2(Vector2.ZERO, ChemistryData.WORLD_SIZE), COLOR_BACKGROUND, true) # Fills the complete fixed workspace.
	var grid_color: Color = Color(1.0, 1.0, 1.0, 0.035) # Matches subtle browser grid opacity.
	for x_value: int in range(0, int(ChemistryData.WORLD_SIZE.x) + 1, 50): # Draws vertical grid lines every fifty units.
		draw_line(Vector2(float(x_value), 0.0), Vector2(float(x_value), ChemistryData.WORLD_SIZE.y), grid_color, 1.0) # Renders one vertical guide.
	for y_value: int in range(0, int(ChemistryData.WORLD_SIZE.y) + 1, 50): # Draws horizontal grid lines every fifty units.
		draw_line(Vector2(0.0, float(y_value)), Vector2(ChemistryData.WORLD_SIZE.x, float(y_value)), grid_color, 1.0) # Renders one horizontal guide.
	draw_line(Vector2(0.0, ChemistryData.WORLD_SIZE.y - 78.0), Vector2(ChemistryData.WORLD_SIZE.x, ChemistryData.WORLD_SIZE.y - 78.0), Color(1.0, 1.0, 1.0, 0.08), 1.0) # Draws the lower construction boundary.

func _draw_aim_assist() -> void: # Highlights valid shell or nucleus capture areas using the browser assistance curve.
	if state.reaction != null or state.freeplay_reaction != null or (state.molecule_active and state.game_mode != &"freeplay") or state.scrap_mode or state.freeplay_select_mode: # Hides assistance while another interaction is active.
		return # Leaves the world uncluttered during those modes.
	var assist: float = 1.0 if state.game_mode == &"freeplay" else float(campaign.current_level()["assist"]) # Resolves campaign assistance or stable freeplay tolerance.
	var alpha: float = 0.08 + (assist - 1.0) * 0.2 # Preserves browser guidance opacity scaling.
	for atom: AtomState in state.atoms: # Draws guidance around every live atom.
		if state.selected_particle == &"electron": # Highlights the next valid electron shell.
			var shell: int = physics.next_electron_shell(atom) # Resolves receiving shell.
			var line_width: float = 5.0 if state.current_level_index == 0 else 3.0 # Preserves stronger opening-level guidance.
			draw_arc(atom.position, ChemistryData.SHELL_RADII[shell], 0.0, TAU, 96, Color(0.3333, 0.4980, 0.7804, clampf(alpha, 0.08, 0.26)), line_width, true) # Draws shell capture ring.
		else: # Highlights nucleus capture for protons and neutrons.
			draw_arc(atom.position, physics.nucleus_radius(atom) + 12.0, 0.0, TAU, 64, Color(0.8627, 0.8863, 0.9098, clampf(alpha * 0.8, 0.06, 0.2)), 2.0, true) # Draws nucleus capture ring.

func _draw_cannon() -> void: # Draws browser-equivalent cannon geometry and current aim direction.
	if state.molecule_active and state.game_mode != &"freeplay": # Hides the cannon after campaign completion.
		return # Leaves the completed molecule as the world focus.
	var offset: Vector2 = state.pointer_position - ChemistryData.CANNON_POSITION # Calculates current aim vector.
	var length: float = maxf(1.0, offset.length()) # Avoids division by zero at the cannon centre.
	var direction: Vector2 = offset / length # Normalizes the aim direction.
	_draw_dashed_line(ChemistryData.CANNON_POSITION + direction * 35.0, state.pointer_position, Color(0.4471, 0.6706, 0.8392, 0.5), 1.0, 7.0, 8.0) # Draws the browser-style dashed aiming guide.
	if state.selected_particle == &"proton" and state.atoms.is_empty(): # Highlights the initial nucleus seed point.
		draw_arc(state.pointer_position, 19.0, 0.0, TAU, 48, Color(0.7843, 0.3608, 0.3608, 0.5), 1.0, true) # Draws the first-proton landing marker.
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x) # Builds cannon barrel width axis.
	var barrel_start: Vector2 = ChemistryData.CANNON_POSITION # Uses cannon centre as barrel origin.
	var barrel_end: Vector2 = ChemistryData.CANNON_POSITION + direction * 48.0 # Matches browser barrel length.
	var barrel: PackedVector2Array = PackedVector2Array([barrel_start - perpendicular * 8.0, barrel_end - perpendicular * 8.0, barrel_end + perpendicular * 8.0, barrel_start + perpendicular * 8.0]) # Builds the rotated barrel rectangle.
	draw_colored_polygon(barrel, Color(0.2745, 0.2980, 0.3294, 1.0)) # Fills the cannon barrel.
	draw_circle(ChemistryData.CANNON_POSITION, 24.0, Color(0.1725, 0.1882, 0.2118, 1.0)) # Fills the cannon base.
	draw_arc(ChemistryData.CANNON_POSITION, 24.0, 0.0, TAU, 64, Color(0.3569, 0.3843, 0.4235, 1.0), 1.0, true) # Outlines the cannon base.

func _draw_particle(particle: ParticleState) -> void: # Draws one moving projectile with its browser color and label.
	var fill: Color = COLOR_PROTON if particle.kind == &"proton" else COLOR_NEUTRON if particle.kind == &"neutron" else COLOR_ELECTRON # Chooses particle-specific fill.
	var label: String = "p+" if particle.kind == &"proton" else "n" if particle.kind == &"neutron" else "e−" # Chooses particle-specific label.
	draw_circle(particle.position, particle.radius, fill) # Draws the projectile body.
	_draw_centered_text(label, particle.position + Vector2(0.0, 3.0), 8 if particle.kind == &"electron" else 9, Color(0.9686, 0.9725, 0.9804, 1.0)) # Draws the particle label.

func _draw_atom(atom: AtomState, now_ms: float) -> void: # Renders one interactive Bohr-model atom with nucleus, shells, electrons, charge, and selection.
	var shell_distribution: Array[int] = physics.electron_shell_distribution(atom.electrons) # Calculates principal-shell occupancy.
	var shell_count: int = maxi(1, shell_distribution.size()) # Ensures an empty atom still shows its first shell.
	var selected: bool = atom.id == state.selected_atom_id # Detects inspector selection.
	var reaction_selected: bool = state.game_mode == &"freeplay" and state.freeplay_selected_ids.has(atom.id) # Detects manual reaction selection.
	if selected or reaction_selected: # Draws the browser selection halo.
		var halo_radius: float = ChemistryData.SHELL_RADII[mini(shell_count - 1, ChemistryData.SHELL_RADII.size() - 1)] + 16.0 # Matches the outer selection footprint.
		var halo_color: Color = Color(0.7882, 0.4157, 0.4157, 0.85) if state.scrap_mode else Color(0.8275, 0.6824, 0.3020, 0.95) if reaction_selected else Color(0.3020, 0.6039, 0.8275, 0.85) # Chooses scrap, reaction, or ordinary selection color.
		draw_arc(atom.position, halo_radius, 0.0, TAU, 96, halo_color, 3.0 if reaction_selected else 2.0, true) # Draws the selection ring.
	for shell: int in shell_count: # Draws each visible Bohr shell.
		draw_arc(atom.position, ChemistryData.SHELL_RADII[shell], 0.0, TAU, 96, Color(0.6784, 0.7216, 0.7647, 0.32), 1.25, true) # Draws one shell orbit.
	var nucleon_total: int = atom.protons + atom.neutrons # Calculates nucleus particle count.
	var nucleus_size: float = physics.nucleus_radius(atom) # Calculates compressed visual nucleus radius.
	if atom.pulse > 0.0: # Draws capture/creation pulse while active.
		draw_arc(atom.position, nucleus_size + atom.pulse * 12.0, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, atom.pulse * 0.2), 1.0, true) # Matches browser pulse ring.
	for index: int in nucleon_total: # Draws packed proton/neutron dots inside the nucleus.
		var is_proton: bool = index < atom.protons # Preserves browser ordering with protons first.
		var angle: float = float(index) * 2.3999632297 # Uses the same golden-angle packing constant.
		var dot_radius: float = clampf(6.5 - float(nucleon_total) * 0.018, 2.15, 6.5) # Compresses dots for heavy nuclei.
		var radial: float = sqrt(float(index)) * dot_radius * 0.82 # Matches browser spiral radius.
		var dot_position: Vector2 = atom.position + Vector2(cos(angle), sin(angle)) * radial # Calculates one nucleon centre.
		draw_circle(dot_position, dot_radius, COLOR_PROTON if is_proton else COLOR_NEUTRON) # Draws proton or neutron dot.
	var electron_index: int = 0 # Tracks global electron index for phase variation.
	for shell: int in shell_distribution.size(): # Draws orbiting electrons shell by shell.
		var count: int = shell_distribution[shell] # Reads electrons in the current shell.
		for index: int in count: # Draws every electron in that shell.
			var angular_speed: float = 0.0006 + float(shell) * 0.00015 # Preserves browser shell speed scaling in radians per millisecond.
			var angle: float = atom.electron_phase + now_ms * angular_speed + (float(index) / float(maxi(1, count))) * TAU + float(electron_index) * 0.11 # Preserves browser orbit phase equation.
			var electron_position: Vector2 = atom.position + Vector2(cos(angle), sin(angle)) * ChemistryData.SHELL_RADII[shell] # Calculates electron world centre.
			draw_circle(electron_position, 5.2, COLOR_ELECTRON) # Draws one orbiting electron.
			electron_index += 1 # Advances global phase index.
	var atom_symbol: String = ChemistryData.element_symbol(atom.protons) # Resolves current element symbol from proton count.
	_draw_centered_text(atom_symbol, atom.position + Vector2(0.0, nucleus_size + 21.0), 13, COLOR_TEXT) # Draws the element label below the nucleus.
	var charge: int = atom.protons - atom.electrons # Calculates formal monatomic charge.
	if charge != 0: # Adds superscript notation only for ions.
		_draw_left_text(ChemistryData.superscript_charge(charge), atom.position + Vector2(maxf(8.0, float(atom_symbol.length()) * 5.0), nucleus_size + 16.0), 10, Color(0.9294, 0.9412, 0.9529, 0.88)) # Draws the charge beside the symbol.

func _draw_campaign_reaction_bonds() -> void: # Fades in current-level bonds while reactants converge.
	if state.reaction == null: # Skips when no campaign reaction is active.
		return # Leaves the world unchanged.
	var strength: float = clampf((state.reaction.elapsed / state.reaction.duration - 0.45) / 0.4, 0.0, 1.0) # Preserves browser bond fade timing.
	if strength <= 0.0: # Avoids drawing fully transparent bonds.
		return # Leaves early until fade begins.
	var entries: Array[AtomState] = [] # Resolves ordered participating atoms.
	for atom_id: int in state.reaction.atom_ids: # Reads every campaign reactant identifier.
		var atom: AtomState = physics.find_atom_by_id(atom_id) # Resolves the live world atom.
		if atom == null: # Rejects incomplete reaction drawing defensively.
			return # Avoids mismatched bond indices.
		entries.append(atom) # Adds the ordered reactant reference.
	for bond: Array in campaign.current_level()["bonds"] as Array[Array]: # Draws every target-product bond.
		_draw_bond_between(entries[int(bond[0])].position, entries[int(bond[1])].position, int(bond[2]), 0.8 * strength) # Draws one fading bond.

func _draw_freeplay_reaction_bonds() -> void: # Fades generic schematic bonds in while selected freeplay reactants converge.
	if state.freeplay_reaction == null: # Skips when no manual reaction is active.
		return # Leaves world unchanged.
	var entries: Array[AtomState] = [] # Resolves ordered participating atoms.
	for atom_id: int in state.freeplay_reaction.atom_ids: # Reads every selected reactant identifier.
		var atom: AtomState = physics.find_atom_by_id(atom_id) # Resolves the live world atom.
		if atom == null: # Rejects incomplete reaction drawing defensively.
			return # Avoids mismatched bond indices.
		entries.append(atom) # Adds ordered reactant reference.
	var strength: float = clampf((state.freeplay_reaction.elapsed / state.freeplay_reaction.duration - 0.45) / 0.4, 0.0, 1.0) # Preserves browser freeplay bond fade timing.
	for bond: Array in state.freeplay_reaction.bonds: # Draws every generic product bond.
		_draw_bond_between(entries[int(bond[0])].position, entries[int(bond[1])].position, int(bond[2]), 0.72 * strength) # Draws one fading schematic bond.

func _draw_campaign_molecule(now_ms: float) -> void: # Renders the completed campaign molecule from the same layout and bond data used by its reaction.
	if not state.molecule_active: # Skips until campaign reaction completes.
		return # Leaves active construction world unchanged.
	var level: Dictionary = campaign.current_level() # Reads active target product data.
	var bob: float = sin(now_ms * 0.0016) * 4.0 # Preserves browser molecule bob amplitude and frequency.
	var positions: Array[Vector2] = [] # Holds absolute atom centres after bobbing.
	for local_position: Vector2 in level["layout"] as Array[Vector2]: # Reads target-local coordinates.
		positions.append(state.molecule_position + local_position + Vector2(0.0, bob)) # Converts to world coordinates and applies bob.
	for bond: Array in level["bonds"] as Array[Array]: # Draws target product connectivity.
		_draw_bond_between(positions[int(bond[0])], positions[int(bond[1])], int(bond[2]), 0.76) # Draws one completed product bond.
	var atom_keys: Array[String] = level["atom_keys"] # Reads ordered product species definitions.
	for index: int in atom_keys.size(): # Draws each completed product atom.
		_draw_molecule_atom(positions[index], atom_keys[index], now_ms, float(index) * 0.73) # Preserves browser phase offsets.
	_draw_centered_text(String(level["formula"]), state.molecule_position + Vector2(0.0, 189.0), 20, Color(0.9294, 0.9412, 0.9529, 0.92)) # Draws target formula below the product.
	if state.game_mode == &"guided": # Shows product name only in guided mode.
		_draw_centered_text(_display_name(String(level["name"])), state.molecule_position + Vector2(0.0, 212.0), 13, Color(0.6157, 0.6471, 0.6824, 0.95)) # Draws guided product name.

func _draw_molecule_atom(position: Vector2, atom_key: String, now_ms: float, phase: float) -> void: # Draws one identifiable center inside a completed campaign molecule.
	var definition: Dictionary = ChemistryData.ATOMS[atom_key] # Reads target species definition.
	var radius: float = clampf(28.0 + sqrt(float(int(definition["protons"]))) * 5.0, 32.0, 49.0) # Preserves browser product-atom radius scaling.
	var symbol: String = String(definition["display_symbol"]) # Reads conventional display symbol.
	var proton_count: int = int(definition["protons"]) # Reads element identity once for color selection.
	var fill: Color = _molecule_color(proton_count) # Chooses the browser element palette.
	draw_circle(position, radius, fill) # Draws the product atom body.
	draw_arc(position, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.18), 1.0, true) # Draws the subtle product atom outline.
	var valence_count: int = physics.valence_electrons(int(definition["electrons"])) # Calculates outer-shell electron count.
	for index: int in valence_count: # Draws symbolic valence electrons around the completed atom.
		var angle: float = now_ms * 0.00035 + phase + (float(index) / float(maxi(1, valence_count))) * TAU # Preserves browser product electron animation.
		draw_circle(position + Vector2(cos(angle), sin(angle)) * (radius + 13.0), 3.8, COLOR_ELECTRON) # Draws one valence electron.
	_draw_centered_text(symbol, position + Vector2(0.0, 7.0), 17 if symbol.length() > 1 else 22, Color(0.9608, 0.9647, 0.9686, 1.0)) # Draws the atom symbol at center.
	var charge: int = int(definition["protons"]) - int(definition["electrons"]) # Calculates monatomic formal charge.
	if charge != 0: # Draws charge only for ionic target centers.
		_draw_left_text(ChemistryData.superscript_charge(charge), position + Vector2(radius * 0.45, -radius * 0.52 + 4.0), 12, Color(0.9608, 0.9647, 0.9686, 0.92)) # Draws superscript charge.

func _draw_freeplay_products(now_ms: float) -> void: # Keeps every manually formed freeplay product visible while construction continues.
	for product: FreeplayProductState in state.freeplay_products: # Draws each retained product independently.
		var bob: float = sin(now_ms * 0.0014 + product.position.x * 0.01) * 2.5 # Preserves browser freeplay bob timing and phase.
		var positions: Array[Vector2] = [] # Holds absolute product atom positions.
		for local_position: Vector2 in product.layout: # Reads each schematic local coordinate.
			positions.append(product.position + local_position + Vector2(0.0, bob)) # Converts to world coordinates with bob.
		for bond: Array in product.bonds: # Draws retained schematic connectivity.
			_draw_bond_between(positions[int(bond[0])], positions[int(bond[1])], int(bond[2]), 0.58) # Draws one retained bond.
		for index: int in product.snapshots.size(): # Draws each retained product center.
			_draw_freeplay_product_atom(positions[index], product.snapshots[index]) # Draws one element center from its captured composition snapshot.
		var max_y: float = positions[0].y # Starts label placement below the lowest atom center.
		for position: Vector2 in positions: # Finds the lowest product center.
			max_y = maxf(max_y, position.y) # Retains maximum Y coordinate.
		_draw_centered_text(ReactionLibrary.pretty_formula_from_ascii(product.formula), Vector2(product.position.x, max_y + 52.0), 17, Color(0.9294, 0.9412, 0.9529, 0.9)) # Draws product formula.
		_draw_centered_text(_display_name(product.product_name), Vector2(product.position.x, max_y + 70.0), 11, Color(0.6157, 0.6471, 0.6824, 0.92)) # Draws product name.

func _draw_freeplay_product_atom(position: Vector2, snapshot: Dictionary) -> void: # Draws one center inside a retained freeplay product.
	var protons: int = int(snapshot["protons"]) # Reads element identity.
	var radius: float = clampf(25.0 + sqrt(float(protons)) * 3.4, 29.0, 46.0) # Preserves browser freeplay product scaling.
	var symbol: String = ChemistryData.element_symbol(protons) # Resolves display symbol.
	draw_circle(position, radius, _freeplay_molecule_color(protons)) # Draws product atom body.
	draw_arc(position, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.18), 1.0, true) # Draws subtle outline.
	_draw_centered_text(symbol, position + Vector2(0.0, 6.0), 15 if symbol.length() > 1 else 20, Color(0.9608, 0.9647, 0.9686, 1.0)) # Draws centered element symbol.

func _draw_bond_between(a: Vector2, b: Vector2, order: int, alpha: float) -> void: # Draws one single, double, or triple molecular bond.
	var offset: Vector2 = b - a # Calculates bond direction.
	var length: float = maxf(1.0, offset.length()) # Avoids division by zero.
	var normal: Vector2 = Vector2(-offset.y, offset.x) / length # Calculates unit perpendicular for multiple bond lines.
	var offsets: PackedFloat32Array = PackedFloat32Array([-8.0, 0.0, 8.0]) if order == 3 else PackedFloat32Array([-5.0, 5.0]) if order == 2 else PackedFloat32Array([0.0]) # Keeps bond offsets strongly typed at runtime.
	for lateral: float in offsets: # Draws each parallel bond stroke.
		draw_line(a + normal * lateral, b + normal * lateral, Color(0.9020, 0.9176, 0.9373, alpha), 5.0 if order == 1 else 3.5, true) # Draws one antialiased bond line.

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void: # Draws the browser aiming guide without depending on a version-specific dash helper.
	var offset: Vector2 = to - from # Calculates full line vector.
	var length: float = offset.length() # Measures total line length.
	if length <= 0.001: # Handles a degenerate line safely.
		return # Avoids normalization and loop work.
	var direction: Vector2 = offset / length # Normalizes line direction.
	var cursor: float = 0.0 # Tracks distance along the line.
	while cursor < length: # Alternates visible dash and empty gap segments.
		var segment_end: float = minf(cursor + dash, length) # Clips the final dash to the line endpoint.
		draw_line(from + direction * cursor, from + direction * segment_end, color, width, true) # Draws one visible dash.
		cursor += dash + gap # Advances past the following gap.

func _draw_centered_text(text: String, baseline: Vector2, font_size: int, color: Color) -> void: # Draws centered native text using Godot's fallback font.
	var width: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x # Measures text width for explicit centering.
	draw_string(_font, baseline - Vector2(width * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color) # Draws the measured text centered on the requested X coordinate.

func _draw_left_text(text: String, baseline: Vector2, font_size: int, color: Color) -> void: # Draws left-aligned native text at a world baseline.
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color) # Draws the label using the native fallback font.

func _molecule_color(protons: int) -> Color: # Returns the browser palette for completed campaign product centers.
	if protons == 1: return Color(0.3020, 0.3373, 0.3804, 1.0) # Uses hydrogen gray.
	if protons == 8: return Color(0.5765, 0.2824, 0.2824, 1.0) # Uses oxygen red.
	if protons == 7: return Color(0.3490, 0.4196, 0.5686, 1.0) # Uses nitrogen blue-gray.
	if protons == 6: return Color(0.2471, 0.2667, 0.2941, 1.0) # Uses carbon charcoal.
	if protons == 9: return Color(0.3216, 0.4824, 0.3922, 1.0) # Uses fluorine green.
	if protons == 16: return Color(0.5490, 0.4667, 0.2863, 1.0) # Uses sulfur ochre.
	if protons == 17: return Color(0.3294, 0.4824, 0.3647, 1.0) # Uses chlorine green.
	return Color(0.3490, 0.3804, 0.4196, 1.0) # Uses the browser fallback element gray.

func _freeplay_molecule_color(protons: int) -> Color: # Returns the browser palette for retained freeplay product centers.
	if protons == 1: return Color(0.3020, 0.3373, 0.3804, 1.0) # Uses hydrogen gray.
	if protons == 8: return Color(0.5765, 0.2824, 0.2824, 1.0) # Uses oxygen red.
	if protons == 7: return Color(0.3490, 0.4196, 0.5686, 1.0) # Uses nitrogen blue-gray.
	if protons == 6: return Color(0.2471, 0.2667, 0.2941, 1.0) # Uses carbon charcoal.
	return Color(0.3490, 0.3804, 0.4196, 1.0) # Uses the browser fallback gray for other elements.

func _display_name(value: String) -> String: # Converts internal underscore names to native title-style UI text.
	return value.replace("_", " ").capitalize() # Applies the project's requested capitalized UI naming convention.
