class_name OdditySettingsService # Integrates the shared Oddity settings contract with Bohr Builder's application-level systems.
extends Node # Lives as an autoload so shared settings are applied before the main game scene starts.

const MASTER_BUS: StringName = &"Master" # Names Godot's standard master audio bus.
const MUSIC_BUS: StringName = &"Music" # Names the standard Oddity music bus.
const EFFECTS_BUS: StringName = &"Effects" # Names the standard Oddity effects bus.
const SPEECH_BUS: StringName = &"Speech" # Names the standard Oddity speech bus.
const STICK_LEFT_NORTH: StringName = &"StickLeft_North" # Names the standard upward left-stick action.
const STICK_LEFT_SOUTH: StringName = &"StickLeft_South" # Names the standard downward left-stick action.
const STICK_LEFT_WEST: StringName = &"StickLeft_West" # Names the standard leftward left-stick action.
const STICK_LEFT_EAST: StringName = &"StickLeft_East" # Names the standard rightward left-stick action.
const BUTTON_A: StringName = &"Button_A" # Names the standard positive interaction action.
const BUTTON_B: StringName = &"Button_B" # Names the standard negative interaction action.
const BUTTON_START: StringName = &"Button_Start" # Names the standard pause or system-menu action.
const BUTTON_BACK: StringName = &"Button_Back" # Names the legacy Bohr Builder action whose old physical binding is removed at runtime.
const BUTTON_INSPECT: StringName = &"Button_Inspect" # Names Bohr Builder's non-standard atom-inspection action.
const CONTROLLER_BACK_BUTTON_INDEX: int = 4 # Uses the controller Back/View button for the game-specific inspect action.
const BRIGHTNESS_CANVAS_LAYER: int = 127 # Places the brightness pass above ordinary scene canvas items.
const BRIGHTNESS_SHADER_CODE: String = "shader_type canvas_item;\nuniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;\nuniform float brightness = 1.0;\nvoid fragment() {\n\tvec4 source = texture(screen_texture, SCREEN_UV);\n\tCOLOR = vec4(source.rgb * brightness, source.a);\n}\n" # Defines one lightweight full-screen brightness multiplication pass.

var settings: Dictionary = {} # Retains the validated shared Oddity settings dictionary for game-specific consumers.
var _paused_by_focus: bool = false # Tracks whether focus loss, rather than the player, caused the SceneTree pause.
var _muted_by_focus: bool = false # Tracks whether this service temporarily muted the Master bus.
var _master_mute_before_focus: bool = false # Preserves the Master bus mute state that existed before focus was lost.
var _brightness_layer: CanvasLayer = null # Holds the full-screen brightness post-process above the ordinary UI canvas.
var _brightness_rect: ColorRect = null # Draws the full-screen screen-reading brightness material.
var _brightness_material: ShaderMaterial = null # Owns the brightness shader parameter applied from shared settings.

func _ready() -> void: # Establishes shared buses, input semantics, shared storage, and live runtime settings before gameplay begins.
	process_mode = Node.PROCESS_MODE_ALWAYS # Keeps focus notifications active while focus-loss pausing has paused the SceneTree.
	_ensure_standard_audio_buses() # Creates the optional Oddity category buses before volume settings are applied.
	_configure_standard_input_map() # Adds canonical keyboard equivalents and game-specific inspect routing before the main scene receives input.
	_reload_settings() # Loads the common OddityBox settings file and applies every supported runtime preference.

func reload_settings() -> void: # Reloads external shared-setting changes and reapplies every supported live consumer.
	_reload_settings() # Uses the same validated startup path so runtime reload behavior cannot diverge.

func controller_deadzone() -> float: # Returns the validated shared analogue deadzone used by Bohr Builder's aiming code.
	return clampf(float(settings.get("controller_deadzone", SharedSettings.DEFAULT_CONTROLLER_DEADZONE)), 0.0, 0.9) # Keeps malformed runtime dictionaries inside the manifest range.

func controller_sensitivity() -> float: # Returns the validated shared controller sensitivity multiplier.
	return clampf(float(settings.get("controller_sensitivity", SharedSettings.DEFAULT_SENSITIVITY)), 0.1, 3.0) # Scales authored controller aim speed without changing keyboard speed.

func button_prompt_mode() -> String: # Returns the explicit prompt family without automatic device inference.
	var prompt_mode: String = String(settings.get("button_prompts", SharedSettings.DEFAULT_BUTTON_PROMPTS)) # Reads the currently loaded shared preference.
	return prompt_mode if prompt_mode == "controller" or prompt_mode == "mouse_keyboard" else SharedSettings.DEFAULT_BUTTON_PROMPTS # Enforces the two allowed manifest values.

