class_name BohrSoundEffectRouter # Observes native gameplay, UI, and physics state and routes interaction events into the centralized sound palette.
extends Node # Lives as an autoload so sound coverage stays separate from chemistry, physics, and controller implementation.

const UI_PRESS_FOCUS_SUPPRESSION_MS: int = 90 # Prevents a mouse or accept-button press from immediately layering an extra focus-navigation tick.
const RESET_DUPLICATE_SUPPRESSION_MS: int = 140 # Prevents state observation from replaying reset feedback immediately after an explicit reset input.
const WALL_CONTACT_MARGIN: float = 2.0 # Allows a small numerical tolerance when identifying a projectile velocity reversal at a workspace boundary.

var _root: BohrBuilderController = null # References the ready production controller while the native game scene is active.
var _last_mode_prompt_open: bool = false # Tracks mode-overlay visibility for menu open and close sounds.
var _last_game_mode: StringName = &"" # Tracks Guided, Formula Only, and Freeplay transitions for state-reset suppression.
var _last_level_index: int = -1 # Tracks campaign navigation so successful level changes receive a dedicated chime.
var _last_selected_particle: StringName = &"" # Tracks the loaded cannon particle for selection feedback.
var _last_scrap_mode: bool = false # Tracks scrap-mode toggles and distinguishes intentional atom removal from other world cleanup.
var _last_freeplay_select_mode: bool = false # Tracks freeplay reactant-selection mode toggles.
var _last_freeplay_selected_ids: Dictionary = {} # Tracks the current manual reactant set without requiring gameplay signals.
var _last_shot_time_ms: float = -1.0 # Tracks successful projectile launches using the authoritative fire-rate timestamp.
var _last_focus_id: int = 0 # Tracks the native focus owner so keyboard and controller navigation can receive a quiet tick.
var _last_status_text: String = "" # Tracks status changes so validation and rejection outcomes can receive semantic feedback.
var _last_atom_snapshots: Dictionary = {} # Stores proton, neutron, and electron totals by atom identifier for creation, capture, and scrap detection.
var _particle_velocities: Dictionary = {} # Stores prior projectile velocity by Object instance identifier for boundary-ricochet detection.
var _last_ui_press_ms: int = -1000 # Stores the latest ordinary UI activation time for focus-sound suppression.
var _last_reset_sound_ms: int = -1000 # Stores the latest explicit reset feedback time for duplicate cleanup suppression.

func _ready() -> void: # Configures the observer to run after the main controller and presentation layers have updated their state for each frame.
	process_priority = 320 # Runs after ordinary gameplay and existing presentation autoloads so observations see finalized frame state.
	set_process(true) # Enables continuous state observation for sounds that do not originate from direct input events.
	set_process_input(true) # Enables direct UI, reset, and inspection feedback without connecting signals.

func _process(_delta: float) -> void: # Binds the active game and translates finalized state changes into lightweight sound events.
	var scene: Node = get_tree().current_scene # Reads the active native scene without assuming the game is always loaded.
	if scene == null or not scene.is_node_ready() or not scene is BohrBuilderController: # Ignores startup, shutdown, tests without the production scene, and unrelated scenes.
		_unbind_scene() # Clears stale observation baselines when the native controller is no longer active.
		return # Stops until a ready Bohr Builder scene is available.
	var controller: BohrBuilderController = scene as BohrBuilderController # Narrows the ready production scene to its strongly typed controller.
	if _root == null or not is_instance_valid(_root) or _root != controller: # Detects first binding or replacement of the production scene.
		_bind_scene(controller) # Seeds every observation baseline without fabricating gameplay events.
		return # Defers change detection until the next finalized frame.
	var mode_changed: bool = _root.state.game_mode != _last_game_mode # Captures mode transition state before updating any baselines.
	var level_changed: bool = _root.state.current_level_index != _last_level_index # Captures campaign navigation state before updating any baselines.
	var menu_changed: bool = _root.state.mode_prompt_open != _last_mode_prompt_open # Captures modal visibility change before focus observation.
	_observe_menu_state() # Plays mode chooser open or close feedback.
	_observe_campaign_and_particle_state() # Plays level-navigation and cannon-particle selection sounds.
	var suppress_cleanup_feedback: bool = mode_changed or level_changed or _reset_was_recent() # Suppresses toggle/scrap artifacts caused by deliberate whole-world transitions.
	_observe_toggle_state(suppress_cleanup_feedback) # Plays scrap-mode and freeplay-selection-mode state cues.
	_observe_freeplay_selection(suppress_cleanup_feedback) # Plays reactant add, remove, and clear feedback.
	_observe_successful_shot() # Plays the particle-specific cannon sound only when a shot was actually accepted.
	_observe_atom_changes(suppress_cleanup_feedback) # Plays nucleus creation, particle capture, and atom scrap feedback.
	_observe_particle_ricochets() # Plays metallic boundary pings for live projectile bounces.
	_observe_status_feedback() # Plays verification and rejection sounds for semantic outcomes exposed through native status text.
	_observe_focus_change(menu_changed) # Plays quiet keyboard/controller navigation feedback while avoiding menu and click layering.
	_last_game_mode = _root.state.game_mode # Stores the current mode baseline for the next finalized frame.
	_last_level_index = _root.state.current_level_index # Stores the current campaign level baseline for the next finalized frame.
	_last_mode_prompt_open = _root.state.mode_prompt_open # Stores current modal visibility for the next finalized frame.

