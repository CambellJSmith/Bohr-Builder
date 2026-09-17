extends Node # Exercises the generated sound palette and centralized sound router through the normal project autoload lifecycle.

var _controller: BohrBuilderController = null # Retains the instantiated production controller while the audio smoke test runs.
var _effects: BohrSoundEffects = null # Retains the generated sound-effects autoload for direct runtime checks.
var _router: BohrSoundEffectRouter = null # Retains the state-observing sound router autoload for integration checks.

func _ready() -> void: # Instantiates the real native scene after project autoloads have been created normally.
	var packed_scene: PackedScene = load("res://godot/bohr_builder_native.tscn") as PackedScene # Loads the production native game scene.
	if packed_scene == null: # Rejects a missing or invalid main scene immediately.
		_fail("Could not load the native Bohr Builder scene for sound validation.") # Reports the setup failure.
		return # Stops before dereferencing an invalid scene.
	_controller = packed_scene.instantiate() as BohrBuilderController # Creates the real production controller and complete UI tree.
	if _controller == null: # Rejects an unexpected root type.
		_fail("Native main scene did not instantiate as BohrBuilderController for sound validation.") # Reports the root mismatch.
		return # Stops the smoke test.
	get_tree().root.add_child(_controller) # Adds the production game directly beneath the SceneTree root so it can become the active current scene.
	get_tree().current_scene = _controller # Makes the production game discoverable exactly as a normal launch does for observer autoloads.
	call_deferred("_run_test_after_ready") # Defers checks until controller @onready references and audio autoload startup have completed.

func _run_test_after_ready() -> void: # Verifies generated samples, polyphonic playback, and representative routed state transitions.
	_effects = get_node_or_null(^"/root/SoundEffects") as BohrSoundEffects # Resolves the centralized generated sound palette registered in project.godot.
	_router = get_node_or_null(^"/root/SoundEffectRouter") as BohrSoundEffectRouter # Resolves the centralized observation router registered in project.godot.
	if _effects == null: # Requires the sound palette autoload to exist at runtime.
		_fail("SoundEffects autoload is missing.") # Reports missing audio infrastructure.
		return # Stops before invoking generated sounds.
	if _router == null: # Requires the router autoload to exist at runtime.
		_fail("SoundEffectRouter autoload is missing.") # Reports missing sound routing infrastructure.
		return # Stops before state-observation checks.
	if _effects._player == null or _effects._playback == null: # Requires the polyphonic host to initialize even under the headless audio driver.
		_fail("Sound effects polyphonic playback host did not initialize.") # Reports an unusable runtime audio layer.
		return # Stops before attempting sample playback.
	if _effects._ui_press_stream == null or _effects._ui_press_stream.data.is_empty(): # Requires generated PCM data to exist for the ordinary interface click.
		_fail("Generated UI press sample is missing PCM data.") # Reports synthesis failure.
		return # Stops before broader palette checks.
	if _effects._fire_proton_stream == null or _effects._fire_neutron_stream == null or _effects._fire_electron_stream == null or _effects._ricochet_stream == null: # Requires the core gameplay sound palette to exist.
		_fail("Generated projectile sound palette is incomplete.") # Reports missing cannon or ricochet samples.
		return # Stops before invoking the palette.
	_effects.play_ui_press() # Exercises ordinary button playback through the shared polyphonic host.
	_effects.play_ui_focus() # Exercises focus-navigation playback through the shared polyphonic host.
	_effects.play_menu_open() # Exercises menu-open playback.
	_effects.play_menu_close() # Exercises menu-close playback.
	_effects.play_particle_selected(&"electron") # Exercises pitch-coded projectile-selection playback.
	_effects.play_particle_fire(&"proton") # Exercises proton cannon playback.
	_effects.play_particle_fire(&"neutron") # Exercises neutron cannon playback.
	_effects.play_particle_fire(&"electron") # Exercises electron cannon playback.
	_effects.play_ricochet(&"proton") # Exercises boundary-impact playback.
	_effects.play_capture(&"electron") # Exercises particle-capture playback.
	_effects.play_atom_created() # Exercises new-nucleus playback.
	_effects.play_toggle(true) # Exercises rising toggle playback.
	_effects.play_toggle(false) # Exercises falling toggle playback.
	_effects.play_inspect(true) # Exercises successful inspection playback.
	_effects.play_inspect(false) # Exercises empty inspection playback.
	_effects.play_scrap() # Exercises atom-removal playback.
	_effects.play_reset() # Exercises workspace-reset playback.
	_effects.play_level_change() # Exercises campaign-navigation playback.
	_effects.play_clear_selection() # Exercises freeplay-selection clear playback.
	_effects.play_error() # Exercises invalid-action playback.
	_effects.play_verify() # Exercises background-verification playback.
	await get_tree().process_frame # Allows the router to bind itself to the production controller after its normal startup path.
	await get_tree().process_frame # Allows one additional finalized frame so all state baselines are stable.
	if _router._root != _controller: # Requires the router to discover and retain the real production controller without signals.
		_fail("Sound effect router did not bind to the production controller.") # Reports broken centralized observation.
		return # Stops before state transition checks.
	_controller.state.selected_particle = &"neutron" # Simulates a successful loaded-particle change through authoritative game state.
	_router.call("_process", 0.0) # Runs one observation pass directly so the test remains deterministic.
	if _router._last_selected_particle != &"neutron": # Requires the router to consume the selected-particle transition.
		_fail("Sound effect router did not observe particle selection changes.") # Reports broken cannon-selection routing.
		return # Stops before successful-shot routing.
	_controller.state.last_shot_time_ms += 200.0 # Simulates the authoritative timestamp advance produced only by an accepted projectile launch.
	_router.call("_process", 0.0) # Runs one observation pass for successful-shot routing.
	if not is_equal_approx(_router._last_shot_time_ms, _controller.state.last_shot_time_ms): # Requires the router to consume the accepted-shot transition.
		_fail("Sound effect router did not observe successful projectile launches.") # Reports broken cannon-fire routing.
		return # Stops before atom-state routing.
	var atom: AtomState = AtomState.new(1, Vector2(300.0, 240.0)) # Creates one valid lightweight world atom for construction-feedback observation.
	_controller.state.atoms.append(atom) # Adds the atom through the same authoritative state array observed during gameplay.
	_router.call("_process", 0.0) # Runs one observation pass for new-nucleus routing.
	if not _router._last_atom_snapshots.has(atom.id): # Requires the router to establish a composition snapshot for the new atom.
		_fail("Sound effect router did not observe new nuclei.") # Reports broken construction routing.
		return # Stops before capture observation.
	atom.electrons += 1 # Simulates a successful electron capture into the existing atom.
	_router.call("_process", 0.0) # Runs one observation pass for capture routing.
	var composition: Vector3i = _router._last_atom_snapshots[atom.id] as Vector3i # Reads the router's finalized composition baseline.
	if composition.z != atom.electrons: # Requires the router to consume the electron-count increase.
		_fail("Sound effect router did not observe particle captures.") # Reports broken capture routing.
		return # Stops the smoke test.
	await get_tree().process_frame # Allows any queued audio/runtime work to execute under the headless driver.
	get_tree().quit(0) # Reports success after generated audio and representative routing paths execute without runtime errors.

func _fail(message: String) -> void: # Reports one deterministic sound-system regression and exits non-zero.
	push_error(message) # Writes the exact failed invariant to the Godot Actions log.
	get_tree().quit(1) # Fails the CI step immediately.