func reduce_motion_enabled() -> bool: # Reports whether non-essential reaction movement should be suppressed.
	return bool(settings.get("reduce_motion", SharedSettings.DEFAULT_REDUCE_MOTION)) # Returns the validated reduced-motion preference.

func flash_reduction_enabled() -> bool: # Reports whether large sudden completion flashes should be suppressed.
	return bool(settings.get("flash_reduction", SharedSettings.DEFAULT_FLASH_REDUCTION)) # Returns the validated flash-reduction preference.

func screen_shake_scale() -> float: # Exposes the shared shake multiplier for any future centralized shake consumer.
	return clampf(float(settings.get("screen_shake", SharedSettings.DEFAULT_SCREEN_SHAKE)), 0.0, 1.0) # Preserves the manifest's normalized shake range.

func start_controller_vibration(device: int, weak_magnitude: float, strong_magnitude: float, duration: float = 0.0) -> void: # Applies the shared vibration permission and strength to one requested controller rumble.
	if not bool(settings.get("controller_vibration", SharedSettings.DEFAULT_CONTROLLER_VIBRATION)): # Rejects rumble when the shared master permission is disabled.
		Input.stop_joy_vibration(device) # Stops any existing vibration on the requested controller immediately.
		return # Leaves vibration disabled without starting a new effect.
	var strength: float = clampf(float(settings.get("controller_vibration_strength", SharedSettings.DEFAULT_CONTROLLER_VIBRATION_STRENGTH)), 0.0, 1.0) # Reads the shared rumble multiplier once.
	var weak: float = clampf(weak_magnitude * strength, 0.0, 1.0) # Scales and clamps the authored weak-motor amplitude.
	var strong: float = clampf(strong_magnitude * strength, 0.0, 1.0) # Scales and clamps the authored strong-motor amplitude.
	Input.start_joy_vibration(device, weak, strong, maxf(duration, 0.0)) # Starts the manifest-compliant vibration request through Godot's input API.

func _notification(what: int) -> void: # Applies focus mute and pause rules without changing any persisted volume or manual pause state.
	if settings.is_empty(): # Ignores lifecycle notifications that occur before startup settings have loaded.
		return # Leaves startup state untouched until the service is ready.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: # Detects the application losing desktop focus.
		_apply_focus_loss() # Applies only the focus-dependent preferences enabled in shared settings.
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN: # Detects the application regaining desktop focus.
		_apply_focus_gain() # Restores only state that this service changed because of focus loss.

func _reload_settings() -> void: # Loads the canonical document and refreshes all Bohr Builder consumers that are meaningful at runtime.
	settings = SharedSettings.load_settings() # Reads and validates the common OddityBox settings file shared with the launcher.
	SharedSettings.apply_settings(settings, get_window()) # Applies monitor, window mode, resolution, VSync, frame cap, category volume, and locale.
	_apply_input_settings() # Pushes the shared analogue deadzone into the standard semantic actions.
	_apply_brightness() # Refreshes the active full-screen brightness pass immediately.

func _ensure_standard_audio_buses() -> void: # Creates the standard optional Oddity category buses and routes each one into Master.
	_ensure_audio_bus(MUSIC_BUS) # Makes the Music bus available even though Bohr Builder currently has no music playback.
	_ensure_audio_bus(EFFECTS_BUS) # Creates the bus used by all current Bohr Builder generated effects.
	_ensure_audio_bus(SPEECH_BUS) # Makes the Speech bus available for schema compatibility even though the game has no voiced dialogue.

func _ensure_audio_bus(bus_name: StringName) -> void: # Creates one named category bus only when the active bus layout does not already provide it.
	if AudioServer.get_bus_index(bus_name) >= 0: # Preserves existing project or platform bus configuration.
		return # Avoids duplicate buses and leaves existing routing untouched.
	AudioServer.add_bus() # Appends one new category bus to the active layout.
	var bus_index: int = AudioServer.bus_count - 1 # Resolves the index of the newly appended bus.
	AudioServer.set_bus_name(bus_index, String(bus_name)) # Gives the new bus its canonical Oddity name.
	AudioServer.set_bus_send(bus_index, MASTER_BUS) # Routes the category bus into Godot's standard Master bus.

