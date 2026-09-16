extends Node # Runs the existing Bohr Builder web app from Godot without changing its behavior.

const WEB_OUTPUT_DIRECTORY: String = "user://bohr_builder_web" # Stores browser-readable copies outside the packed Godot project.
const WEB_FILES: PackedStringArray = [ # Lists every file required by the existing browser version.
	"index.html", # Provides the application markup.
	"styles.css", # Provides the application styling.
	"js/dom.js", # Provides DOM references and shared constants.
	"js/chemistry-data.js", # Provides element and chemistry data.
	"js/chemistry-utils.js", # Provides chemistry helper functions.
	"js/campaign.js", # Provides campaign generation and validation.
	"js/reaction-library.js", # Provides freeplay reaction lookup.
	"js/state-ui.js", # Provides mode and interface state.
	"js/physics.js", # Provides particle and atom simulation.
	"js/campaign-reaction.js", # Provides automatic campaign reactions.
	"js/freeplay.js", # Provides freeplay behavior.
	"js/inspector.js", # Provides atom inspection behavior.
	"js/render.js", # Provides canvas rendering.
	"js/input.js", # Provides browser input handling.
] # Ends the required web file list.

func _ready() -> void: # Prepares the web files, opens Bohr Builder, then closes the launcher.
	if not _copy_web_app(): # Stops immediately when the browser files cannot be prepared.
		push_error("Bohr Builder could not copy its web files into user storage.") # Reports a clear launcher failure.
		return # Keeps the launcher open so the error remains visible in the debugger.
	var index_path: String = ProjectSettings.globalize_path(WEB_OUTPUT_DIRECTORY.path_join("index.html")) # Converts the Godot path into a native operating-system path.
	var open_error: Error = OS.shell_open(index_path) # Opens the unchanged HTML application in the default browser.
	if open_error != OK: # Detects operating-system launch failures.
		push_error("Bohr Builder could not open the browser. Error: %s" % error_string(open_error)) # Reports the operating-system error.
		return # Keeps the launcher alive when the browser could not be opened.
	get_tree().quit() # Exits the temporary Godot launcher after the browser opens successfully.

func _copy_web_app() -> bool: # Copies the source web app from res:// into a normal filesystem directory that browsers can read.
	var output_directory_absolute: String = ProjectSettings.globalize_path(WEB_OUTPUT_DIRECTORY) # Resolves the output directory into a native path.
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(output_directory_absolute) # Creates the output directory and any missing parents.
	if directory_error != OK: # Detects failures creating the output directory.
		push_error("Could not create Bohr Builder web directory. Error: %s" % error_string(directory_error)) # Reports the directory creation problem.
		return false # Prevents launching an incomplete copy of the app.
	for relative_path: String in WEB_FILES: # Copies every browser asset required by the existing application.
		var source_path: String = "res://".path_join(relative_path) # Builds the path to the repository source file.
		if not FileAccess.file_exists(source_path): # Verifies the source file exists before attempting to copy it.
			push_error("Missing Bohr Builder web file: %s" % source_path) # Reports the exact missing source file.
			return false # Stops before creating a broken browser copy.
		var destination_path: String = WEB_OUTPUT_DIRECTORY.path_join(relative_path) # Builds the writable destination path.
		var destination_directory_absolute: String = ProjectSettings.globalize_path(destination_path.get_base_dir()) # Resolves the destination folder into a native path.
		var nested_directory_error: Error = DirAccess.make_dir_recursive_absolute(destination_directory_absolute) # Creates nested folders such as the JavaScript directory.
		if nested_directory_error != OK: # Detects failures creating a nested destination folder.
			push_error("Could not create web asset directory. Error: %s" % error_string(nested_directory_error)) # Reports the nested directory failure.
			return false # Prevents an incomplete copy from launching.
		var source_bytes: PackedByteArray = FileAccess.get_file_as_bytes(source_path) # Reads the source exactly as stored so HTML, CSS, and JavaScript remain unchanged.
		if FileAccess.get_open_error() != OK: # Detects source read failures even when an empty byte array is valid.
			push_error("Could not read Bohr Builder web file: %s" % source_path) # Reports the source file that failed to read.
			return false # Stops before writing incomplete data.
		var destination_file: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE) # Opens the writable browser copy destination.
		if destination_file == null: # Detects destination file creation failures.
			push_error("Could not write Bohr Builder web file: %s" % destination_path) # Reports the exact destination that failed.
			return false # Stops before launching a partial app.
		destination_file.store_buffer(source_bytes) # Writes the source bytes without transforming the original web application.
		destination_file.close() # Flushes and closes the destination file immediately.
	return true # Confirms the complete browser app is ready to launch.
