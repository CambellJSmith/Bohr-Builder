class_name BohrBuilderOddityController # Adapts Bohr Builder's existing controller to the Oddity shared input and sensitivity contract.
extends BohrBuilderController # Preserves the established gameplay controller while overriding only shared-platform behavior.

const BUTTON_INSPECT: StringName = &"Button_Inspect" # Uses a dedicated game-specific action for atom inspection instead of overloading Button_B.

var _oddity_settings_service: OdditySettingsService = null # Caches the typed application service without creating a compile-time dependency on its autoload singleton name.

func _handle_key_event(event: InputEventKey) -> void: # Routes canonical keyboard equivalents through semantic Oddity actions before legacy game-specific shortcuts.
	if event.is_action_pressed(BUTTON_B): # Maps the standard negative action to back, cancel, or return behavior.
		_handle_negative_action() # Cancels the most immediate reversible UI or interaction state.
		get_viewport().set_input_as_handled() # Prevents Escape from also triggering an unrelated native UI path.
		return # Stops after the semantic negative action has been consumed.
	if event.is_action_pressed(BUTTON_START): # Maps the standard system action to the mode/system overlay.
		_toggle_system_menu() # Opens or closes the modal without repurposing Start for gameplay.
		get_viewport().set_input_as_handled() # Prevents the legacy M shortcut from executing a second time.
		return # Stops after handling the system-menu action.
	if event.is_action_pressed(BUTTON_INSPECT): # Routes the explicit inspect shortcut through its semantic action.
		_inspect_atom_at_pointer() # Inspects the atom beneath the current aim point.
		get_viewport().set_input_as_handled() # Prevents the legacy direct I shortcut from executing again.
		return # Stops after the inspection action.
	if event.is_action_pressed(BUTTON_A): # Maps Enter and Space to the canonical positive or primary action.
		_activate_focused_control(true) # Activates focused UI or starts the contextual workspace primary action.
		get_viewport().set_input_as_handled() # Prevents duplicate native or legacy key activation.
		return # Stops after the positive action press.
	if event.is_action_released(BUTTON_A): # Detects release of the canonical primary action.
		_activate_focused_control(false) # Releases continuous workspace firing when the workspace owns focus.
		get_viewport().set_input_as_handled() # Prevents a second release path from seeing the same event.
		return # Stops after the positive action release.
	if event.pressed and not event.echo and _route_left_stick_navigation_event(event): # Uses WASD as left-stick menu navigation whenever UI rather than the workspace owns focus.
		get_viewport().set_input_as_handled() # Prevents the same navigation key from escaping into legacy shortcuts.
		return # Stops after semantic menu navigation.
	super._handle_key_event(event) # Preserves game-specific number, particle, reset, reaction, and campaign shortcuts that are outside the shared contract.

func _handle_controller_event(event: InputEvent) -> void: # Applies Oddity controller semantics before delegating game-specific controller actions to the existing implementation.
	if event.is_action_pressed(BUTTON_B): # Reserves Button_B for negative, back, and cancel behavior.
		_handle_negative_action() # Cancels the nearest reversible interaction instead of inspecting an atom.
		get_viewport().set_input_as_handled() # Prevents the old Button_B inspection branch from receiving this event.
		return # Stops after the canonical negative action.
	if event.is_action_pressed(BUTTON_START): # Reserves Button_Start for the system/menu role.
		_toggle_system_menu() # Opens or closes the mode/system overlay without triggering an ordinary gameplay action.
		get_viewport().set_input_as_handled() # Prevents the base controller from opening the overlay a second time.
		return # Stops after the system-menu action.
	if event.is_action_pressed(BUTTON_INSPECT): # Routes controller Back/View to the explicit game-specific inspect action.
		_inspect_atom_at_pointer() # Inspects the atom beneath the current aim point.
		get_viewport().set_input_as_handled() # Prevents any legacy Back/View action from also executing.
		return # Stops after inspection.
	if _route_left_stick_navigation_event(event): # Uses the primary left stick for menu navigation whenever a UI control owns focus.
		get_viewport().set_input_as_handled() # Prevents the same analogue event from reaching another focus route.
		return # Stops after menu navigation.
	super._handle_controller_event(event) # Preserves A, X, Y, shoulders, triggers, stick clicks, and D-pad game-specific behavior.

