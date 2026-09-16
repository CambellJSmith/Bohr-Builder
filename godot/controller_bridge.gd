class_name BohrControllerBridge
extends Node

const STICK_LEFT_NORTH: StringName = &"StickLeft_North" # Moves the in-game aim upward through the left stick.
const STICK_LEFT_SOUTH: StringName = &"StickLeft_South" # Moves the in-game aim downward through the left stick.
const STICK_LEFT_WEST: StringName = &"StickLeft_West" # Moves the in-game aim left through the left stick.
const STICK_LEFT_EAST: StringName = &"StickLeft_East" # Moves the in-game aim right through the left stick.
const DPAD_NORTH: StringName = &"DPad_North" # Navigates the embedded interface upward.
const DPAD_SOUTH: StringName = &"DPad_South" # Navigates the embedded interface downward.
const DPAD_WEST: StringName = &"DPad_West" # Navigates the embedded interface left.
const DPAD_EAST: StringName = &"DPad_East" # Navigates the embedded interface right.
const BUTTON_A: StringName = &"Button_A" # Activates the focused control or performs the primary canvas action.
const BUTTON_B: StringName = &"Button_B" # Inspects the atom under the current aim point.
const BUTTON_X: StringName = &"Button_X" # Toggles scrap mode.
const BUTTON_Y: StringName = &"Button_Y" # Toggles freeplay reactant-selection mode.
const BUTTON_START: StringName = &"Button_Start" # Opens the game-mode chooser.
const BUTTON_BACK: StringName = &"Button_Back" # Resets the active level or workspace.
const BUTTON_LB: StringName = &"Button_LB" # Cycles to the previous particle type.
const BUTTON_RB: StringName = &"Button_RB" # Cycles to the next particle type.
const BUTTON_LT: StringName = &"Button_LT" # Moves to the previous unlocked campaign level.
const BUTTON_RT: StringName = &"Button_RT" # Moves to the next unlocked campaign level.
const BUTTON_L3: StringName = &"Button_L3" # Clears the current freeplay reactant selection.
const BUTTON_R3: StringName = &"Button_R3" # Reacts selected freeplay species or advances a completed campaign level.

var _browser: Control = null # Stores the embedded Chromium control that receives controller commands.

func _ready() -> void: # Keeps controller polling disabled until the browser host supplies a valid browser instance.
	set_process(false) # Avoids polling input before the embedded page can receive it.

func configure(browser: Control) -> void: # Connects this input component to the embedded browser.
	_browser = browser # Retains the browser instance used for JavaScript input forwarding.
	set_process(true) # Begins controller polling after the browser is ready.

func _process(delta: float) -> void: # Polls analog input and forwards controller actions into the embedded page each frame.
	if _browser == null or not is_instance_valid(_browser): # Stops cleanly when the browser instance no longer exists.
		set_process(false) # Prevents repeated work after the browser has been destroyed.
		return # Exits without attempting to call the extension.
	var aim_vector: Vector2 = Input.get_vector(STICK_LEFT_WEST, STICK_LEFT_EAST, STICK_LEFT_NORTH, STICK_LEFT_SOUTH, 0.20) # Reads the left stick as a normalized two-dimensional aim vector.
	if aim_vector.length_squared() > 0.0001: # Sends analog aim updates only while the stick is meaningfully displaced.
		_eval_web("window.bohr_controller_move_aim?.(%f,%f,%f);" % [aim_vector.x, aim_vector.y, delta]) # Moves the browser-side game aim using Godot's controller sampling.
	_forward_navigation(DPAD_NORTH, "up") # Forwards one upward interface-navigation press.
	_forward_navigation(DPAD_SOUTH, "down") # Forwards one downward interface-navigation press.
	_forward_navigation(DPAD_WEST, "left") # Forwards one left interface-navigation press.
	_forward_navigation(DPAD_EAST, "right") # Forwards one right interface-navigation press.
	_forward_button(BUTTON_A, "accept") # Forwards primary action press and release state.
	_forward_button(BUTTON_B, "inspect") # Forwards inspection input.
	_forward_button(BUTTON_X, "scrap") # Forwards scrap-mode input.
	_forward_button(BUTTON_Y, "react_select") # Forwards freeplay selection input.
	_forward_button(BUTTON_START, "mode") # Forwards mode-menu input.
	_forward_button(BUTTON_BACK, "reset") # Forwards reset input.
	_forward_button(BUTTON_LB, "particle_previous") # Forwards previous-particle input.
	_forward_button(BUTTON_RB, "particle_next") # Forwards next-particle input.
	_forward_button(BUTTON_LT, "level_previous") # Forwards previous-level input.
	_forward_button(BUTTON_RT, "level_next") # Forwards next-level input.
	_forward_button(BUTTON_L3, "clear") # Forwards clear-reactants input.
	_forward_button(BUTTON_R3, "context") # Forwards react-or-next contextual input.

func _forward_navigation(action_name: StringName, direction: String) -> void: # Sends one D-pad navigation event on each distinct press.
	if Input.is_action_just_pressed(action_name): # Prevents continuous focus movement from a held digital direction.
		_eval_web("window.bohr_controller_navigate?.('%s');" % direction) # Invokes spatial focus navigation inside the webpage.

func _forward_button(action_name: StringName, web_action: String) -> void: # Sends controller button edges so held primary fire can be represented accurately.
	if Input.is_action_just_pressed(action_name): # Detects the start of the physical button press.
		_eval_web("window.bohr_controller_action?.('%s',true);" % web_action) # Sends the pressed state into the webpage.
	if Input.is_action_just_released(action_name): # Detects the end of the physical button press.
		_eval_web("window.bohr_controller_action?.('%s',false);" % web_action) # Sends the released state into the webpage.

func _eval_web(script: String) -> void: # Executes a small semantic input command inside the embedded Chromium page.
	if _browser == null or not is_instance_valid(_browser) or not _browser.has_method("eval"): # Validates the native browser interface before calling it.
		return # Ignores input safely while the native browser is unavailable.
	_browser.call("eval", script) # Uses Godot CEF's JavaScript evaluator without hard-typing the external extension class.