func _input(event: InputEvent) -> void: # Adds immediate feedback for UI activation, reset shortcuts, and explicit atom-inspection actions.
	if _root == null or not is_instance_valid(_root): # Ignores input before the production controller has been bound.
		return # Leaves startup input silent rather than guessing at semantic targets.
	if event is InputEventMouseButton: # Handles mouse UI activation, reset controls, and right-click inspection.
		_handle_mouse_input(event as InputEventMouseButton) # Routes the narrowed mouse event through sound-only semantics.
		return # Stops sound routing after mouse handling.
	if event is InputEventKey: # Handles keyboard button activation, reset, and inspection shortcuts.
		_handle_key_input(event as InputEventKey) # Routes the narrowed keyboard event through sound-only semantics.
		return # Stops sound routing after keyboard handling.
	_handle_controller_input(event) # Handles named controller actions for activation, reset, and inspection feedback.

func _bind_scene(controller: BohrBuilderController) -> void: # Captures the production controller and seeds observation baselines from its current state.
	_root = controller # Retains the live production controller for state, UI, and workspace access.
	_last_mode_prompt_open = _root.state.mode_prompt_open # Seeds modal state without creating a false transition.
	_last_game_mode = _root.state.game_mode # Seeds active mode without creating a false transition.
	_last_level_index = _root.state.current_level_index # Seeds campaign position without creating a false level-change chime.
	_last_selected_particle = _root.state.selected_particle # Seeds loaded projectile selection without creating a false selection sound.
	_last_scrap_mode = _root.state.scrap_mode # Seeds scrap-mode state without creating a false toggle sound.
	_last_freeplay_select_mode = _root.state.freeplay_select_mode # Seeds freeplay selection-mode state without creating a false toggle sound.
	_last_freeplay_selected_ids = _root.state.freeplay_selected_ids.duplicate() # Seeds the current reactant set for later add/remove comparison.
	_last_shot_time_ms = _root.state.last_shot_time_ms # Seeds the authoritative fire timestamp so existing state does not sound like a new shot.
	_last_status_text = _root.status_label.text # Seeds visible status text so startup guidance does not trigger validation sounds.
	_last_atom_snapshots = _build_atom_snapshots() # Seeds atom composition baselines so existing atoms do not sound newly created.
	_particle_velocities = _build_particle_velocity_map() # Seeds projectile velocities so existing motion does not fabricate a ricochet.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads any native focus already assigned during scene startup.
	_last_focus_id = focus_owner.get_instance_id() if focus_owner != null else 0 # Seeds focus identity without producing a startup navigation tick.
	if _root.state.mode_prompt_open: # Gives the initial mode chooser the same audible arrival as later menu openings.
		SoundEffects.play_menu_open() # Plays one restrained rising menu chime at application entry.

