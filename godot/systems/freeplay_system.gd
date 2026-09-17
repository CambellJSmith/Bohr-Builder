class_name FreeplaySystem # Recreates manual freeplay selection, validation, reaction animation, and retained products.
extends RefCounted # Keeps freeplay rules separate from native UI and drawing.

var state: BohrGameState # References shared gameplay state.
var controller: BohrBuilderController # References the native controller for direct refresh calls without signals.
var pubchem: PubChemClient = PubChemClient.new() # Provides optional online formula verification with manual polling.

func _init(game_state: BohrGameState, game_controller: BohrBuilderController) -> void: # Binds freeplay logic to the active native game.
	state = game_state # Retains shared simulation state.
	controller = game_controller # Retains the direct native controller callback target.

func selected_atoms() -> Array[AtomState]: # Resolves the current freeplay identifier set to live atom references.
	var selected: Array[AtomState] = [] # Collects live selected species in world ordering.
	for atom: AtomState in state.atoms: # Reads every active atom once.
		if state.freeplay_selected_ids.has(atom.id): # Checks whether its identifier is selected.
			selected.append(atom) # Adds the live atom reference.
	return selected # Returns the filtered selection.

func sanitize_selection() -> void: # Removes selected identifiers whose atoms no longer exist.
	var live_ids: Dictionary = {} # Builds a set of current world atom identifiers.
	for atom: AtomState in state.atoms: # Reads every live atom.
		live_ids[atom.id] = true # Marks its identifier as valid.
	for key: Variant in state.freeplay_selected_ids.keys(): # Checks every selected identifier.
		if not live_ids.has(int(key)): # Detects a selection whose atom was consumed or scrapped.
			state.freeplay_selected_ids.erase(key) # Removes the stale identifier.

func toggle_reactant(atom: AtomState) -> void: # Adds or removes one atom or ion from manual reaction selection.
	if atom == null: # Ignores an empty aim point safely.
		return # Leaves selection unchanged.
	if state.freeplay_selected_ids.has(atom.id): # Detects an already-selected species.
		state.freeplay_selected_ids.erase(atom.id) # Removes it from the reaction set.
	else: # Handles an unselected species.
		state.freeplay_selected_ids[atom.id] = true # Adds its identifier to the reaction set.
	state.selected_atom_id = atom.id # Selects the same species for the inspector.
	controller.refresh_inspector() # Updates its native inspector details.
	controller.refresh_freeplay_ui() # Updates formula, charge, and reaction-button state.

func clear_selection() -> void: # Clears all manually selected freeplay reactants when allowed.
	if state.freeplay_reaction != null or state.freeplay_verifying: # Blocks changes while a reaction or online check is active.
		return # Leaves selection unchanged.
	state.freeplay_selected_ids.clear() # Removes every selected identifier.
	controller.refresh_freeplay_ui() # Refreshes native selection summary and controls.
	controller.set_status("Reaction Selection Cleared") # Reports the clear action.

