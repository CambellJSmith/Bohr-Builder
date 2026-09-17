extends SceneTree # Exercises the production reaction-presentation layer after the real native scene has completed its ready path.

var _controller: BohrBuilderController = null # Retains the instantiated production controller while the smoke test runs.
var _presenter: ReactionPresentationLayer = null # Retains the production reaction presentation autoload for direct invariant checks.

func _initialize() -> void: # Instantiates the real native scene and defers reaction-presentation assertions until all @onready references exist.
	var packed_scene: PackedScene = load("res://godot/bohr_builder_native.tscn") as PackedScene # Loads the production native game scene.
	if packed_scene == null: # Rejects a missing or invalid main scene immediately.
		_fail("Could not load the native Bohr Builder scene.") # Reports the setup failure.
		return # Stops the smoke test before dereferencing an invalid scene.
	_controller = packed_scene.instantiate() as BohrBuilderController # Creates the real production controller and complete UI tree.
	if _controller == null: # Rejects an unexpected root type.
		_fail("Native main scene did not instantiate as BohrBuilderController.") # Reports the root type mismatch.
		return # Stops the smoke test.
	root.add_child(_controller) # Adds the production game to the active SceneTree so its normal ready path runs.
	current_scene = _controller # Makes the production game discoverable through SceneTree.current_scene just like a normal launch.
	call_deferred("_run_test_after_ready") # Defers all interaction until controller @onready references, systems, and campaign data are initialized.

func _run_test_after_ready() -> void: # Triggers a production-style successful result and verifies generated audio, particles, and staged completion data.
	_presenter = root.get_node_or_null("ReactionPresentation") as ReactionPresentationLayer # Resolves the autoload registered by project.godot.
	if _presenter == null: # Rejects a missing presentation autoload.
		_fail("ReactionPresentation autoload is missing.") # Reports the integration failure.
		return # Stops before attempting presentation calls.
	_controller.call("_set_game_mode", &"guided") # Enters a normal campaign mode through the production semantic mode transition.
	_controller.state.molecule_active = true # Simulates CampaignSystem's successful post-reaction product state.
	_controller.state.molecule_position = ChemistryData.WORLD_SIZE * Vector2(0.5, 0.42) # Uses the exact production campaign molecule centre.
	_presenter.call("_bind_scene", _controller) # Establishes the live controller reference exactly as the autoload does during normal play.
	_presenter.call("_finish_campaign_reaction") # Starts the production completion flash, particles, generated chime, and result reveal timeline.
	if _presenter._completion_formula != String(_controller.campaign_system.current_level()["formula"]): # Confirms the visible reveal uses authoritative campaign chemistry data.
		_fail("Reaction presentation formula does not match the completed campaign target.") # Reports incorrect result capture.
		return # Stops the smoke test.
	if _presenter._completion_name.is_empty(): # Requires the staged molecule-name reveal to contain readable product identity.
		_fail("Reaction presentation did not capture the completed molecule name.") # Reports missing molecule naming.
		return # Stops the smoke test.
	if _presenter._completion_heading != "Level 01 Complete": # Requires an explicit level-complete state for the first campaign target.
		_fail("Reaction presentation did not create the expected level-complete heading.") # Reports unclear progression feedback.
		return # Stops the smoke test.
	if _presenter._completion_subheading != "Next Level Unlocked": # Requires progression feedback after successful non-final campaign completion.
		_fail("Reaction presentation did not create the next-level unlock message.") # Reports missing progression feedback.
		return # Stops the smoke test.
	if _presenter._burst_particles.size() != 42: # Requires the configured native completion particle burst to be created.
		_fail("Reaction presentation did not create the expected completion particle burst.") # Reports missing visual impact feedback.
		return # Stops the smoke test.
	if _presenter._reaction_start_player == null or _presenter._reaction_start_player.stream == null: # Requires generated reaction-start audio to exist without external assets.
		_fail("Reaction presentation start audio was not generated.") # Reports missing build-up audio.
		return # Stops the smoke test.
	if _presenter._reaction_complete_player == null or _presenter._reaction_complete_player.stream == null: # Requires generated success audio to exist without external assets.
		_fail("Reaction presentation completion audio was not generated.") # Reports missing success audio.
		return # Stops the smoke test.
	_presenter.call("_process", 1.25) # Advances beyond every staged formula/name/completion reveal threshold.
	_presenter.queue_redraw() # Requests a real CanvasItem draw pass for the completion flash, particles, and result card.
	await process_frame # Allows Godot to execute the production presentation draw callback once.
	await process_frame # Allows one additional frame so any deferred CanvasItem/runtime errors surface before success.
	quit(0) # Reports success after production reaction presentation executes without runtime errors.

func _fail(message: String) -> void: # Reports one deterministic presentation regression and exits non-zero.
	push_error(message) # Writes the exact failed invariant to the Godot Actions log.
	quit(1) # Fails the CI step immediately.
