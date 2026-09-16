extends Control # Hosts the existing Bohr Builder web application inside the Godot window.

const BROWSER_CLASS_NAME: StringName = &"CefTexture" # Identifies the Godot CEF browser node without creating a hard parser dependency.
const BOHR_BUILDER_URL: String = "res://index.html" # Points the embedded browser at the existing application entry point.

@onready var dependency_panel: Control = $DependencyPanel # Displays setup instructions when the native browser addon is unavailable.

var _browser: Control = null # Holds the runtime-created embedded browser control.

func _ready() -> void: # Creates the embedded Chromium surface when the native addon is available.
	if not ClassDB.class_exists(BROWSER_CLASS_NAME): # Keeps the project runnable even before the external CEF dependency is installed.
		dependency_panel.visible = true # Shows the dependency instructions in the Godot window.
		push_warning("Godot CEF is not installed. Install the addon into res://addons/godot_cef and restart Godot.") # Reports the missing native dependency in the debugger.
		return # Stops before attempting to instantiate a class that is not registered.
	_browser = ClassDB.instantiate(BROWSER_CLASS_NAME) as Control # Creates the CEF-backed TextureRect dynamically after confirming the class exists.
	if _browser == null: # Guards against a native extension that registered incorrectly.
		dependency_panel.visible = true # Keeps the setup information visible when browser creation fails.
		push_error("Godot CEF registered CefTexture but the browser control could not be created.") # Reports the extension initialization problem.
		return # Stops before configuring an invalid browser instance.
	_configure_browser() # Applies browser settings before the node enters the scene tree.
	add_child(_browser) # Adds the browser to Godot so CEF can initialize and begin rendering.
	_browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # Makes the browser fill the complete Godot window.
	dependency_panel.visible = false # Removes the dependency instructions once the embedded browser is active.

func _configure_browser() -> void: # Configures the embedded browser while preserving the current HTML implementation unchanged.
	_browser.name = "Bohr Builder Browser" # Gives the runtime node a readable scene-tree name.
	_browser.mouse_filter = Control.MOUSE_FILTER_STOP # Ensures mouse input is delivered to the embedded webpage.
	_browser.focus_mode = Control.FOCUS_ALL # Allows keyboard input to remain inside the embedded webpage.
	_browser.set("enable_accelerated_osr", true) # Requests GPU-backed browser rendering when the current platform supports it.
	_browser.set("background_color", Color(0.09, 0.10, 0.11, 1.0)) # Matches the existing page background while the first frame initializes.
	_browser.set("url", BOHR_BUILDER_URL) # Loads the repository HTML directly through Godot CEF's res protocol.
