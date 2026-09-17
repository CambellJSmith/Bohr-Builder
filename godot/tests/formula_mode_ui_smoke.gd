extends SceneTree # Verifies Formula Mode exposes the same campaign information as Guided Mode except for atom requirements.

var _controller: BohrBuilderController = null # Holds the production controller until its deferred post-ready assertions run.

func _initialize() -> void: # Builds the native main scene and defers assertions until @onready references and campaign data exist.
	var packed_scene: PackedScene = load("res://godot/bohr_builder_native.tscn") as PackedScene # Loads the production native interface.
	if packed_scene == null: # Rejects a missing or invalid main scene.
		_fail("Could not load the native Bohr Builder scene.") # Reports the setup failure.
		return # Stops the smoke test.
	_controller = packed_scene.instantiate() as BohrBuilderController # Creates the real application controller and UI tree.
	if _controller == null: # Rejects an unexpected root type.
		_fail("Native main scene did not instantiate as BohrBuilderController.") # Reports the type mismatch.
		return # Stops the smoke test.
	root.add_child(_controller) # Adds the production interface to the live SceneTree so its normal ready lifecycle can run.
	current_scene = _controller # Makes the instantiated game visible to the production presenter autoload.
	call_deferred("_run_test_after_ready") # Waits until the scene's @onready references, systems and generated campaign are initialized.

func _run_test_after_ready() -> void: # Enters Formula Mode after production _ready() and checks every intended parity surface.
	if _controller == null or not is_instance_valid(_controller) or not _controller.is_node_ready(): # Requires a fully initialized production controller.
		_fail("Native controller was not ready for Formula Mode UI assertions.") # Reports an invalid test lifecycle.
		return # Stops the smoke test.
	_controller.call("_set_game_mode", &"formula_only") # Enters Formula Mode through the production semantic mode transition.
	var presenter: CampaignModePresenter = root.get_node_or_null("FormulaModePresenter") as CampaignModePresenter # Reuses the production autoload when the project has instantiated it.
	if presenter == null: # Provides a deterministic fallback for script-run environments that omit autoload instantiation.
		presenter = CampaignModePresenter.new() # Creates the same production presenter class directly.
		root.add_child(presenter) # Gives the fallback presenter a live SceneTree before processing.
	presenter.call("_process", 0.0) # Applies Formula Mode parity immediately for deterministic assertions.
	if _controller.campaign.is_empty(): # Requires generated campaign data before reading active level metadata.
		_fail("Campaign data was empty after the native controller became ready.") # Reports an invalid application startup state.
		return # Stops the smoke test.
	var entry: Dictionary = _controller.campaign[_controller.state.current_level_index] # Reads the active campaign definition for expected labels.
	if _controller.requirement_group.visible: # Formula Mode must hide the explicit atom recipe.
		_fail("Formula Mode requirement group should be hidden.") # Reports the only intended visibility difference failing.
		return # Stops the smoke test.
	if not _controller.guided_level_details.visible: # Lesson and equation should match Guided Mode.
		_fail("Formula Mode should show the Guided lesson and equation section.") # Reports missing campaign information.
		return # Stops the smoke test.
	if not _controller.target_name.visible: # Molecule target name should match Guided Mode at the normal desktop project width.
		_fail("Formula Mode should show the target molecule name.") # Reports missing target naming.
		return # Stops the smoke test.
	var expected_name: String = _display_name(String(entry["name"])) # Formats the expected molecule name exactly like the production UI.
	if _controller.target_name.text != expected_name: # Confirms the target name is populated, not merely visible.
		_fail("Formula Mode target molecule name does not match Guided Mode.") # Reports incorrect target naming.
		return # Stops the smoke test.
	var expected_title: String = _display_name(String(entry["title"])) # Formats the expected campaign title.
	if _controller.level_title.text != expected_title: # Rejects the old generic Formula Challenge title.
		_fail("Formula Mode level title does not match Guided Mode.") # Reports title divergence.
		return # Stops the smoke test.
	if not _controller.level_select.get_item_text(_controller.state.current_level_index).contains(expected_name): # Confirms selector entries retain molecule names.
		_fail("Formula Mode level selector should include molecule names.") # Reports stripped selector information.
		return # Stops the smoke test.
	if _controller.status_label.text != "Easy Start — Make Two Hydrogen Atoms: Fire A Proton To Start Each Nucleus, Then Capture One Electron On Each First Shell": # Confirms the default first-level guidance matches Guided Mode.
		_fail("Formula Mode default campaign guidance does not match Guided Mode.") # Reports status-text divergence.
		return # Stops the smoke test.
	_controller.state.molecule_active = true # Simulates a completed campaign reaction after the production reaction system has formed the molecule.
	_controller.state.molecule_position = ChemistryData.WORLD_SIZE * Vector2(0.5, 0.42) # Uses the same final product position as the campaign system.
	presenter.call("_process", 0.0) # Updates completed-product presentation for Formula Mode.
	var product_name_label: Label = _controller.workspace.get_node_or_null("Formula Product Name") as Label # Finds the supplemental name used to match Guided completed-product rendering.
	if product_name_label == null or not product_name_label.visible or product_name_label.text != expected_name: # Requires the completed molecule name to remain visible in Formula Mode.
		_fail("Formula Mode completed product should display the same molecule name as Guided Mode.") # Reports post-reaction naming divergence.
		return # Stops the smoke test.
	quit(0) # Reports success after all Formula-versus-Guided presentation invariants pass.

func _fail(message: String) -> void: # Reports one deterministic smoke-test failure and exits non-zero.
	push_error(message) # Writes the exact failed invariant to the Godot test log.
	quit(1) # Fails the CI step immediately.

func _display_name(value: String) -> String: # Mirrors production title-style display formatting for expected values.
	return value.replace("_", " ").capitalize() # Converts internal names to the native UI representation.
