class_name SharedSettings # Owns the Oddity-wide settings file shared by the launcher and every compatible game.
extends RefCounted # Keeps shared settings storage independent from any one scene tree.

const SETTINGS_FOLDER_NAME: String = "OddityBox" # Names the common settings folder used by every Oddity application.
const SETTINGS_FILE_NAME: String = "settings.cfg" # Names the common ConfigFile document shared between applications.
const DEFAULT_WIDTH: int = 1280 # Defines the fallback window width.
const DEFAULT_HEIGHT: int = 720 # Defines the fallback window height.
const DEFAULT_DISPLAY_MODE: String = "windowed" # Defines the fallback display mode.
const DEFAULT_MONITOR: int = 0 # Defines the fallback monitor index.
const DEFAULT_VSYNC: bool = true # Defines the fallback vertical synchronization preference.
const DEFAULT_FRAME_LIMIT: int = 60 # Defines the fallback frame-rate cap.
const DEFAULT_RESOLUTION_SCALE: float = 1.0 # Defines the shared render-scale preference for games that support it.
const DEFAULT_BRIGHTNESS: float = 1.0 # Defines the shared brightness preference for games that support it.
const DEFAULT_VOLUME: float = 1.0 # Defines the fallback linear volume.
const DEFAULT_CONTROLLER_VIBRATION: bool = true # Defines whether compatible games should use controller vibration.
const DEFAULT_CONTROLLER_VIBRATION_STRENGTH: float = 1.0 # Defines the shared vibration strength multiplier.
const DEFAULT_CONTROLLER_DEADZONE: float = 0.2 # Defines the shared analogue deadzone preference.
const DEFAULT_SENSITIVITY: float = 1.0 # Defines shared mouse and controller sensitivity defaults.
const DEFAULT_INVERT_Y: bool = false # Defines the shared vertical-look inversion preference.
const DEFAULT_BUTTON_PROMPTS: String = "controller" # Defines the explicit prompt family used by compatible game UI without automatic device switching.
const DEFAULT_SUBTITLES: bool = true # Defines the shared speech subtitle preference.
const DEFAULT_SUBTITLE_SIZE: String = "medium" # Defines the shared subtitle size preference.
const DEFAULT_SOUND_CAPTIONS: bool = false # Defines the shared non-speech sound caption preference.
const DEFAULT_REDUCE_MOTION: bool = false # Defines the shared reduced-motion preference.
const DEFAULT_SCREEN_SHAKE: float = 1.0 # Defines the shared screen-shake intensity preference.
const DEFAULT_FLASH_REDUCTION: bool = false # Defines the shared flash-reduction preference.
const DEFAULT_LANGUAGE: String = "en" # Defines the shared locale code.
const DEFAULT_PAUSE_WHEN_UNFOCUSED: bool = true # Defines whether compatible games should pause when focus is lost.
const DEFAULT_MUTE_WHEN_UNFOCUSED: bool = false # Defines whether compatible games should mute when focus is lost.
const MINIMUM_RESOLUTION: Vector2i = Vector2i(640, 360) # Prevents malformed settings from creating an unusably small window.
const MUSIC_BUS_NAME: StringName = &"Music" # Names the standard music audio bus.
const EFFECTS_BUS_NAME: StringName = &"Effects" # Names the standard effects audio bus.
const SPEECH_BUS_NAME: StringName = &"Speech" # Names the standard speech audio bus.

func _init() -> void: # Keeps the class constructible while all behavior remains static.
	pass # Performs no instance initialization because shared settings are stateless helpers.