func _unbind_scene() -> void: # Clears scene-specific observation state when the production game is absent.
	if _root == null: # Avoids repeatedly rebuilding empty baselines while no game scene is active.
		return # Leaves the already-unbound observer untouched.
	_root = null # Drops the stale production controller reference.
	_last_mode_prompt_open = false # Clears modal transition state for the next scene binding.
	_last_game_mode = &"" # Clears mode transition state for the next scene binding.
	_last_level_index = -1 # Clears campaign navigation state for the next scene binding.
	_last_selected_particle = &"" # Clears cannon selection state for the next scene binding.
	_last_scrap_mode = false # Clears scrap-mode state for the next scene binding.
	_last_freeplay_select_mode = false # Clears freeplay selection-mode state for the next scene binding.
	_last_freeplay_selected_ids.clear() # Clears retained reactant identifiers from the old scene.
	_last_shot_time_ms = -1.0 # Clears successful-shot timing from the old scene.
	_last_focus_id = 0 # Clears stale native focus identity.
	_last_status_text = "" # Clears stale status feedback text.
	_last_atom_snapshots.clear() # Clears atom composition baselines from the old world.
	_particle_velocities.clear() # Clears projectile motion baselines from the old world.

func _observe_menu_state() -> void: # Plays dedicated modal transition sounds when the mode chooser opens or closes.
	if _root.state.mode_prompt_open == _last_mode_prompt_open: # Ignores frames where modal visibility did not change.
		return # Leaves the sound mix untouched.
	if _root.state.mode_prompt_open: # Handles the mode chooser becoming visible.
		SoundEffects.play_menu_open() # Plays the rising modal-arrival chime.
	else: # Handles a mode choice closing the chooser.
		SoundEffects.play_menu_close() # Plays the short confirming modal-close chime.

func _observe_campaign_and_particle_state() -> void: # Plays campaign-navigation and loaded-particle selection feedback.
	if _root.state.current_level_index != _last_level_index: # Detects a successful switch to another campaign level.
		SoundEffects.play_level_change() # Plays the positive level-navigation chime once for the actual state change.
	if _root.state.selected_particle != _last_selected_particle: # Detects a successful cannon particle selection change.
		SoundEffects.play_particle_selected(_root.state.selected_particle) # Plays a pitch-coded cue for proton, neutron, or electron selection.
	_last_selected_particle = _root.state.selected_particle # Stores current cannon selection after checking for a change.

func _observe_toggle_state(suppress_feedback: bool) -> void: # Plays boolean mode feedback without sounding cleanup caused by level, mode, or reset transitions.
	if _root.state.scrap_mode != _last_scrap_mode and not suppress_feedback: # Detects a player-driven scrap-mode toggle.
		SoundEffects.play_toggle(_root.state.scrap_mode) # Mirrors the new scrap state with a rising or falling cue.
	if _root.state.freeplay_select_mode != _last_freeplay_select_mode and not suppress_feedback and _root.state.freeplay_reaction == null and not _root.state.freeplay_verifying: # Detects a player-driven reactant-selection-mode toggle outside reaction/verification cleanup.
		SoundEffects.play_toggle(_root.state.freeplay_select_mode) # Mirrors the new selection mode with a rising or falling cue.
	_last_scrap_mode = _root.state.scrap_mode # Stores current scrap-mode state after observation.
	_last_freeplay_select_mode = _root.state.freeplay_select_mode # Stores current freeplay-selection-mode state after observation.

func _observe_freeplay_selection(suppress_feedback: bool) -> void: # Plays reactant selection changes by comparing the manual identifier set between finalized frames.
	var current_ids: Dictionary = _root.state.freeplay_selected_ids # Reads the authoritative current reactant set.
	var changed: bool = current_ids.size() != _last_freeplay_selected_ids.size() # Detects the common add/remove case by set size first.
	if not changed: # Checks key membership only when both sets have the same number of entries.
		for key: Variant in current_ids.keys(): # Reads every currently selected identifier.
			if not _last_freeplay_selected_ids.has(key): # Detects a replacement or otherwise changed equal-sized set.
				changed = true # Records the set mutation.
				break # Stops after the first differing identifier.
	if changed and not suppress_feedback and _root.state.freeplay_reaction == null and not _root.state.freeplay_verifying: # Plays feedback only for direct player selection edits.
		if current_ids.size() > _last_freeplay_selected_ids.size(): # Detects one or more newly selected reactants.
			SoundEffects.play_toggle(true) # Plays the compact rising add-selection cue.
		elif current_ids.is_empty() and _last_freeplay_selected_ids.size() > 1: # Detects an explicit clear of a multi-reactant selection.
			SoundEffects.play_clear_selection() # Plays the dedicated softer clear-selection cue once.
		else: # Handles ordinary deselection of one or more reactants.
			SoundEffects.play_toggle(false) # Plays the compact falling deselection cue.
	_last_freeplay_selected_ids = current_ids.duplicate() # Stores an independent copy of the current set for the next frame.

