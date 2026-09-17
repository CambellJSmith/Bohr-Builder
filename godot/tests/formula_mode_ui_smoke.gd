extends SceneTree # Verifies Formula Mode exposes the same campaign information as Guided Mode except for atom requirements.

func _initialize() -> void: # Builds the native main scene and applies the Formula Mode presentation helper synchronously.
	var packed_scene: PackedScene = load("res://godot/bohr_builder_native.tscn") as PackedScene # Loads the production native interface.
	if packed_scene == null: # Rejects a missing or invalid main scene.
		_fail("Could not load the native Bohr Builder scene.") # Reports the setup failure.
		return # Stops the smoke test.
	var controller: BohrBuilderController = packed_scene.instantiate() as BohrBuilderController # Creates the real application controller and UI tree.
	if controller == null: # Rejects an unexpected root type.
		_fail("Native main scene did not instantiate as BohrBuilderController.") # Reports the type mismatch.
		return # Stops the smoke test.
	root.add_child(controller) # Runs the production controller _ready() path and populates campaign state.
	current_scene = controller # Makes the instantiated game visible to presenter scene lookup.
	controller.size = Vector2(1500.0, 900.0) # Uses the normal desktop viewport size so secondary campaign names should be visible.
	controller.call("_set_game_mode", &"formula_only") # Enters Formula Mode through the production semantic mode transition.
	var presenter: CampaignModePresenter = CampaignModePresenter.new() # Creates the production campaign presentation helper directly for deterministic testing.
	root.add_child(presenter) # Gives the presenter access to the active SceneTree and controller.
	presenter.call("_process", 0.0) # Applies Formula Mode parity immediately without waiting for a rendered frame.
	var entry: Dictionary = controller.campaign[controller.state.current_level_index] # Reads the active campaign definition for expected labels.
	if controller.requirement_group.visible: # Formula Mode must hide the explicit atom recipe.
		_fail("Formula Mode requirement group should be hidden.") # Reports the only intended visibility difference failing.
		return # Stops the smoke test.
	if not controller.guided_level_details.visible: # Lesson and equation should match Guided Mode.
		_fail("Formula Mode should show the Guided lesson and equation section.") # Reports missing campaign information.
		return # Stops the smoke test.
	if not controller.target_name.visible: # Molecule target name should match Guided Mode at desktop width.
		_fail("Formula Mode should show the target molecule name.") # Reports missing target naming.
		return # Stops the smoke test.
	var expected_name: String = _display_name(String(entry["name"])) # Formats the expected molecule name exactly like the production UI.
	if controller.target_name.text != expected_name: # Confirms the target name is populated, not merely visible.
		_fail("Formula Mode target molecule name does not match Guided Mode.") # Reports incorrect target naming.
		return # Stops the smoke test.
	var expected_title: String = _display_name(String(entry["title"])) # Formats the expected campaign title.
	if controller.level_title.text != expected_title: # Rejects the old generic Formula Challenge title.
		_fail("Formula Mode level title does not match Guided Mode.") # Reports title divergence.
		return # Stops the smoke test.
	if not controller.level_select.get_item_text(controller.state.current_level_index).contains(expected_name): # Confirms selector entries retain molecule names.
		_fail("Formula Mode level selector should include molecule names.") # Reports stripped selector information.
		return # Stops the smoke test.
	if controller.status_label.text != "Easy Start — Make Two Hydrogen Atoms: Fire A Proton To Start Each Nucleus, Then Capture One Electron On Each First Shell": # Confirms the default first-level guidance matches Guided Mode.
		_fail("Formula Mode default campaign guidance does not match Guided Mode.") # Reports status-text divergence.
		return # Stops the smoke test.
	controller.state.molecule_active = true # Simulates a completed campaign reaction after the production reaction system has formed the molecule.
	controller.state.molecule_position = ChemistryData.WORLD_SIZE * Vector2(0.5, 0.42) # Uses the same final product position as the campaign system.
	presenter.call("_process", 0.0) # Updates completed-product presentation for Formula Mode.
	var product_name_label: Label = controller.workspace.get_node_or_null("Formula Product Name") as Label # Finds the supplemental name used to match Guided completed-product rendering.
	if product_name_label == null or not product_name_label.visible or product_name_label.text != expected_name: # Requires the completed molecule name to remain visible in Formula Mode.
		_fail("Formula Mode completed product should display the same molecule name as Guided Mode.") # Reports post-reaction naming divergence.
		return # Stops the smoke test.
	quit(0) # Reports success after all Formula-versus-Guided presentation invariants pass.

func _fail(message: String) -> void: # Reports one deterministic smoke-test failure and exits non-zero.
	push_error(message) # Writes the exact failed invariant to the Godot test log.
	quit(1) # Fails the CI step immediately.

func _display_name(value: String) -> String: # Mirrors production title-style display formatting for expected values.
	return value.replace("_", " ").capitalize() # Converts internal names to the native UI representation.