static func load_settings() -> Dictionary: # Loads and validates the complete shared settings document.
	var settings: Dictionary = get_default_settings() # Starts from a complete schema so missing keys migrate automatically.
	var settings_path: String = get_settings_path() # Resolves the shared file location.
	if not FileAccess.file_exists(settings_path): # Detects first run.
		save_settings(settings) # Creates the shared settings file immediately.
		return settings # Returns defaults used for first-run initialization.
	var config: ConfigFile = ConfigFile.new() # Creates the ConfigFile parser.
	if config.load(settings_path) != OK: # Rejects malformed or unreadable shared settings.
		push_warning("Oddity shared settings could not be loaded; defaults will be used.") # Records the storage failure.
		return settings # Falls back to safe defaults.
	settings["width"] = maxi(int(config.get_value("display", "width", DEFAULT_WIDTH)), MINIMUM_RESOLUTION.x) # Reads window width.
	settings["height"] = maxi(int(config.get_value("display", "height", DEFAULT_HEIGHT)), MINIMUM_RESOLUTION.y) # Reads window height.
	var legacy_fullscreen: bool = bool(config.get_value("display", "fullscreen", false)) # Reads the previous schema for automatic migration.
	settings["display_mode"] = _validated_display_mode(String(config.get_value("display", "display_mode", "fullscreen" if legacy_fullscreen else DEFAULT_DISPLAY_MODE))) # Reads or migrates display mode.
	settings["monitor"] = maxi(int(config.get_value("display", "monitor", DEFAULT_MONITOR)), 0) # Reads preferred monitor.
	settings["vsync"] = bool(config.get_value("display", "vsync", DEFAULT_VSYNC)) # Reads VSync preference.
	settings["frame_limit"] = maxi(int(config.get_value("display", "frame_limit", DEFAULT_FRAME_LIMIT)), 0) # Reads frame cap where zero means unlimited.
	settings["resolution_scale"] = clampf(float(config.get_value("display", "resolution_scale", DEFAULT_RESOLUTION_SCALE)), 0.5, 2.0) # Reads game render-scale preference.
	settings["brightness"] = clampf(float(config.get_value("display", "brightness", DEFAULT_BRIGHTNESS)), 0.5, 1.5) # Reads brightness preference.
	settings["master_volume"] = _read_volume(config, "master_volume") # Reads master volume.
	settings["music_volume"] = _read_volume(config, "music_volume") # Reads music volume.
	settings["effects_volume"] = _read_volume(config, "effects_volume") # Reads effects volume.
	settings["speech_volume"] = _read_volume(config, "speech_volume") # Reads speech volume.
	settings["mute_when_unfocused"] = bool(config.get_value("audio", "mute_when_unfocused", DEFAULT_MUTE_WHEN_UNFOCUSED)) # Reads background mute preference.
	settings["controller_vibration"] = bool(config.get_value("input", "controller_vibration", DEFAULT_CONTROLLER_VIBRATION)) # Reads vibration toggle.
	settings["controller_vibration_strength"] = clampf(float(config.get_value("input", "controller_vibration_strength", DEFAULT_CONTROLLER_VIBRATION_STRENGTH)), 0.0, 1.0) # Reads vibration intensity.
	settings["controller_deadzone"] = clampf(float(config.get_value("input", "controller_deadzone", DEFAULT_CONTROLLER_DEADZONE)), 0.0, 0.9) # Reads controller deadzone.
	settings["mouse_sensitivity"] = clampf(float(config.get_value("input", "mouse_sensitivity", DEFAULT_SENSITIVITY)), 0.1, 3.0) # Reads mouse sensitivity.
	settings["controller_sensitivity"] = clampf(float(config.get_value("input", "controller_sensitivity", DEFAULT_SENSITIVITY)), 0.1, 3.0) # Reads controller sensitivity.
	settings["invert_y"] = bool(config.get_value("input", "invert_y", DEFAULT_INVERT_Y)) # Reads vertical inversion.
	settings["button_prompts"] = _validated_button_prompts(String(config.get_value("input", "button_prompts", DEFAULT_BUTTON_PROMPTS))) # Reads the explicit controller or mouse-and-keyboard prompt preference.
	settings["subtitles"] = bool(config.get_value("accessibility", "subtitles", DEFAULT_SUBTITLES)) # Reads subtitle toggle.
	settings["subtitle_size"] = _validated_subtitle_size(String(config.get_value("accessibility", "subtitle_size", DEFAULT_SUBTITLE_SIZE))) # Reads subtitle size.
	settings["sound_captions"] = bool(config.get_value("accessibility", "sound_captions", DEFAULT_SOUND_CAPTIONS)) # Reads sound caption toggle.
	settings["reduce_motion"] = bool(config.get_value("accessibility", "reduce_motion", DEFAULT_REDUCE_MOTION)) # Reads reduced-motion preference.
	settings["screen_shake"] = clampf(float(config.get_value("accessibility", "screen_shake", DEFAULT_SCREEN_SHAKE)), 0.0, 1.0) # Reads screen-shake intensity.
	settings["flash_reduction"] = bool(config.get_value("accessibility", "flash_reduction", DEFAULT_FLASH_REDUCTION)) # Reads flash-reduction preference.
	settings["language"] = String(config.get_value("general", "language", DEFAULT_LANGUAGE)).strip_edges() # Reads locale code.
	if String(settings["language"]).is_empty(): # Rejects an empty locale.
		settings["language"] = DEFAULT_LANGUAGE # Restores the fallback locale.
	settings["pause_when_unfocused"] = bool(config.get_value("general", "pause_when_unfocused", DEFAULT_PAUSE_WHEN_UNFOCUSED)) # Reads background pause preference.
	save_settings(settings) # Rewrites the validated complete schema so older files migrate automatically.
	return settings # Returns the complete validated dictionary.

