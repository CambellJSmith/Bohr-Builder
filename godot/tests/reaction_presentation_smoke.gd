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

func _run_test_after_ready() -> void: # Triggers a production-style successful result and verifies generated effects, staged completion data, overlay progression, and immediate dismissal.
	_presenter = root.get_node_or_null("ReactionPresentation") as ReactionPresentationLayer # Resolves the autoload registered by project.godot.
	if _presenter == null: # Rejects a missing presentation autoload.
		_fail("ReactionPresentation autoload is missing.") # Reports the integration failure.
		return # Stops before attempting presentation calls.
	_controller.call("_set_game_mode", &"guided") # Enters a normal campaign mode through the production semantic mode transition.
	_controller.state.molecule_active = true # Simulates CampaignSystem's successful post-reaction product state.
	_controller.state.molecule_position = ChemistryData.WORLD_SIZE * Vector2(0.5, 0.42) # Uses the exact production campaign molecule centre.
	_presenter.call("_bind_scene", _controller) # Establishes the live controller reference exactly as the autoload does during normal play.
	var completion_overlay: Control = _controller.get_node_or_null(^"CompletionOverlay") as Control # Resolves the editor-defined presentation overlay that should own progression at runtime.
	if completion_overlay == null: # Requires the dedicated completion overlay to exist in the production scene.
		_fail("Completion overlay is missing from the native scene.") # Reports an invalid scene integration.
		return # Stops before checking button ownership.
	if _controller.next_button.get_parent() != completion_overlay: # Requires runtime composition to remove progression from the right sidebar.
		_fail("Next Level button was not moved into the completion overlay.") # Reports the stale sidebar placement.
		return # Stops before testing staged presentation.
	_controller.campaign_system.complete_level() # Mirrors production completion by unlocking the next campaign level before the presentation layer reveals progression.
	_presenter.call("_finish_campaign_reaction") # Starts the production completion flash, particles, generated chime, result reveal, and progression timeline.
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
	if not _presenter._completion_has_next_level: # Requires the first campaign completion to expose the staged progression action.
		_fail("Reaction presentation did not record next-level progression availability.") # Reports incorrect campaign completion state.
		return # Stops the smoke test.
	if _controller.next_button.visible or not _controller.next_button.disabled: # Requires progression to remain hidden while the celebratory information sequence begins.
		_fail("Next Level button became interactive before the completion sequence finished.") # Reports premature progression exposure.
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
	_presenter.call("_process", 1.65) # Advances beyond formula, name, level-complete text, unlock copy, and the final button fade threshold.
	if not _controller.next_button.visible or _controller.next_button.disabled: # Requires the completed sequence to expose an active native progression action.
		_fail("Next Level button was not revealed after the completion sequence.") # Reports missing final progression UI.
		return # Stops the smoke test.
	if _controller.next_button.text != "Next Level": # Requires the completion action to keep the established player-facing label.
		_fail("Completion progression button does not display Next Level.") # Reports an unexpected action label regression.
		return # Stops the smoke test.
	if not _controller.workspace.get_global_rect().encloses(_controller.next_button.get_global_rect()): # Requires the button to live visually inside the workspace completion presentation rather than the sidebar.
		_fail("Next Level button is not positioned inside the workspace completion card.") # Reports incorrect responsive placement.
		return # Stops the smoke test.
	if not _controller.next_button.has_focus(): # Requires keyboard and controller users to land directly on the newly revealed primary action.
		_fail("Next Level button did not receive focus when it became interactive.") # Reports inaccessible completion progression.
		return # Stops the smoke test.
	_presenter.queue_redraw() # Requests a real CanvasItem draw pass for the completion flash, particles, result card, and button backing.
	await process_frame # Allows Godot to execute the production presentation draw callback once.
	_controller.call("_handle_button_action", &"NextButton") # Activates the same semantic Next Level path used by mouse, keyboard, and controller input.
	_presenter.call("_process", 0.0) # Runs the post-input presentation pass that must clear the completion state before the next draw.
	if _controller.state.current_level_index != 1: # Requires progression to advance from level one to level two.
		_fail("Next Level did not advance the campaign after completion.") # Reports broken progression while testing dismissal.
		return # Stops the smoke test.
	if _presenter._completion_elapsed >= 0.0 or not _presenter._completion_formula.is_empty() or not _presenter._completion_heading.is_empty(): # Requires all staged completion content to be cleared immediately after progression.
		_fail("Completion presentation state remained active after Next Level was pressed.") # Reports the stale completion-card regression.
		return # Stops the smoke test.
	if _controller.next_button.visible or not _controller.next_button.disabled: # Requires the old progression control to disappear with the dismissed result card.
		_fail("Next Level button remained visible after advancing to the next campaign level.") # Reports stale overlay interaction.
		return # Stops the smoke test.
	await process_frame # Allows the queued redraw from completion dismissal to replace the old CanvasItem draw commands.
	await process_frame # Allows one additional frame so any deferred CanvasItem/runtime errors surface before success.
	quit(0) # Reports success after production reaction presentation executes and dismisses without runtime errors.

func _fail(message: String) -> void: # Reports one deterministic presentation regression and exits non-zero.
	push_error(message) # Writes the exact failed invariant to the Godot Actions log.
	quit(1) # Fails the CI step immediately.
