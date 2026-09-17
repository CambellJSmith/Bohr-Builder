class_name BohrSoundEffects # Owns the lightweight generated sound palette used across native UI and gameplay actions.
extends Node # Lives as an autoload so controller and systems can play sounds directly without signals.

const MIX_RATE: int = 22050 # Uses a compact sample rate that remains clear for short interface and gameplay effects.
const POLYPHONY: int = 32 # Allows rapid shots, ricochets, captures, and UI sounds to overlap without cutting each other off.

var _player: AudioStreamPlayer = null # Owns the single non-positional playback node used for the complete sound-effects mix.
var _playback: AudioStreamPlaybackPolyphonic = null # Provides simultaneous stream playback through the shared player.
var _ui_press_stream: AudioStreamWAV = null # Stores the soft confirmation chirp used by native buttons.
var _ui_focus_stream: AudioStreamWAV = null # Stores the quieter navigation tick used when focus moves.
var _menu_open_stream: AudioStreamWAV = null # Stores the rising menu-open chime.
var _menu_close_stream: AudioStreamWAV = null # Stores the compact confirming menu-close chime.
var _fire_proton_stream: AudioStreamWAV = null # Stores the warm proton-launch pulse.
var _fire_neutron_stream: AudioStreamWAV = null # Stores the heavier neutron-launch pulse.
var _fire_electron_stream: AudioStreamWAV = null # Stores the brighter electron-launch zap.
var _ricochet_stream: AudioStreamWAV = null # Stores the metallic wall-impact ping.
var _capture_stream: AudioStreamWAV = null # Stores the ascending particle-capture tone.
var _atom_created_stream: AudioStreamWAV = null # Stores the small harmonic bloom used when a new nucleus is seeded.
var _toggle_on_stream: AudioStreamWAV = null # Stores the rising toggle/selection cue.
var _toggle_off_stream: AudioStreamWAV = null # Stores the falling toggle/deselection cue.
var _inspect_stream: AudioStreamWAV = null # Stores the restrained atom-inspection tick.
var _scrap_stream: AudioStreamWAV = null # Stores the short descending atom-removal sound.
var _reset_stream: AudioStreamWAV = null # Stores the soft reset/clear sweep.
var _level_stream: AudioStreamWAV = null # Stores the positive level-navigation chime.
var _error_stream: AudioStreamWAV = null # Stores the muted rejection buzz used for invalid actions.
var _verify_stream: AudioStreamWAV = null # Stores the small pulse used when online compound verification begins.

func _ready() -> void: # Builds every reusable generated sample and starts the polyphonic playback host.
	_build_palette() # Generates the complete sound palette once instead of synthesizing during gameplay.
	var polyphonic_stream: AudioStreamPolyphonic = AudioStreamPolyphonic.new() # Creates one stream capable of mixing arbitrary short effects concurrently.
	polyphonic_stream.polyphony = POLYPHONY # Reserves enough simultaneous voices for rapid physics and interface activity.
	_player = AudioStreamPlayer.new() # Creates the non-positional player recommended for interface and global game sounds.
	_player.name = "Sound Effects Player" # Gives the runtime audio node a readable scene-tree name.
	_player.stream = polyphonic_stream # Assigns the polyphonic host stream before playback is started.
	_player.volume_db = -1.5 # Leaves a little headroom beneath the existing reaction presentation sounds.
	add_child(_player) # Adds the player to the active SceneTree before requesting its playback instance.
	_player.play() # Starts the polyphonic host so individual generated streams can be triggered at any time.
	_playback = _player.get_stream_playback() as AudioStreamPlaybackPolyphonic # Captures the typed polyphonic playback interface used by every public sound method.

func play_ui_press() -> void: # Plays a compact confirmation for ordinary native button activation.
	_play(_ui_press_stream, -9.0, 1.0) # Keeps routine clicks audible but subordinate to gameplay effects.

func play_ui_focus() -> void: # Plays a very quiet tick when keyboard or controller focus moves to another control.
	_play(_ui_focus_stream, -15.0, 1.0) # Uses a low level so repeated navigation remains pleasant.

func play_menu_open() -> void: # Plays the rising cue used when the mode chooser appears.
	_play(_menu_open_stream, -8.0, 1.0) # Gives modal arrival a clear but restrained identity.

func play_menu_close() -> void: # Plays the confirming cue used when a mode choice closes the modal.
	_play(_menu_close_stream, -9.0, 1.0) # Keeps mode confirmation shorter than the opening cue.