static func save_settings(settings: Dictionary) -> Error: # Writes the complete shared settings schema.
	var settings_directory: String = _get_settings_directory() # Resolves the shared directory.
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(settings_directory) # Ensures it exists.
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS: # Detects directory creation failure.
		return directory_error # Returns the filesystem error.
	var config: ConfigFile = ConfigFile.new() # Creates a clean configuration document.
	config.set_value("display", "width", maxi(int(settings.get("width", DEFAULT_WIDTH)), MINIMUM_RESOLUTION.x)) # Stores width.
	config.set_value("display", "height", maxi(int(settings.get("height", DEFAULT_HEIGHT)), MINIMUM_RESOLUTION.y)) # Stores height.
	config.set_value("display", "display_mode", _validated_display_mode(String(settings.get("display_mode", DEFAULT_DISPLAY_MODE)))) # Stores display mode.
	config.set_value("display", "monitor", maxi(int(settings.get("monitor", DEFAULT_MONITOR)), 0)) # Stores monitor.
	config.set_value("display", "vsync", bool(settings.get("vsync", DEFAULT_VSYNC))) # Stores VSync.
	config.set_value("display", "frame_limit", maxi(int(settings.get("frame_limit", DEFAULT_FRAME_LIMIT)), 0)) # Stores frame cap so the previous choice can return when VSync is disabled.
	config.set_value("display", "resolution_scale", clampf(float(settings.get("resolution_scale", DEFAULT_RESOLUTION_SCALE)), 0.5, 2.0)) # Stores render scale.
	config.set_value("display", "brightness", clampf(float(settings.get("brightness", DEFAULT_BRIGHTNESS)), 0.5, 1.5)) # Stores brightness.
	config.set_value("audio", "master_volume", _volume(settings, "master_volume")) # Stores master volume.
	config.set_value("audio", "music_volume", _volume(settings, "music_volume")) # Stores music volume.
	config.set_value("audio", "effects_volume", _volume(settings, "effects_volume")) # Stores effects volume.
	config.set_value("audio", "speech_volume", _volume(settings, "speech_volume")) # Stores speech volume.
	config.set_value("audio", "mute_when_unfocused", bool(settings.get("mute_when_unfocused", DEFAULT_MUTE_WHEN_UNFOCUSED))) # Stores background mute preference.
	config.set_value("input", "controller_vibration", bool(settings.get("controller_vibration", DEFAULT_CONTROLLER_VIBRATION))) # Stores vibration toggle.
	config.set_value("input", "controller_vibration_strength", clampf(float(settings.get("controller_vibration_strength", DEFAULT_CONTROLLER_VIBRATION_STRENGTH)), 0.0, 1.0)) # Stores vibration strength.
	config.set_value("input", "controller_deadzone", clampf(float(settings.get("controller_deadzone", DEFAULT_CONTROLLER_DEADZONE)), 0.0, 0.9)) # Stores controller deadzone.
	config.set_value("input", "mouse_sensitivity", clampf(float(settings.get("mouse_sensitivity", DEFAULT_SENSITIVITY)), 0.1, 3.0)) # Stores mouse sensitivity.
	config.set_value("input", "controller_sensitivity", clampf(float(settings.get("controller_sensitivity", DEFAULT_SENSITIVITY)), 0.1, 3.0)) # Stores controller sensitivity.
	config.set_value("input", "invert_y", bool(settings.get("invert_y", DEFAULT_INVERT_Y))) # Stores inversion preference.
	config.set_value("input", "button_prompts", _validated_button_prompts(String(settings.get("button_prompts", DEFAULT_BUTTON_PROMPTS)))) # Stores the explicit prompt family without any automatic input-device inference.
	config.set_value("accessibility", "subtitles", bool(settings.get("subtitles", DEFAULT_SUBTITLES))) # Stores subtitle toggle.
	config.set_value("accessibility", "subtitle_size", _validated_subtitle_size(String(settings.get("subtitle_size", DEFAULT_SUBTITLE_SIZE)))) # Stores subtitle size.
	config.set_value("accessibility", "sound_captions", bool(settings.get("sound_captions", DEFAULT_SOUND_CAPTIONS))) # Stores sound captions.
	config.set_value("accessibility", "reduce_motion", bool(settings.get("reduce_motion", DEFAULT_REDUCE_MOTION))) # Stores reduced motion.
	config.set_value("accessibility", "screen_shake", clampf(float(settings.get("screen_shake", DEFAULT_SCREEN_SHAKE)), 0.0, 1.0)) # Stores screen shake.
	config.set_value("accessibility", "flash_reduction", bool(settings.get("flash_reduction", DEFAULT_FLASH_REDUCTION))) # Stores flash reduction.
	config.set_value("general", "language", String(settings.get("language", DEFAULT_LANGUAGE)).strip_edges()) # Stores locale code.
	config.set_value("general", "pause_when_unfocused", bool(settings.get("pause_when_unfocused", DEFAULT_PAUSE_WHEN_UNFOCUSED))) # Stores background pause preference.
	return config.save(get_settings_path()) # Persists the complete document.