func attempt_reaction() -> void: # Validates selected composition and starts only known real products.
	if state.game_mode != &"freeplay" or state.freeplay_reaction != null or state.freeplay_verifying: # Rejects attempts outside idle freeplay.
		return # Leaves world state unchanged.
	var selected: Array[AtomState] = selected_atoms() # Resolves current selected species.
	if selected.size() < 2: # Requires at least two reactants exactly like the browser implementation.
		controller.set_status("Select At Least Two Atoms Or Ions First") # Explains the minimum selection requirement.
		return # Rejects the attempt.
	var charge: int = ReactionLibrary.total_charge(selected) # Calculates net formal charge.
	if charge != 0: # Rejects an unbalanced selected composition.
		var prefix: String = "+" if charge > 0 else "" # Formats a positive sign explicitly.
		controller.set_status("Reaction Rejected — Selected Reactants Have Net Charge %s%d" % [prefix, charge]) # Preserves the browser charge rejection rule.
		return # Leaves selection intact for correction.
	var formula: String = ReactionLibrary.ascii_formula_from_atoms(selected) # Builds normalized Hill-system composition.
	var library: Dictionary = ReactionLibrary.static_real_products() # Reads the full offline real-product whitelist.
	if library.has(formula): # Accepts a known offline product immediately.
		_start_reaction(selected, formula, String(library[formula])) # Starts deterministic in-world combination.
		return # Avoids unnecessary network verification.
	state.freeplay_select_mode = false # Leaves reactant-selection mode during online verification.
	state.freeplay_verifying = true # Blocks edits until the lookup completes.
	controller.refresh_freeplay_ui() # Updates native control states and labels.
	controller.set_status("Checking %s Against PubChem…" % ReactionLibrary.pretty_formula_from_ascii(formula), 0.0) # Displays persistent online-check feedback.
	if not pubchem.start_verify(formula): # Handles the unlikely case of a client already busy.
		state.freeplay_verifying = false # Releases the verification lock.
		controller.refresh_freeplay_ui() # Restores native controls.
		controller.set_status("%s Is Not In The Offline Library And Online Verification Is Unavailable" % ReactionLibrary.pretty_formula_from_ascii(formula), 3.2) # Matches the browser unavailable outcome.

func process_network() -> void: # Advances optional PubChem verification without blocking the Godot main thread.
	pubchem.process() # Polls DNS, TLS, HTTP request, and body IO once.
	if not state.freeplay_verifying or not pubchem.has_result(): # Ignores the client until an active verification has completed.
		return # Leaves native UI unchanged.
	var formula: String = pubchem.active_formula() # Retains the completed formula before consuming its result.
	var result: int = pubchem.take_result() # Reads exists, absent, or unavailable status.
	state.freeplay_verifying = false # Releases the freeplay verification lock.
	controller.refresh_freeplay_ui() # Restores native freeplay control availability.
	if result == 1: # Handles a PubChem-verified real formula.
		var selected: Array[AtomState] = selected_atoms() # Resolves the still-selected live reactants.
		if selected.size() >= 2: # Ensures the world has not changed unexpectedly during verification.
			_start_reaction(selected, formula, "pubchem_verified_compound") # Starts the same retained schematic product used by the browser.
	elif result < 0: # Handles timeout, DNS, TLS, or other network unavailability.
		controller.set_status("%s Is Not In The Offline Library And Online Verification Is Unavailable" % ReactionLibrary.pretty_formula_from_ascii(formula), 3.2) # Preserves the browser unavailable message.
	else: # Handles a definitive PubChem miss.
		controller.set_status("Reaction Rejected — No PubChem Compound Found For %s" % ReactionLibrary.pretty_formula_from_ascii(formula), 3.2) # Preserves the browser rejection outcome.

func update_reaction(delta: float) -> void: # Animates selected freeplay species into a retained product without ending the sandbox.
	if state.freeplay_reaction == null: # Ignores updates without an active manual reaction.
		return # Leaves state unchanged.
	var reaction: ReactionState = state.freeplay_reaction # Retains a typed local reference for the frame.
	reaction.elapsed += delta # Advances reaction time.
	var ratio: float = clampf(reaction.elapsed / reaction.duration, 0.0, 1.0) # Normalizes progress.
	var eased: float = 1.0 - pow(1.0 - ratio, 3.0) # Preserves the browser cubic ease-out curve.
	for index: int in reaction.atom_ids.size(): # Moves each selected species independently.
		var atom: AtomState = _find_atom_by_id(reaction.atom_ids[index]) # Resolves the live reactant.
		if atom == null: # Tolerates a missing atom defensively.
			continue # Leaves that reaction slot unchanged.
		atom.position = reaction.start_positions[index].lerp(reaction.center + reaction.layout[index], eased) # Interpolates into product-local position.
		atom.velocity = Vector2.ZERO # Stops atom drift while combining.
	if ratio >= 1.0: # Finalizes the retained freeplay product.
		var consumed: Dictionary = {} # Builds a set of consumed atom identifiers.
		for atom_id: int in reaction.atom_ids: # Reads every participating species identifier.
			consumed[atom_id] = true # Marks it for removal.
		for index: int in range(state.atoms.size() - 1, -1, -1): # Removes consumed atoms in reverse.
			if consumed.has(state.atoms[index].id): # Detects a consumed reactant.
				state.atoms.remove_at(index) # Removes it from the live workspace.
		var product: FreeplayProductState = FreeplayProductState.new() # Allocates the retained schematic product.
		product.position = reaction.center # Stores its world centre.
		product.formula = reaction.formula # Stores its ASCII formula.
		product.product_name = reaction.product_name # Stores its known or verified name.
		product.snapshots = reaction.snapshots.duplicate(true) # Preserves consumed atom composition.
		product.layout = reaction.layout.duplicate() # Preserves local product coordinates.
		product.bonds = reaction.bonds.duplicate(true) # Preserves schematic connectivity.
		state.freeplay_products.append(product) # Keeps the product visible while freeplay continues.
		var formed: String = ReactionLibrary.pretty_formula_from_ascii(reaction.formula) # Creates display chemistry notation.
		state.freeplay_reaction = null # Ends manual reaction animation.
		controller.set_status("%s Formed — Freeplay Continues" % formed, 2.5) # Preserves browser completion feedback.
		controller.refresh_freeplay_ui() # Refreshes freeplay controls after completion.
		controller.refresh_inspector() # Clears any inspector reference consumed by the reaction.