func _observe_successful_shot() -> void: # Plays cannon audio only when physics accepted a projectile launch and updated its fire-rate timestamp.
	if _root.state.last_shot_time_ms > _last_shot_time_ms + 0.001: # Detects the authoritative successful-fire timestamp advancing.
		SoundEffects.play_particle_fire(_root.state.selected_particle) # Plays the dedicated proton, neutron, or electron launch sample.
	_last_shot_time_ms = _root.state.last_shot_time_ms # Stores current fire timing after observation.

func _observe_atom_changes(suppress_removal_feedback: bool) -> void: # Detects new nuclei, particle captures, and scrap removals from strongly typed atom state.
	var current_snapshots: Dictionary = _build_atom_snapshots() # Builds one compact current particle-count snapshot per live atom.
	for atom: AtomState in _root.state.atoms: # Reads each live atom to compare its composition against the previous frame.
		var atom_id: int = atom.id # Stores the stable world identifier used by snapshot dictionaries.
		var current: Vector3i = current_snapshots[atom_id] as Vector3i # Reads the current proton, neutron, and electron totals.
		if not _last_atom_snapshots.has(atom_id): # Detects a newly seeded nucleus rather than a capture into an existing atom.
			SoundEffects.play_atom_created() # Plays the small harmonic bloom for successful nucleus creation.
			continue # Avoids also interpreting the initial proton as a capture.
		var previous: Vector3i = _last_atom_snapshots[atom_id] as Vector3i # Reads the previous composition for this stable atom identifier.
		if current.x > previous.x: # Detects one or more proton captures since the previous finalized frame.
			SoundEffects.play_capture(&"proton") # Plays the proton-pitched construction confirmation.
		elif current.y > previous.y: # Detects one or more neutron captures since the previous finalized frame.
			SoundEffects.play_capture(&"neutron") # Plays the lower neutron-pitched construction confirmation.
		elif current.z > previous.z: # Detects one or more electron shell captures since the previous finalized frame.
			SoundEffects.play_capture(&"electron") # Plays the brighter electron-pitched construction confirmation.
	if not suppress_removal_feedback and _last_scrap_mode and _root.state.reaction == null and _root.state.freeplay_reaction == null and not _root.state.molecule_active and current_snapshots.size() < _last_atom_snapshots.size(): # Detects atom removal while scrap mode owns the workspace rather than reaction or reset cleanup.
		SoundEffects.play_scrap() # Plays one descending removal sound even if defensive cleanup removed more than one entry.
	_last_atom_snapshots = current_snapshots # Stores the current atom composition map for the next finalized frame.

func _observe_particle_ricochets() -> void: # Detects wall rebounds from projectile velocity sign changes at workspace boundaries.
	var current_velocities: Dictionary = {} # Builds a fresh map containing only projectiles that remain alive this frame.
	for particle: ParticleState in _root.state.particles: # Reads every live projectile after physics has advanced it.
		var instance_id: int = particle.get_instance_id() # Uses the RefCounted Object identifier as a stable lifetime key.
		var velocity: Vector2 = particle.velocity # Reads the finalized post-collision velocity for this frame.
		if _particle_velocities.has(instance_id): # Compares motion only for projectiles that also existed in the previous frame.
			var previous: Vector2 = _particle_velocities[instance_id] as Vector2 # Reads the previous finalized velocity vector.
			var horizontal_flip: bool = previous.x * velocity.x < 0.0 and (particle.position.x <= particle.radius + WALL_CONTACT_MARGIN or particle.position.x >= ChemistryData.WORLD_SIZE.x - particle.radius - WALL_CONTACT_MARGIN) # Detects a horizontal sign reversal exactly at a left or right boundary.
			var vertical_flip: bool = previous.y * velocity.y < 0.0 and (particle.position.y <= particle.radius + WALL_CONTACT_MARGIN or particle.position.y >= ChemistryData.WORLD_SIZE.y - particle.radius - WALL_CONTACT_MARGIN) # Detects a vertical sign reversal exactly at a top or bottom boundary.
			if horizontal_flip or vertical_flip: # Treats a corner rebound as one physical impact rather than two simultaneous pings.
				SoundEffects.play_ricochet(particle.kind) # Plays the particle-pitched metallic ricochet sample.
		current_velocities[instance_id] = velocity # Stores current velocity for comparison on the next finalized frame.
	_particle_velocities = current_velocities # Replaces stale projectile entries with the current live set.