func _configure_standard_input_map() -> void: # Applies Oddity semantic action bindings before gameplay input starts.
	_ensure_action(STICK_LEFT_NORTH, SharedSettings.DEFAULT_CONTROLLER_DEADZONE) # Ensures the canonical upward left-stick action exists.
	_ensure_action(STICK_LEFT_SOUTH, SharedSettings.DEFAULT_CONTROLLER_DEADZONE) # Ensures the canonical downward left-stick action exists.
	_ensure_action(STICK_LEFT_WEST, SharedSettings.DEFAULT_CONTROLLER_DEADZONE) # Ensures the canonical leftward left-stick action exists.
	_ensure_action(STICK_LEFT_EAST, SharedSettings.DEFAULT_CONTROLLER_DEADZONE) # Ensures the canonical rightward left-stick action exists.
	_ensure_key_binding(STICK_LEFT_NORTH, KEY_W) # Maps W to the canonical upward left-stick action.
	_ensure_key_binding(STICK_LEFT_SOUTH, KEY_S) # Maps S to the canonical downward left-stick action.
	_ensure_key_binding(STICK_LEFT_WEST, KEY_A) # Maps A to the canonical leftward left-stick action.
	_ensure_key_binding(STICK_LEFT_EAST, KEY_D) # Maps D to the canonical rightward left-stick action.
	_ensure_action(BUTTON_A, 0.5) # Ensures the canonical positive action exists.
	_ensure_key_binding(BUTTON_A, KEY_ENTER) # Maps Enter to the standard positive interaction.
	_ensure_key_binding(BUTTON_A, KEY_SPACE) # Maps Space to the standard primary interaction used by the workspace.
	_ensure_action(BUTTON_B, 0.5) # Ensures the canonical negative action exists.
	_ensure_key_binding(BUTTON_B, KEY_ESCAPE) # Maps Escape to the standard negative or back interaction.
	_ensure_action(BUTTON_START, 0.5) # Ensures the standard system-menu action exists.
	_ensure_key_binding(BUTTON_START, KEY_M) # Retains M as the keyboard equivalent for Bohr Builder's mode/system menu.
	_ensure_action(BUTTON_INSPECT, 0.5) # Creates the game-specific inspect action without overloading the standard negative button.
	_ensure_key_binding(BUTTON_INSPECT, KEY_I) # Retains I as the keyboard atom-inspection shortcut through a semantic action.
	_ensure_joy_button_binding(BUTTON_INSPECT, CONTROLLER_BACK_BUTTON_INDEX) # Moves controller Back/View to the explicit inspect action.
	if InputMap.has_action(BUTTON_BACK): # Detects the legacy physical Back/View action from the existing project Input Map.
		InputMap.action_erase_events(BUTTON_BACK) # Removes its reset binding so Back/View cannot compete with the new inspect action.

func _ensure_action(action: StringName, deadzone: float) -> void: # Creates one semantic action when the project does not already define it.
	if not InputMap.has_action(action): # Detects a missing action safely.
		InputMap.add_action(action, deadzone) # Creates the action with its intended initial deadzone.

func _ensure_key_binding(action: StringName, keycode: Key) -> void: # Adds one keyboard equivalent only when the action does not already contain it.
	var event: InputEventKey = InputEventKey.new() # Allocates a physical keyboard input event for the semantic action.
	event.keycode = keycode # Uses the named keyboard key required by the Oddity input contract.
	if not InputMap.action_has_event(action, event): # Avoids duplicate bindings when a future project file already contains the same key.
		InputMap.action_add_event(action, event) # Adds the keyboard event to the semantic action.

func _ensure_joy_button_binding(action: StringName, button_index: int) -> void: # Adds one controller button event to a semantic game action.
	var event: InputEventJoypadButton = InputEventJoypadButton.new() # Allocates a standard joypad-button input event.
	event.button_index = button_index # Assigns the requested controller button index.
	if not InputMap.action_has_event(action, event): # Avoids duplicating an existing project binding.
		InputMap.action_add_event(action, event) # Adds the controller event to the semantic action.

func _apply_input_settings() -> void: # Pushes validated shared analogue preferences into the canonical movement actions.
	var deadzone: float = controller_deadzone() # Reads one consistent shared deadzone for all four left-stick directions.
	InputMap.action_set_deadzone(STICK_LEFT_NORTH, deadzone) # Applies the shared deadzone to upward analogue intent.
	InputMap.action_set_deadzone(STICK_LEFT_SOUTH, deadzone) # Applies the shared deadzone to downward analogue intent.
	InputMap.action_set_deadzone(STICK_LEFT_WEST, deadzone) # Applies the shared deadzone to leftward analogue intent.
	InputMap.action_set_deadzone(STICK_LEFT_EAST, deadzone) # Applies the shared deadzone to rightward analogue intent.

