class_name BohrModeClickRouter # Routes mode-selector mouse clicks independently of the workspace input handler.
extends Node # Polls the physical mouse state so consumed viewport input cannot suppress modal activation.

const MODE_OVERLAY_PATH: NodePath = ^"ModeOverlay" # Locates the modal overlay on the active Bohr Builder scene.
const GUIDED_BUTTON_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/Responsive Mode Grid/GuidedModeButton" # Locates the guided mode button after responsive reparenting.
const FORMULA_BUTTON_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/Responsive Mode Grid/FormulaModeButton" # Locates the formula-only mode button after responsive reparenting.
const FREEPLAY_BUTTON_PATH: NodePath = ^"ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/Responsive Mode Grid/FreeplayModeButton" # Locates the freeplay mode button after responsive reparenting.

var _left_was_down: bool = false # Remembers the previous physical mouse-button state so one click activates only once.

func _ready() -> void: # Enables per-frame modal click polling.
	set_process(true) # Keeps the router active while the native game scene is running.

func _process(_delta: float) -> void: # Detects a fresh physical left-click and routes it to a visible mode button.
	var left_is_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) # Reads the physical mouse state independently of consumed InputEvent routing.
	if left_is_down and not _left_was_down: # Reacts only to the rising edge of a new click.
		_try_activate_mode_at_mouse() # Checks whether the new click landed on one of the visible mode choices.
	_left_was_down = left_is_down # Stores the state for the next frame's edge detection.

func _try_activate_mode_at_mouse() -> void: # Activates the mode button directly under the current mouse position when the modal is visible.
	var scene: Node = get_tree().current_scene # Reads the active application scene.
	if scene == null or scene.name != "Bohr Builder": # Ignores startup frames and unrelated scenes.
		return # Leaves input untouched outside the native game scene.
	var overlay: Control = scene.get_node_or_null(MODE_OVERLAY_PATH) as Control # Resolves the current mode overlay.
	if overlay == null or not overlay.is_visible_in_tree(): # Requires the chooser to be visibly open.
		return # Prevents clicks from affecting hidden mode controls during gameplay.
	var mouse_position: Vector2 = scene.get_viewport().get_mouse_position() # Reads the current viewport-space pointer position.
	var button_paths: Array[NodePath] = [GUIDED_BUTTON_PATH, FORMULA_BUTTON_PATH, FREEPLAY_BUTTON_PATH] # Defines the three responsive mode-button locations in display order.
	for button_path: NodePath in button_paths: # Tests each mode card against the click position.
		var button: Button = scene.get_node_or_null(button_path) as Button # Resolves one live button after responsive reparenting.
		if button == null or not button.is_visible_in_tree() or button.disabled: # Skips unavailable controls safely.
			continue # Moves to the next mode choice.
		if not button.get_global_rect().has_point(mouse_position): # Rejects clicks outside this button's displayed rectangle.
			continue # Moves to the next mode choice.
		button.grab_focus() # Preserves visible keyboard/controller focus on the selected card.
		if scene.has_method("_handle_button_action"): # Uses the controller's existing semantic button dispatcher when available.
			scene.call("_handle_button_action", StringName(button.name)) # Applies the selected mode without relying on a native pressed signal.
		return # Stops after the single clicked mode has been activated.