func play_particle_selected(kind: StringName) -> void: # Plays a pitch-coded cue when the loaded subatomic particle changes.
	var pitch: float = 1.0 # Starts from the neutral proton selection pitch.
	if kind == &"neutron": # Gives the heavier neutral particle a lower selection tone.
		pitch = 0.84 # Lowers the shared selection cue without allocating another sample.
	elif kind == &"electron": # Gives the lightweight electron a brighter selection tone.
		pitch = 1.28 # Raises the shared selection cue for immediate auditory distinction.
	_play(_ui_focus_stream, -10.0, pitch) # Reuses the soft navigation timbre with particle-specific pitch.

func play_particle_fire(kind: StringName) -> void: # Plays the dedicated launch sound for the projectile that actually entered the simulation.
	if kind == &"electron": # Uses the brighter electrical launch sound for electrons.
		_play(_fire_electron_stream, -7.0, 1.0) # Keeps rapid electron firing crisp without becoming harsh.
	elif kind == &"neutron": # Uses the deepest launch sound for neutrons.
		_play(_fire_neutron_stream, -6.5, 1.0) # Gives neutron shots a little extra physical weight.
	else: # Uses the warm mid-low launch sound for protons and safe fallbacks.
		_play(_fire_proton_stream, -6.5, 1.0) # Gives proton shots a distinct but related cannon character.

func play_ricochet(kind: StringName) -> void: # Plays one metallic impact when a projectile rebounds from a wall or hard particle limit.
	var pitch: float = 1.0 # Starts from the proton impact pitch.
	if kind == &"neutron": # Lowers impacts for the heavier neutron.
		pitch = 0.88 # Makes neutron ricochets sound slightly larger.
	elif kind == &"electron": # Raises impacts for the lightweight electron.
		pitch = 1.22 # Makes electron ricochets read as smaller and faster.
	_play(_ricochet_stream, -10.0, pitch) # Keeps repeated boundary contacts below launch and capture volume.

func play_capture(kind: StringName) -> void: # Plays an ascending confirmation when a projectile is absorbed by an atom.
	var pitch: float = 1.0 # Starts from the proton capture pitch.
	if kind == &"neutron": # Gives neutron capture a slightly warmer lower confirmation.
		pitch = 0.92 # Lowers the shared capture sample subtly.
	elif kind == &"electron": # Gives electron shell capture a brighter confirmation.
		pitch = 1.24 # Raises the shared capture sample to match electron identity.
	_play(_capture_stream, -7.0, pitch) # Makes successful construction feedback clearer than ordinary UI ticks.

func play_atom_created() -> void: # Plays a small harmonic bloom when an uncaptured proton seeds a new nucleus.
	_play(_atom_created_stream, -6.0, 1.0) # Gives nucleus creation a distinct positive construction reward.

func play_toggle(enabled: bool) -> void: # Plays rising or falling feedback for modes and manual reactant selection.
	_play(_toggle_on_stream if enabled else _toggle_off_stream, -10.0, 1.0) # Mirrors the boolean state change with matching pitch direction.

func play_inspect(found: bool) -> void: # Plays a readable inspection tick or a muted miss when no atom is under the aim point.
	if found: # Confirms that a real atom was selected for inspection.
		_play(_inspect_stream, -11.0, 1.0) # Keeps inspection feedback subtle because it may be used frequently.
	else: # Reports an empty inspection target without a harsh failure sound.
		_play(_error_stream, -16.0, 1.18) # Uses a quiet short rejection cue for empty space.

func play_scrap() -> void: # Plays the compact descending sound used when an atom is removed.
	_play(_scrap_stream, -7.5, 1.0) # Gives destructive feedback enough presence to distinguish it from toggling scrap mode.

func play_reset() -> void: # Plays a soft clearing sweep when the player explicitly resets the current workspace.
	_play(_reset_stream, -8.5, 1.0) # Keeps reset feedback broad but unobtrusive.

func play_level_change() -> void: # Plays a positive navigation chime when campaign progression moves to another level.
	_play(_level_stream, -7.0, 1.0) # Distinguishes substantial campaign navigation from ordinary button presses.

func play_clear_selection() -> void: # Plays a soft falling cue when the freeplay reactant set is cleared.
	_play(_toggle_off_stream, -11.0, 0.9) # Reuses the deselection timbre at a slightly lower pitch.

func play_error() -> void: # Plays a short muted rejection sound for invalid or unavailable actions.
	_play(_error_stream, -10.0, 1.0) # Makes failure audible without sounding punitive.

func play_verify() -> void: # Plays a light pulse when a freeplay formula begins external verification.
	_play(_verify_stream, -11.0, 1.0) # Indicates background validation without competing with reaction audio.

func _play(stream: AudioStreamWAV, volume_db: float, pitch_scale: float) -> void: # Starts one generated sample through the shared polyphonic player.
	if _playback == null or stream == null: # Tolerates startup, shutdown, and headless timing where playback is unavailable.
		return # Leaves gameplay completely independent from audio availability.
	_playback.play_stream(stream, 0.0, volume_db, pitch_scale) # Starts the short sample immediately while preserving simultaneous voices.