static func apply_settings(settings: Dictionary, window: Window) -> void: # Applies settings with direct engine-level runtime equivalents.
	apply_display_settings(settings, window) # Applies display mode, monitor, VSync, resolution, and FPS cap.
	apply_audio_settings(settings) # Applies standard Oddity audio buses.
	TranslationServer.set_locale(String(settings.get("language", DEFAULT_LANGUAGE))) # Applies the shared language to registered translations.

static func apply_display_settings(settings: Dictionary, window: Window) -> void: # Applies runtime display settings using current Godot APIs.
	if window == null: # Guards against calls before a root window exists.
		return # Leaves display state unchanged.
	var screen_count: int = maxi(DisplayServer.get_screen_count(), 1) # Reads available monitor count.
	window.current_screen = clampi(int(settings.get("monitor", DEFAULT_MONITOR)), 0, screen_count - 1) # Moves the window to the selected monitor.
	var vsync_enabled: bool = bool(settings.get("vsync", DEFAULT_VSYNC)) # Reads VSync once so frame-pacing behavior stays internally consistent.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED) # Applies VSync at runtime.
	Engine.max_fps = 0 if vsync_enabled else maxi(int(settings.get("frame_limit", DEFAULT_FRAME_LIMIT)), 0) # Lets VSync own frame pacing while enabled and restores the saved independent cap when disabled.
	var display_mode: String = _validated_display_mode(String(settings.get("display_mode", DEFAULT_DISPLAY_MODE))) # Reads validated display mode.
	window.borderless = false # Clears borderless state before selecting a mode.
	if display_mode == "fullscreen": # Handles normal fullscreen.
		window.mode = Window.MODE_FULLSCREEN # Uses Godot fullscreen mode.
		return # Resolution is controlled by the active display in fullscreen.
	window.mode = Window.MODE_WINDOWED # Uses desktop window mode for decorated and borderless options.
	window.borderless = display_mode == "borderless" # Removes decorations for borderless fullscreen-style presentation.
	if display_mode == "borderless": # Handles borderless mode.
		window.size = DisplayServer.screen_get_size(window.current_screen) # Fits the selected screen.
		window.position = DisplayServer.screen_get_position(window.current_screen) # Aligns to the selected screen origin.
		return # Skips normal window sizing.
	window.size = Vector2i(maxi(int(settings.get("width", DEFAULT_WIDTH)), MINIMUM_RESOLUTION.x), maxi(int(settings.get("height", DEFAULT_HEIGHT)), MINIMUM_RESOLUTION.y)) # Applies saved window resolution.
	window.move_to_center() # Centers the decorated window.

