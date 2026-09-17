extends Node # Keeps Steam integration available globally through the autoload.

const STEAM_APP_ID: int = 4281680 # Identifies the Bohr Builder base game to Steamworks.
const DLC_APP_ID: int = 5290570 # Identifies the Bohr Builder DLC for entitlement checks.

var is_initialized: bool = false # Tracks whether Steamworks initialized successfully.
var is_online: bool = false # Tracks whether the current Steam user is logged on.
var owns_game: bool = false # Tracks whether Steam reports ownership of the base game.
var steam_id: int = 0 # Stores the current Steam user's account identifier.
var dlc_installed: bool = false # Caches the latest DLC installation state.
var initialization_status: int = -1 # Stores the latest Steam initialization result code.
var initialization_message: String = "Not initialized." # Stores the latest Steam initialization diagnostic text.


func _ready() -> void: # Initializes Steam as soon as the autoload enters the scene tree.
	process_mode = Node.PROCESS_MODE_ALWAYS # Keeps Steam callbacks running while the scene tree is paused.
	_initialize_steam() # Starts the Steamworks connection and initial account-state query.


func _process(_delta: float) -> void: # Pumps Steamworks callbacks while Steam is active.
	if not is_initialized: # Avoids calling Steamworks when initialization was unavailable or failed.
		return # Leaves the frame without unnecessary Steam API work.
	Steam.run_callbacks() # Dispatches pending Steamworks callbacks on the main thread.


func _exit_tree() -> void: # Releases Steamworks cleanly when the autoload is removed at shutdown.
	if not is_initialized: # Avoids shutting down an API instance that never initialized.
		return # Leaves shutdown handling when there is no active Steam session.
	Steam.steamShutdown() # Releases the Steamworks API connection and callback resources.
	is_initialized = false # Prevents further Steam API access after shutdown.


func _initialize_steam() -> void: # Initializes Steamworks with Bohr Builder's base-game App ID.
	if not OS.has_feature("editor") and Steam.restartAppIfNecessary(STEAM_APP_ID): # Relaunches exported builds through Steam when required by Steamworks.
		get_tree().quit() # Stops the directly launched process after Steam schedules the correct launch.
		return # Prevents initialization from continuing in the process that is closing.

	var init_result: Dictionary = Steam.steamInitEx(STEAM_APP_ID, false) # Requests detailed initialization results while callbacks remain manually pumped.
	initialization_status = int(init_result.get("status", -1)) # Records the numeric Steam initialization result.
	initialization_message = String(init_result.get("verbal", "Unknown Steam initialization result.")) # Records Steam's diagnostic description.

	if initialization_status != 0: # Keeps the game usable when Steam is unavailable during development or CI.
		push_warning("Steam initialization unavailable: %s" % initialization_message) # Reports the Steam failure without terminating Bohr Builder.
		return # Leaves Steam-dependent state disabled until the next application launch.

	is_initialized = true # Marks Steamworks as safe for subsequent API calls.
	refresh_account_state() # Populates the current user, ownership, and DLC state immediately.


func refresh_account_state() -> void: # Refreshes Steam account and entitlement data from the active client.
	if not is_initialized: # Prevents account queries before Steamworks is ready.
		return # Leaves cached state unchanged when Steam is unavailable.
	is_online = Steam.loggedOn() # Reads whether the current Steam user is connected.
	steam_id = Steam.getSteamID() # Reads the current Steam user's account identifier.
	owns_game = Steam.isSubscribed() # Reads whether Steam reports the base game as owned.
	dlc_installed = Steam.isDLCInstalled(DLC_APP_ID) # Reads whether the configured DLC is both owned and installed.


func has_dlc() -> bool: # Returns a current entitlement-and-installation check for the configured DLC.
	if not is_initialized: # Treats unavailable Steamworks as unavailable DLC content.
		return false # Prevents DLC access without a successful Steam entitlement query.
	dlc_installed = Steam.isDLCInstalled(DLC_APP_ID) # Refreshes the cached DLC state at the point gameplay requests it.
	return dlc_installed # Returns the current Steam DLC installation state.


func is_steam_available() -> bool: # Provides a stable public query for Steam-dependent systems.
	return is_initialized # Returns whether Steamworks initialized successfully for this session.