func _build_palette() -> void: # Generates all short samples using deterministic PCM synthesis.
	_ui_press_stream = _build_sweep(610.0, 920.0, 0.070, 0.22, 0.16, 0.0) # Builds a soft upward button chirp.
	_ui_focus_stream = _build_sweep(920.0, 1120.0, 0.045, 0.15, 0.10, 0.0) # Builds a tiny bright navigation tick.
	_menu_open_stream = _build_chime(PackedFloat32Array([392.0, 523.25, 659.25]), 0.210, 0.13, 0.040) # Builds a gentle rising modal-open arpeggio.
	_menu_close_stream = _build_chime(PackedFloat32Array([659.25, 523.25]), 0.140, 0.12, 0.032) # Builds a compact descending mode-confirmation chime.
	_fire_proton_stream = _build_sweep(235.0, 120.0, 0.120, 0.34, 0.30, 0.045) # Builds the proton cannon's warm energetic pulse.
	_fire_neutron_stream = _build_sweep(165.0, 82.0, 0.135, 0.36, 0.36, 0.065) # Builds the neutron cannon's heavier low pulse.
	_fire_electron_stream = _build_sweep(1320.0, 430.0, 0.095, 0.25, 0.20, 0.025) # Builds the electron cannon's quick bright zap.
	_ricochet_stream = _build_sweep(1480.0, 620.0, 0.085, 0.20, 0.54, 0.035) # Builds a short metallic falling impact ping.
	_capture_stream = _build_sweep(480.0, 960.0, 0.125, 0.24, 0.18, 0.0) # Builds a clear ascending construction confirmation.
	_atom_created_stream = _build_chime(PackedFloat32Array([261.63, 392.0, 523.25]), 0.230, 0.14, 0.025) # Builds a warm harmonic bloom for new nuclei.
	_toggle_on_stream = _build_sweep(520.0, 790.0, 0.085, 0.18, 0.12, 0.0) # Builds a small rising mode-on cue.
	_toggle_off_stream = _build_sweep(720.0, 430.0, 0.085, 0.16, 0.12, 0.0) # Builds a small falling mode-off cue.
	_inspect_stream = _build_sweep(760.0, 910.0, 0.060, 0.14, 0.18, 0.0) # Builds a restrained glassy inspection tick.
	_scrap_stream = _build_sweep(390.0, 105.0, 0.125, 0.28, 0.28, 0.16) # Builds a short descending textured removal sound.
	_reset_stream = _build_sweep(560.0, 145.0, 0.180, 0.19, 0.10, 0.075) # Builds a soft wide clearing sweep.
	_level_stream = _build_chime(PackedFloat32Array([440.0, 554.37, 659.25]), 0.220, 0.14, 0.036) # Builds a positive campaign-navigation chime.
	_error_stream = _build_sweep(190.0, 145.0, 0.105, 0.22, 0.42, 0.035) # Builds a muted low rejection buzz.
	_verify_stream = _build_sweep(430.0, 650.0, 0.110, 0.14, 0.15, 0.0) # Builds a light verification-start pulse.

func _build_sweep(start_frequency: float, end_frequency: float, duration: float, amplitude: float, harmonic_mix: float, noise_mix: float) -> AudioStreamWAV: # Synthesizes one smoothly swept, softly enveloped mono effect.
	var sample_count: int = maxi(1, int(duration * float(MIX_RATE))) # Calculates the exact number of PCM samples for the requested duration.
	var pcm: PackedByteArray = PackedByteArray() # Stores little-endian signed sixteen-bit mono samples.
	pcm.resize(sample_count * 2) # Reserves two bytes for each generated sample.
	for sample_index: int in sample_count: # Generates every sample deterministically once during startup.
		var time: float = float(sample_index) / float(MIX_RATE) # Converts the sample index into elapsed seconds.
		var progress: float = clampf(time / duration, 0.0, 1.0) # Normalizes the effect timeline for frequency and envelope shaping.
		var phase_cycles: float = start_frequency * time + 0.5 * (end_frequency - start_frequency) * time * time / duration # Integrates the linear frequency sweep into a continuous phase.
		var phase: float = TAU * phase_cycles # Converts integrated cycles into radians for sine synthesis.
		var attack: float = clampf(time / 0.008, 0.0, 1.0) # Applies a fast click-free attack to every generated sample.
		var release: float = pow(1.0 - progress, 2.15) # Gives short effects a smooth natural decay rather than an abrupt cutoff.
		var envelope: float = attack * release # Combines attack and release into the final amplitude contour.
		var value: float = sin(phase) * amplitude # Generates the fundamental tone at the requested level.
		value += sin(phase * 2.01) * amplitude * harmonic_mix # Adds a slightly detuned second harmonic for a softer game-like timbre.
		if noise_mix > 0.0: # Adds deterministic texture only to effects that benefit from physical impact or motion.
			var noise_seed: float = sin(float(sample_index) * 12.9898 + 78.233) * 43758.5453 # Produces a stable pseudo-random floating-point sequence without global RNG state.
			var noise_value: float = (noise_seed - floor(noise_seed)) * 2.0 - 1.0 # Converts the deterministic sequence into a centered minus-one-to-one sample.
			value += noise_value * amplitude * noise_mix # Mixes the requested amount of textured noise into the tonal effect.
		_write_pcm16_sample(pcm, sample_index, value * envelope) # Encodes the enveloped mixed sample into the PCM byte buffer.
	return _stream_from_pcm(pcm) # Wraps the finished raw sample data in a reusable native audio resource.