static func apply_audio_settings(settings: Dictionary) -> void: # Applies shared audio volumes to standard buses.
	_set_bus_volume(&"Master", float(settings.get("master_volume", DEFAULT_VOLUME))) # Applies master volume.
	_set_bus_volume(MUSIC_BUS_NAME, float(settings.get("music_volume", DEFAULT_VOLUME))) # Applies music volume.
	_set_bus_volume(EFFECTS_BUS_NAME, float(settings.get("effects_volume", DEFAULT_VOLUME))) # Applies effects volume.
	_set_bus_volume(SPEECH_BUS_NAME, float(settings.get("speech_volume", DEFAULT_VOLUME))) # Applies speech volume.

static func get_default_settings() -> Dictionary: # Builds a fresh complete settings dictionary.
	return {"width": DEFAULT_WIDTH, "height": DEFAULT_HEIGHT, "display_mode": DEFAULT_DISPLAY_MODE, "monitor": DEFAULT_MONITOR, "vsync": DEFAULT_VSYNC, "frame_limit": DEFAULT_FRAME_LIMIT, "resolution_scale": DEFAULT_RESOLUTION_SCALE, "brightness": DEFAULT_BRIGHTNESS, "master_volume": DEFAULT_VOLUME, "music_volume": DEFAULT_VOLUME, "effects_volume": DEFAULT_VOLUME, "speech_volume": DEFAULT_VOLUME, "mute_when_unfocused": DEFAULT_MUTE_WHEN_UNFOCUSED, "controller_vibration": DEFAULT_CONTROLLER_VIBRATION, "controller_vibration_strength": DEFAULT_CONTROLLER_VIBRATION_STRENGTH, "controller_deadzone": DEFAULT_CONTROLLER_DEADZONE, "mouse_sensitivity": DEFAULT_SENSITIVITY, "controller_sensitivity": DEFAULT_SENSITIVITY, "invert_y": DEFAULT_INVERT_Y, "button_prompts": DEFAULT_BUTTON_PROMPTS, "subtitles": DEFAULT_SUBTITLES, "subtitle_size": DEFAULT_SUBTITLE_SIZE, "sound_captions": DEFAULT_SOUND_CAPTIONS, "reduce_motion": DEFAULT_REDUCE_MOTION, "screen_shake": DEFAULT_SCREEN_SHAKE, "flash_reduction": DEFAULT_FLASH_REDUCTION, "language": DEFAULT_LANGUAGE, "pause_when_unfocused": DEFAULT_PAUSE_WHEN_UNFOCUSED} # Returns the complete schema.