func _process_aim_input(delta: float) -> void: # Applies keyboard and controller aim with shared deadzone and controller-sensitivity settings.
	if state.mode_prompt_open: # Prevents world aim movement while the system/mode overlay owns interaction.
		return # Leaves the current pointer position unchanged behind the modal.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads native UI focus so left-stick navigation and workspace aiming remain distinct.
	if focus_owner != null and focus_owner != workspace: # Gives visible interface controls ownership of WASD and left-stick navigation while focused.
		return # Leaves world aim stationary until the workspace regains focus.
	var keyboard_axis: Vector2 = Vector2.ZERO # Accumulates the canonical WASD keyboard equivalent of the left stick.
	keyboard_axis.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)) # Reads horizontal WASD intent without arrow-key aliases.
	keyboard_axis.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)) # Reads vertical WASD intent without arrow-key aliases.
	if keyboard_axis.length_squared() > 0.0: # Gives active keyboard aim priority so the same WASD InputMap bindings are not counted again as controller-style action strength.
		workspace.grab_focus() # Keeps visible focus on the construction workspace while aiming.
		_move_aim(keyboard_axis, KEYBOARD_AIM_SPEED, delta) # Uses the authored keyboard speed without applying controller sensitivity.
		return # Skips the combined action vector while a keyboard direction is held.
	var settings_service: OdditySettingsService = _get_oddity_settings_service() # Resolves the typed application service without relying on an injected autoload identifier.
	var deadzone: float = settings_service.controller_deadzone() if settings_service != null else SharedSettings.DEFAULT_CONTROLLER_DEADZONE # Reads the shared analogue deadzone or the canonical fallback.
	var controller_axis: Vector2 = Input.get_vector(STICK_LEFT_WEST, STICK_LEFT_EAST, STICK_LEFT_NORTH, STICK_LEFT_SOUTH, deadzone) # Reads the canonical semantic left-stick vector with one centralized deadzone.
	if controller_axis.length_squared() <= 0.0001: # Ignores residual analogue noise inside the validated deadzone.
		return # Leaves aim unchanged when no meaningful controller intent exists.
	workspace.grab_focus() # Keeps controller aim anchored to the construction workspace.
	var sensitivity: float = settings_service.controller_sensitivity() if settings_service != null else SharedSettings.DEFAULT_SENSITIVITY # Reads the shared controller multiplier or the canonical fallback.
	_move_aim(controller_axis, CONTROLLER_AIM_SPEED * sensitivity, delta) # Scales the authored controller aim speed exactly once.

func _route_left_stick_navigation_event(event: InputEvent) -> bool: # Converts canonical left-stick actions into interface navigation when the workspace is not the active target.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads current native focus to distinguish menu navigation from world aiming.
	if not state.mode_prompt_open and (focus_owner == null or focus_owner == workspace): # Leaves left-stick events available for continuous world aim when gameplay owns focus.
		return false # Reports that no interface navigation consumed this event.
	if event.is_action_pressed(STICK_LEFT_NORTH): # Detects upward canonical left-stick intent.
		_navigate_focus(&"up") # Moves native UI focus upward using the existing spatial navigation system.
		return true # Reports that interface navigation consumed the event.
	if event.is_action_pressed(STICK_LEFT_SOUTH): # Detects downward canonical left-stick intent.
		_navigate_focus(&"down") # Moves native UI focus downward.
		return true # Reports that interface navigation consumed the event.
	if event.is_action_pressed(STICK_LEFT_WEST): # Detects leftward canonical left-stick intent.
		_navigate_focus(&"left") # Moves native UI focus leftward.
		return true # Reports that interface navigation consumed the event.
	if event.is_action_pressed(STICK_LEFT_EAST): # Detects rightward canonical left-stick intent.
		_navigate_focus(&"right") # Moves native UI focus rightward.
		return true # Reports that interface navigation consumed the event.
	return false # Reports that this event was not a canonical navigation press.

func _handle_negative_action() -> void: # Applies Button_B and Escape consistently as cancel, back, dismiss, or return.
	if state.mode_prompt_open: # Gives the modal system/mode overlay first ownership of the negative action.
		_close_system_menu() # Dismisses the overlay only when a gameplay mode has already been selected.
		return # Stops after modal cancellation handling.
	if state.freeplay_select_mode: # Treats active freeplay reactant selection as a cancellable interaction mode.
		_toggle_reactant_selection() # Leaves reactant-selection mode and restores ordinary workspace behavior.
		return # Stops after cancelling the selection mode.
	if state.scrap_mode: # Treats active scrap mode as a cancellable interaction mode.
		_toggle_scrap_mode() # Leaves scrap mode and restores ordinary workspace behavior.
		return # Stops after cancelling scrap mode.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads current interface focus for ordinary back navigation.
	if focus_owner != null and focus_owner != workspace: # Returns from a focused sidebar or action control to the primary gameplay surface.
		workspace.grab_focus() # Restores construction workspace focus without performing an unrelated action.

func _toggle_system_menu() -> void: # Uses Button_Start consistently to open or resume from Bohr Builder's system/mode overlay.
	if state.mode_prompt_open: # Detects an already-open overlay.
		_close_system_menu() # Resumes the current mode when a current mode exists.
		return # Stops after attempting to close the overlay.
	open_mode_overlay() # Opens the existing modal system/mode chooser during gameplay.

func _close_system_menu() -> void: # Closes the modal without resetting or changing the current game mode.
	if not state.mode_prompt_open or state.game_mode == &"": # Keeps the required first-launch mode choice open until the player selects a real mode.
		return # Leaves startup mode selection unchanged when there is no gameplay state to resume.
	state.pointer_down = false # Releases any held primary fire before returning to gameplay.
	state.mode_prompt_open = false # Resumes the existing gameplay simulation state.
	mode_overlay.visible = false # Hides the modal system/mode chooser.
	workspace.grab_focus() # Restores keyboard and controller focus to the primary construction surface.

func _get_oddity_settings_service() -> OdditySettingsService: # Resolves and caches the application service by its stable autoload tree path.
	if _oddity_settings_service == null or not is_instance_valid(_oddity_settings_service): # Refreshes the cache after startup ordering or unusual tree replacement.
		_oddity_settings_service = get_node_or_null(^"/root/OdditySettings") as OdditySettingsService # Uses a NodePath lookup so standalone script parsing does not require the autoload identifier.
	return _oddity_settings_service # Returns the cached typed service or null when running outside the full application tree.