func _observe_status_feedback() -> void: # Plays semantic validation sounds for noteworthy status changes without modifying gameplay systems.
	var status_text: String = _root.status_label.text # Reads the authoritative player-facing native status text.
	if status_text == _last_status_text: # Ignores unchanged status across ordinary frames.
		return # Leaves the sound mix untouched.
	if status_text.begins_with("Checking "): # Detects optional PubChem verification beginning.
		SoundEffects.play_verify() # Plays the light background-validation pulse.
	elif status_text.contains("Rejected") or status_text.contains("Unavailable") or status_text.contains("Limit Reached") or status_text.contains("No Known Element Has More Protons") or status_text.begins_with("Select At Least"): # Detects invalid chemistry, unavailable verification, and hard construction limits.
		SoundEffects.play_error() # Plays the muted rejection cue without making the failure feel punitive.
	_last_status_text = status_text # Stores current status after semantic observation.

func _observe_focus_change(suppress_feedback: bool) -> void: # Plays quiet focus-navigation feedback for keyboard and controller movement between native controls.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads the current native focus owner after controller navigation has completed.
	var focus_id: int = focus_owner.get_instance_id() if focus_owner != null else 0 # Converts the focus owner to a stable identity for change detection.
	if focus_id != _last_focus_id and _last_focus_id != 0 and focus_owner is BaseButton and not suppress_feedback and Time.get_ticks_msec() - _last_ui_press_ms > UI_PRESS_FOCUS_SUPPRESSION_MS: # Detects deliberate UI navigation while avoiding startup, menus, and activation layering.
		SoundEffects.play_ui_focus() # Plays the very quiet navigation tick once for the new focus target.
	_last_focus_id = focus_id # Stores the current focus identity for the next finalized frame.

func _handle_mouse_input(event: InputEventMouseButton) -> void: # Provides immediate sound for mouse-driven native controls and right-click inspection.
	if not event.pressed: # Ignores mouse releases because activation feedback belongs to the press edge.
		return # Leaves release events silent.
	if event.button_index == MOUSE_BUTTON_LEFT: # Handles ordinary left-click UI activation.
		var hovered: Control = get_viewport().gui_get_hovered_control() # Reads the deepest native control currently under the pointer.
		var actionable: Control = _find_actionable_control(hovered) # Resolves a button ancestor while excluding the workspace itself.
		if actionable is BaseButton: # Plays only for real native buttons rather than arbitrary interface surfaces.
			_play_control_press(actionable as BaseButton) # Plays ordinary click feedback plus any explicit reset semantic.
	elif event.button_index == MOUSE_BUTTON_RIGHT and _root.workspace.get_global_rect().has_point(event.position): # Handles the controller's right-click atom-inspection shortcut only inside the workspace.
		var local_position: Vector2 = _root.workspace.get_global_transform_with_canvas().affine_inverse() * event.position # Converts viewport coordinates to workspace-local coordinates.
		if _root.workspace.local_point_is_world(local_position): # Rejects responsive letterbox margins that are not part of the simulation world.
			var world_position: Vector2 = _root.workspace.world_from_local(local_position) # Converts the click into fixed simulation coordinates.
			SoundEffects.play_inspect(_root.physics.pick_atom_at(world_position) != null) # Plays a found or empty inspection cue using the exact clicked world point.

func _handle_key_input(event: InputEventKey) -> void: # Provides immediate sound for keyboard control activation, reset, and inspection shortcuts.
	if not event.pressed or event.echo: # Processes only distinct key-down edges.
		return # Leaves releases and key-repeat events silent.
	if event.keycode == KEY_R and not _root.state.mode_prompt_open: # Detects the controller's native reset shortcut outside the modal chooser.
		_play_reset_feedback() # Plays the reset sweep immediately even when the workspace is already empty.
	elif event.keycode == KEY_I and not _root.state.mode_prompt_open: # Detects the native atom-inspection shortcut.
		SoundEffects.play_inspect(_root.physics.pick_atom_at(_root.state.pointer_position) != null) # Plays found or empty feedback at the current fixed-world aim point.
	if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE: # Detects keyboard activation of a focused native button.
		var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads the control that will receive the controller's semantic activation.
		if focus_owner is BaseButton: # Excludes workspace Space firing and other non-button focus targets.
			_play_control_press(focus_owner as BaseButton) # Plays ordinary activation feedback plus any explicit reset semantic.