static func get_settings_path() -> String: # Returns the absolute shared settings file path.
	return _get_settings_directory().path_join(SETTINGS_FILE_NAME) # Appends the common filename.

static func _read_volume(config: ConfigFile, key: String) -> float: # Reads one normalized volume from the audio section.
	return clampf(float(config.get_value("audio", key, DEFAULT_VOLUME)), 0.0, 1.0) # Returns a safe linear value.

static func _volume(settings: Dictionary, key: String) -> float: # Reads one normalized volume from a settings dictionary.
	return clampf(float(settings.get(key, DEFAULT_VOLUME)), 0.0, 1.0) # Returns a safe linear value.

static func _validated_display_mode(value: String) -> String: # Validates persisted display-mode strings.
	return value if value == "windowed" or value == "borderless" or value == "fullscreen" else DEFAULT_DISPLAY_MODE # Rejects unsupported values.

static func _validated_button_prompts(value: String) -> String: # Validates explicit prompt-style strings used across compatible games.
	return value if value == "controller" or value == "mouse_keyboard" else DEFAULT_BUTTON_PROMPTS # Rejects unsupported prompt modes and deliberately provides no automatic mode.

static func _validated_subtitle_size(value: String) -> String: # Validates persisted subtitle-size strings.
	return value if value == "small" or value == "medium" or value == "large" else DEFAULT_SUBTITLE_SIZE # Rejects unsupported values.

static func _get_settings_directory() -> String: # Resolves one common per-user Oddity folder outside project-specific user directories.
	var home_directory: String = OS.get_environment("HOME") # Reads the user's home folder.
	if OS.get_name() == "Windows": # Uses Windows roaming application data.
		var app_data: String = OS.get_environment("APPDATA") # Reads the roaming application-data directory.
		if not app_data.is_empty(): # Prefers the OS-provided roaming path.
			return app_data.path_join(SETTINGS_FOLDER_NAME) # Returns the common Windows location.
		var user_profile: String = OS.get_environment("USERPROFILE") # Reads the user profile fallback.
		if not user_profile.is_empty(): # Uses the profile when available.
			return user_profile.path_join("AppData").path_join("Roaming").path_join(SETTINGS_FOLDER_NAME) # Reconstructs the roaming path.
	if OS.get_name() == "macOS" and not home_directory.is_empty(): # Uses macOS Application Support.
		return home_directory.path_join("Library").path_join("Application Support").path_join(SETTINGS_FOLDER_NAME) # Returns the common macOS location.
	var xdg_config_home: String = OS.get_environment("XDG_CONFIG_HOME") # Reads Linux XDG configuration root.
	if not xdg_config_home.is_empty(): # Prefers a configured XDG root.
		return xdg_config_home.path_join(SETTINGS_FOLDER_NAME) # Returns the XDG location.
	if not home_directory.is_empty(): # Falls back to the conventional Linux config folder.
		return home_directory.path_join(".config").path_join(SETTINGS_FOLDER_NAME) # Returns the Linux fallback location.
	return ProjectSettings.globalize_path("user://").path_join(SETTINGS_FOLDER_NAME) # Uses a final platform fallback.

static func _set_bus_volume(bus_name: StringName, volume: float) -> void: # Applies one linear volume value when the bus exists.
	var bus_index: int = AudioServer.get_bus_index(bus_name) # Looks up the requested bus.
	if bus_index < 0: # Detects missing optional category buses.
		return # Leaves routing untouched.
	AudioServer.set_bus_volume_linear(bus_index, clampf(volume, 0.0, 1.0)) # Applies the normalized linear volume.