func _build_chime(frequencies: PackedFloat32Array, duration: float, amplitude: float, stagger: float) -> AudioStreamWAV: # Synthesizes a small staggered sine chime for menus and campaign navigation.
	var sample_count: int = maxi(1, int(duration * float(MIX_RATE))) # Calculates the exact number of samples for the requested chime duration.
	var pcm: PackedByteArray = PackedByteArray() # Stores little-endian signed sixteen-bit mono samples.
	pcm.resize(sample_count * 2) # Reserves two bytes for every generated chime sample.
	for sample_index: int in sample_count: # Generates the complete chime once during startup.
		var time: float = float(sample_index) / float(MIX_RATE) # Converts sample index into seconds.
		var mixed: float = 0.0 # Accumulates all staggered note voices for the current sample.
		for voice_index: int in frequencies.size(): # Mixes each requested chime note independently.
			var voice_start: float = float(voice_index) * stagger # Delays successive voices to create a light arpeggiated movement.
			if time < voice_start: # Leaves the current voice silent until its entry point.
				continue # Moves directly to the next possible chime voice.
			var voice_time: float = time - voice_start # Measures elapsed time since this note began.
			var voice_duration: float = maxf(0.001, duration - voice_start) # Protects the envelope denominator for the final staggered voice.
			var progress: float = clampf(voice_time / voice_duration, 0.0, 1.0) # Normalizes the active note timeline.
			var attack: float = clampf(voice_time / 0.010, 0.0, 1.0) # Smooths the note onset to avoid digital clicks.
			var envelope: float = attack * pow(1.0 - progress, 2.0) # Gives every note a clean bell-like decay.
			var phase: float = TAU * float(frequencies[voice_index]) * voice_time # Calculates the current fundamental phase for this voice.
			mixed += sin(phase) * amplitude * envelope # Adds the voice fundamental to the current output sample.
			mixed += sin(phase * 2.0) * amplitude * 0.10 * envelope # Adds a quiet octave harmonic for clarity on small speakers.
		_write_pcm16_sample(pcm, sample_index, mixed) # Encodes the complete chime mix into the PCM byte buffer.
	return _stream_from_pcm(pcm) # Wraps the generated chime data in a reusable native audio resource.

func _write_pcm16_sample(buffer: PackedByteArray, sample_index: int, value: float) -> void: # Encodes one normalized floating-point sample as little-endian signed sixteen-bit PCM.
	var clamped_value: float = clampf(value, -1.0, 1.0) # Prevents synthesis peaks from overflowing the PCM representation.
	var signed_sample: int = int(round(clamped_value * 32767.0)) # Converts normalized amplitude into a signed sixteen-bit integer.
	var unsigned_sample: int = signed_sample & 0xffff # Preserves the two's-complement representation used for negative samples.
	buffer[sample_index * 2] = unsigned_sample & 0xff # Writes the low byte first for little-endian PCM.
	buffer[sample_index * 2 + 1] = (unsigned_sample >> 8) & 0xff # Writes the high byte second for little-endian PCM.

func _stream_from_pcm(pcm: PackedByteArray) -> AudioStreamWAV: # Wraps generated raw mono PCM bytes in an AudioStreamWAV resource.
	var stream: AudioStreamWAV = AudioStreamWAV.new() # Allocates the reusable native audio stream.
	stream.format = AudioStreamWAV.FORMAT_16_BITS # Declares signed sixteen-bit PCM data.
	stream.mix_rate = MIX_RATE # Uses the same compact sample rate used during synthesis.
	stream.stereo = false # Keeps global short effects mono and inexpensive.
	stream.data = pcm # Assigns the generated raw PCM bytes to the playable stream.
	return stream # Returns the fully configured generated sound resource.