func _apply_brightness() -> void: # Applies the shared brightness value through one full-screen canvas post-process.
	_ensure_brightness_filter() # Lazily creates the single rendering pass used by all brightness values.
	if _brightness_material == null: # Protects unusual headless or teardown states where the filter could not be created.
		return # Leaves rendering untouched when no valid material exists.
	var brightness: float = clampf(float(settings.get("brightness", SharedSettings.DEFAULT_BRIGHTNESS)), 0.5, 1.5) # Reads the validated shared brightness multiplier.
	_brightness_material.set_shader_parameter(&"brightness", brightness) # Applies the value immediately without stacking multiple brightness effects.

func _ensure_brightness_filter() -> void: # Creates the reusable screen-reading brightness layer exactly once.
	if _brightness_layer != null and is_instance_valid(_brightness_layer): # Reuses the existing post-process after the first settings application.
		return # Avoids reallocating a full-screen shader or Control.
	_brightness_layer = CanvasLayer.new() # Creates an application-level canvas layer above the ordinary scene UI.
	_brightness_layer.name = "Oddity Brightness Layer" # Gives the runtime integration node a readable scene-tree name.
	_brightness_layer.layer = BRIGHTNESS_CANVAS_LAYER # Draws the filter after ordinary Bohr Builder canvas items.
	add_child(_brightness_layer) # Adds the layer before its full-rect child is configured.
	_brightness_rect = ColorRect.new() # Creates one screen-sized draw item for the brightness pass.
	_brightness_rect.name = "Oddity Brightness Filter" # Gives the runtime post-process a readable scene-tree name.
	_brightness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Guarantees the visual filter never intercepts game or UI input.
	_brightness_rect.color = Color.WHITE # Supplies an opaque draw primitive while the shader replaces its final pixels.
	_brightness_layer.add_child(_brightness_rect) # Parents the filter to the dedicated top canvas layer.
	_brightness_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # Keeps the post-process fitted to the active root window at every resolution.
	var shader: Shader = Shader.new() # Allocates the compact screen-reading canvas shader.
	shader.code = BRIGHTNESS_SHADER_CODE # Assigns the single-pass brightness multiplication implementation.
	_brightness_material = ShaderMaterial.new() # Creates the material instance whose brightness parameter can change live.
	_brightness_material.shader = shader # Binds the screen-reading shader to the reusable material.
	_brightness_rect.material = _brightness_material # Applies the material to the full-screen filter Control.

func _apply_focus_loss() -> void: # Temporarily mutes and pauses only when the corresponding shared preferences request it.
	if bool(settings.get("mute_when_unfocused", SharedSettings.DEFAULT_MUTE_WHEN_UNFOCUSED)): # Checks the shared background-mute preference.
		var master_index: int = AudioServer.get_bus_index(MASTER_BUS) # Resolves the Master bus without modifying any saved volume.
		if master_index >= 0 and not _muted_by_focus: # Applies focus mute once while preserving the prior mute state.
			_master_mute_before_focus = AudioServer.is_bus_mute(master_index) # Remembers whether another system had already muted Master.
			AudioServer.set_bus_mute(master_index, true) # Temporarily mutes output without changing shared volume values.
			_muted_by_focus = true # Marks Master as changed by this focus-loss handler.
	if bool(settings.get("pause_when_unfocused", SharedSettings.DEFAULT_PAUSE_WHEN_UNFOCUSED)) and not get_tree().paused: # Pauses only when the game was not already manually paused.
		_paused_by_focus = true # Records that focus loss owns this pause transition.
		get_tree().paused = true # Suspends gameplay until focus returns.

func _apply_focus_gain() -> void: # Restores only mute and pause state that focus loss itself changed.
	if _muted_by_focus: # Detects a temporary Master mute owned by this service.
		var master_index: int = AudioServer.get_bus_index(MASTER_BUS) # Resolves the Master bus for restoration.
		if master_index >= 0: # Restores the previous mute state only when the bus still exists.
			AudioServer.set_bus_mute(master_index, _master_mute_before_focus) # Preserves any pre-existing manual or system mute state.
		_muted_by_focus = false # Clears focus-mute ownership after restoration.
	if _paused_by_focus: # Detects a SceneTree pause caused specifically by focus loss.
		get_tree().paused = false # Resumes gameplay because focus loss, not the player, caused this pause.
		_paused_by_focus = false # Clears focus-pause ownership so later manual pauses are never undone.
