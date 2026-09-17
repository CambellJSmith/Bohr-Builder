class_name BohrModeClickRouter # Routes overlay mouse clicks independently of the workspace input handler.
extends Node # Polls the physical mouse state so consumed viewport input cannot suppress native overlay activation.

const MODE_OVERLAY_PATH: NodePath = ^"ModeOverlay" # Locates the modal overlay on the active Bohr Builder scene.
const GUIDED_RESPONSIVE_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/Responsive Mode Grid/GuidedModeButton" # Locates the guided button after responsive reparenting.
const FORMULA_RESPONSIVE_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/Responsive Mode Grid/FormulaModeButton" # Locates the formula-only button after responsive reparenting.
const FREEPLAY_RESPONSIVE_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/Responsive Mode Grid/FreeplayModeButton" # Locates the freeplay button after responsive reparenting.
const GUIDED_ORIGINAL_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/ModeGrid/GuidedModeButton" # Locates the guided button before responsive reparenting.
const FORMULA_ORIGINAL_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/ModeGrid/FormulaModeButton" # Locates the formula-only button before responsive reparenting.
const FREEPLAY_ORIGINAL_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/ModeGrid/FreeplayModeButton" # Locates the freeplay button before responsive reparenting.
const NEXT_LEVEL_OVERLAY_PATH: NodePath = ^"CompletionOverlay/NextButton" # Locates the next-level button after the reaction presenter moves it into the completion overlay.
const NEXT_LEVEL_ORIGINAL_PATH: NodePath = ^"AppMargin/AppShell/WorkspaceLayout/Sidebar/ActionGroup/NextButton" # Locates the next-level button before reaction presentation has rebound it.

var _left_was_down: bool = false # Remembers the previous physical mouse-button state so one click activates only once.

func _ready() -> void: # Enables per-frame overlay click polling.
	set_process(true) # Keeps the router active while the native game scene is running.

func _process(_delta: float) -> void: # Detects a fresh physical left-click and routes it to visible overlay controls.
	var left_is_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) # Reads the physical mouse state independently of consumed InputEvent routing.
	if left_is_down and not _left_was_down: # Reacts only to the rising edge of a new click.
		if not _try_activate_mode_at_mouse(): # Gives the modal chooser first ownership of clicks while it is visible.
			_try_activate_completion_at_mouse() # Routes completed-level clicks when no mode button consumed the click.
	_left_was_down = left_is_down # Stores the state for the next frame's edge detection.

func _try_activate_mode_at_mouse() -> bool: # Activates the mode button directly under the current mouse position when the modal is visible.
	var scene: Node = get_tree().current_scene # Reads the active application scene.
	if scene == null or scene.name != "Bohr Builder": # Ignores startup frames and unrelated scenes.
		return false # Reports that no mode control handled the click.
	var overlay: Control = scene.get_node_or_null(MODE_OVERLAY_PATH) as Control # Resolves the current mode overlay.
	if overlay == null or not overlay.is_visible_in_tree(): # Requires the chooser to be visibly open.
		return false # Leaves the click available for other overlay controls.
	var mouse_position: Vector2 = scene.get_viewport().get_mouse_position() # Reads the current viewport-space pointer position.
	var buttons: Array[Button] = [ # Resolves all three cards whether or not responsive reparenting has already happened.
		_resolve_button(scene, GUIDED_RESPONSIVE_PATH, GUIDED_ORIGINAL_PATH), # Resolves the guided mode card.
		_resolve_button(scene, FORMULA_RESPONSIVE_PATH, FORMULA_ORIGINAL_PATH), # Resolves the formula-only mode card.
		_resolve_button(scene, FREEPLAY_RESPONSIVE_PATH, FREEPLAY_ORIGINAL_PATH), # Resolves the freeplay mode card.
	] # Completes the ordered mode-button set.
	for button: Button in buttons: # Tests each mode card against the click position.
		if button == null or not button.is_visible_in_tree() or button.disabled: # Skips unavailable controls safely.
			continue # Moves to the next mode choice.
		if not button.get_global_rect().has_point(mouse_position): # Rejects clicks outside this button's displayed rectangle.
			continue # Moves to the next mode choice.
		button.grab_focus() # Preserves visible keyboard/controller focus on the selected card.
		if scene.has_method("_handle_button_action"): # Uses the controller's existing semantic button dispatcher when available.
			scene.call("_handle_button_action", StringName(button.name)) # Applies the selected mode without relying on a native pressed signal.
		return true # Reports that the click was consumed by the mode chooser.
	return false # Reports that the click did not land on a visible mode card.

func _try_activate_completion_at_mouse() -> bool: # Activates the staged next-level button even though workspace input consumes the same viewport click first.
	var scene: Node = get_tree().current_scene # Reads the active application scene.
	if scene == null or scene.name != "Bohr Builder": # Ignores startup frames and unrelated scenes.
		return false # Reports no completion activation.
	var button: Button = _resolve_button(scene, NEXT_LEVEL_OVERLAY_PATH, NEXT_LEVEL_ORIGINAL_PATH) # Resolves the next-level control before or after runtime reparenting.
	if button == null or not button.is_visible_in_tree() or button.disabled: # Requires the staged button to be visibly interactive.
		return false # Leaves unrelated clicks untouched.
	var mouse_position: Vector2 = scene.get_viewport().get_mouse_position() # Reads the same viewport-space pointer used for the displayed completion card.
	if not button.get_global_rect().has_point(mouse_position): # Rejects clicks outside the next-level button rectangle.
		return false # Leaves the click untouched when it belongs elsewhere.
	button.grab_focus() # Preserves keyboard/controller continuation after a mouse click.
	if scene.has_method("_handle_button_action"): # Uses the controller's existing semantic progression dispatcher.
		scene.call("_handle_button_action", StringName(button.name)) # Advances to the next unlocked campaign level without signals.
		return true # Reports that the completion click was consumed.
	return false # Reports no activation if the production controller dispatcher is unavailable.

func _resolve_button(scene: Node, preferred_path: NodePath, fallback_path: NodePath) -> Button: # Finds one overlay button before or after runtime reparenting.
	var button: Button = scene.get_node_or_null(preferred_path) as Button # Tries the current runtime location first.
	if button != null: # Accepts the preferred location when available.
		return button # Returns the resolved native button.
	return scene.get_node_or_null(fallback_path) as Button # Falls back to the original scene path during startup.