func _handle_controller_input(event: InputEvent) -> void: # Provides immediate sound for controller accept, reset, and inspection actions.
	if event.is_action_pressed(&"Button_Back") and not _root.state.mode_prompt_open: # Detects the native controller reset action outside the modal chooser.
		_play_reset_feedback() # Plays the reset sweep immediately even when there is nothing currently in the workspace.
	if event.is_action_pressed(&"Button_B") and not _root.state.mode_prompt_open: # Detects the native controller atom-inspection action.
		SoundEffects.play_inspect(_root.physics.pick_atom_at(_root.state.pointer_position) != null) # Plays found or empty feedback at the controller aim point.
	if event.is_action_pressed(&"Button_A"): # Detects controller activation of a focused native interface button.
		var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads the control about to receive semantic activation.
		if focus_owner is BaseButton: # Excludes workspace primary fire so launch audio remains tied to successful physics shots.
			_play_control_press(focus_owner as BaseButton) # Plays ordinary button activation feedback plus any explicit reset semantic.

func _play_control_press(button: BaseButton) -> void: # Plays ordinary button feedback while layering only the few semantics that need immediate direct-input treatment.
	SoundEffects.play_ui_press() # Gives every native button activation a consistent short confirmation chirp.
	_last_ui_press_ms = Time.get_ticks_msec() # Suppresses the focus tick caused by the same activation event.
	if button.name == &"ResetButton": # Detects the explicit reset/clear workspace native control.
		_play_reset_feedback() # Adds the soft reset sweep to the ordinary button click.

func _play_reset_feedback() -> void: # Plays one reset sweep and records it so state cleanup does not duplicate the same event.
	SoundEffects.play_reset() # Plays the dedicated workspace-reset sound immediately on the user action.
	_last_reset_sound_ms = Time.get_ticks_msec() # Records the semantic action for short duplicate-suppression checks.

func _reset_was_recent() -> bool: # Reports whether an explicit reset sound was just played for the same state transition.
	return Time.get_ticks_msec() - _last_reset_sound_ms <= RESET_DUPLICATE_SUPPRESSION_MS # Uses a short window that covers one or several frames without masking later actions.

func _build_atom_snapshots() -> Dictionary: # Builds a compact atom-id to particle-count map for sound-only change detection.
	var snapshots: Dictionary = {} # Allocates the fresh finalized-frame snapshot map.
	if _root == null: # Handles startup and unbound calls defensively.
		return snapshots # Returns an empty map when no world can be observed.
	for atom: AtomState in _root.state.atoms: # Reads every constructed atom or ion once.
		snapshots[atom.id] = Vector3i(atom.protons, atom.neutrons, atom.electrons) # Stores exact composition using a compact strongly typed integer vector.
	return snapshots # Returns the complete current atom composition map.

func _build_particle_velocity_map() -> Dictionary: # Builds a live projectile-id to velocity map for ricochet comparisons.
	var velocities: Dictionary = {} # Allocates the fresh finalized-frame projectile motion map.
	if _root == null: # Handles startup and unbound calls defensively.
		return velocities # Returns an empty map when no world can be observed.
	for particle: ParticleState in _root.state.particles: # Reads every currently live projectile once.
		velocities[particle.get_instance_id()] = particle.velocity # Stores exact finalized velocity under the projectile object's stable lifetime identifier.
	return velocities # Returns the complete current projectile motion map.

func _find_actionable_control(control: Control) -> Control: # Walks from the deepest hovered Control to the nearest native button ancestor.
	var current: Node = control # Starts from the leaf control reported by the viewport.
	while current != null and current != _root: # Walks toward the production controller root without escaping the active game scene.
		if current is BaseButton: # Recognizes Buttons, OptionButtons, and other native button derivatives.
			return current as Control # Returns the first actionable native button ancestor.
		current = current.get_parent() # Continues toward the scene root when the leaf is decorative button content.
	return null # Reports that the pointer is not over an actionable native button.