func _start_reaction(selected: Array[AtomState], formula: String, product_name: String) -> void: # Begins deterministic freeplay combination after a formula is accepted.
	var center: Vector2 = Vector2.ZERO # Accumulates selected species positions for reaction centering.
	for atom: AtomState in selected: # Sums every selected world position.
		center += atom.position # Adds one reactant centre.
	center /= float(selected.size()) # Calculates the mean reaction centre.
	center.x = clampf(center.x, 220.0, ChemistryData.WORLD_SIZE.x - 220.0) # Preserves browser horizontal product bounds.
	center.y = clampf(center.y, 190.0, ChemistryData.WORLD_SIZE.y - 220.0) # Preserves browser vertical product bounds.
	var reaction: ReactionState = ReactionState.new() # Allocates native manual reaction state.
	reaction.duration = 2.1 # Preserves the browser freeplay reaction duration.
	reaction.center = center # Stores the bounded product centre.
	reaction.formula = formula # Stores normalized product formula.
	reaction.product_name = product_name # Stores the known or verified product name.
	reaction.layout = ReactionLibrary.generic_product_layout(selected.size()) # Generates the same browser schematic product positions.
	reaction.bonds = ReactionLibrary.generic_product_bonds(selected.size()) # Generates the same browser schematic connectivity.
	for atom: AtomState in selected: # Snapshots every selected reactant.
		reaction.atom_ids.append(atom.id) # Stores its unique world identifier.
		reaction.start_positions.append(atom.position) # Stores its pre-reaction position.
		reaction.snapshots.append({"protons": atom.protons, "neutrons": atom.neutrons, "electrons": atom.electrons, "symbol": ChemistryData.element_symbol(atom.protons)}) # Preserves particle counts for retained rendering.
	state.freeplay_reaction = reaction # Activates manual reaction processing.
	state.freeplay_selected_ids.clear() # Clears reaction selection as combination begins.
	state.freeplay_select_mode = false # Leaves reactant-selection mode.
	state.particles.clear() # Removes stray projectiles just like the browser implementation.
	state.selected_atom_id = -1 # Clears atom inspection.
	controller.set_status("%s Validated — Reacting" % ReactionLibrary.pretty_formula_from_ascii(formula), 0.0) # Displays persistent validation feedback during combination.
	controller.refresh_freeplay_ui() # Updates selection and control state.
	controller.refresh_inspector() # Clears the native inspector.

func _find_atom_by_id(atom_id: int) -> AtomState: # Resolves one live world atom by identifier.
	for atom: AtomState in state.atoms: # Searches the small active atom list.
		if atom.id == atom_id: # Matches the requested unique identifier.
			return atom # Returns the live atom reference.
	return null # Reports that the atom no longer exists.
