class_name ReactionPresentationLayer # Adds native reaction charge-up, completion particles, staged result cards, progression controls, and synthesized audio without changing chemistry rules.
extends Control # Draws the non-interactive visual presentation layer while positioning the existing native progression button over it.

const CAMPAIGN_CENTER: Vector2 = Vector2(550.0, 294.0) # Matches ChemistryData.WORLD_SIZE * Vector2(0.5, 0.42) without recalculating it every draw call.
const RESULT_CARD_WIDTH: float = 500.0 # Caps the completion card so it stays readable without dominating the workspace.
const RESULT_CARD_TEXT_HEIGHT: float = 154.0 # Reserves enough vertical space for staged formula, name, and completion text when no progression button is needed.
const RESULT_CARD_BUTTON_HEIGHT: float = 214.0 # Adds a dedicated footer area for the campaign next-level button.
const NEXT_BUTTON_REVEAL_TIME: float = 1.34 # Reveals progression only after the formula, product name, completion heading, and unlock text have appeared.
const NEXT_BUTTON_FADE_DURATION: float = 0.22 # Fades the native button in quickly without competing with the earlier chemistry result beats.
const BURST_PARTICLE_COUNT: int = 42 # Provides a substantial but inexpensive completion burst.
const CHARGE_RING_COUNT: int = 3 # Draws several converging rings during the reaction build-up.
const AUDIO_MIX_RATE: int = 44100 # Uses standard PCM output for the generated native sound effects.
const COLOR_CYAN: Color = Color(0.3098, 0.8275, 1.0, 1.0) # Provides the cool reaction-energy accent used by the existing dark interface.
const COLOR_GOLD: Color = Color(1.0, 0.7608, 0.2784, 1.0) # Provides the warm successful-completion accent.
const COLOR_WHITE: Color = Color(0.9608, 0.9725, 0.9843, 1.0) # Provides the primary result-card text color.
const COLOR_MUTED: Color = Color(0.6157, 0.6471, 0.6824, 1.0) # Matches the existing muted native interface text.

var _root: BohrBuilderController = null # References the ready production controller while the native game scene is active.
var _previous_campaign_reaction_active: bool = false # Detects campaign reaction start and completion edges without signals.
var _previous_freeplay_reaction_active: bool = false # Detects freeplay reaction start and completion edges without signals.
var _previous_freeplay_product_count: int = 0 # Detects which successful freeplay reaction created a new retained product.
var _last_mode: StringName = &"" # Clears stale completion presentation when the user changes game modes.
var _completion_elapsed: float = -1.0 # Tracks seconds since the latest successful reaction completed, or negative while no result is shown.
var _completion_world_position: Vector2 = Vector2.ZERO # Stores the successful product centre in fixed workspace coordinates.
var _completion_formula: String = "" # Stores the successful product formula for the staged reveal.
var _completion_name: String = "" # Stores the successful product name for the staged reveal.
var _completion_heading: String = "" # Stores Level Complete, Campaign Complete, or Reaction Complete text.
var _completion_subheading: String = "" # Stores the progression message shown after the main completion heading.
var _completion_is_campaign: bool = false # Distinguishes campaign completion from freeplay reaction presentation.
var _completion_has_next_level: bool = false # Tracks whether the current successful campaign result should reveal progression.
var _next_button_focus_assigned: bool = false # Prevents repeatedly stealing focus once the staged next-level button becomes interactive.
var _burst_particles: Array[Dictionary] = [] # Stores lightweight deterministic completion particles drawn directly by this Control.
var _reaction_start_player: AudioStreamPlayer = null # Plays the generated rising reaction cue.
var _reaction_complete_player: AudioStreamPlayer = null # Plays the generated completion chord.

func _ready() -> void: # Configures the overlay, generated audio players, and post-controller process ordering.
	mouse_filter = Control.MOUSE_FILTER_IGNORE # Guarantees the drawn presentation layer never blocks gameplay or UI clicks.
	focus_mode = Control.FOCUS_NONE # Keeps keyboard and controller focus on real game controls.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # Fills the root viewport so workspace-local effects can be converted into overlay coordinates.
	z_index = 90 # Places reaction polish above normal gameplay while leaving the native completion button above it.
	process_priority = 220 # Runs after the controller, responsive layout, and Formula Mode parity helpers have updated their state for the frame.
	_reaction_start_player = AudioStreamPlayer.new() # Creates the native player used for the reaction build-up sound.
	_reaction_start_player.name = "Reaction Start Audio" # Gives the runtime player a readable scene-tree name.
	_reaction_start_player.stream = _build_reaction_start_sound() # Assigns a generated rising tone so no external audio asset is required.
	_reaction_start_player.volume_db = -9.0 # Keeps the short effect present without overpowering future music or UI audio.
	add_child(_reaction_start_player) # Attaches the start player to the persistent presentation layer.
	_reaction_complete_player = AudioStreamPlayer.new() # Creates the native player used for successful reaction completion.
	_reaction_complete_player.name = "Reaction Complete Audio" # Gives the runtime player a readable scene-tree name.
	_reaction_complete_player.stream = _build_completion_sound() # Assigns a generated three-note success chord.
	_reaction_complete_player.volume_db = -5.0 # Makes the completion cue stronger than the reaction-start cue.
	add_child(_reaction_complete_player) # Attaches the completion player to the persistent presentation layer.
	set_process(true) # Enables state-edge polling, particles, staged reveal timing, progression presentation, and redraw requests.

func _process(delta: float) -> void: # Observes production reaction state and advances presentation effects without owning gameplay logic.
	var scene: Node = get_tree().current_scene # Reads the active native game scene.
	if scene == null or not scene.is_node_ready() or not scene is BohrBuilderController: # Waits until the production controller is ready and ignores unrelated scenes.
		_unbind_scene() # Clears stale state if the main game scene has gone away.
		queue_redraw() # Removes any remaining overlay pixels on the next draw pass.
		return # Stops presentation work until the native game returns.
	if _root == null or not is_instance_valid(_root) or _root != scene: # Detects the first usable frame or a scene replacement.
		_bind_scene(scene as BohrBuilderController) # Captures the live production controller and establishes transition baselines.
	if _root.state.game_mode != _last_mode: # Detects a deliberate switch between Guided, Formula, and Freeplay modes.
		_last_mode = _root.state.game_mode # Stores the newly active mode.
		_reset_completion() # Prevents an old result card from following the player into another mode.
	var campaign_active: bool = _root.state.reaction != null # Reads whether an automatic campaign reaction is currently combining atoms.
	var freeplay_active: bool = _root.state.freeplay_reaction != null # Reads whether a validated freeplay reaction is currently combining species.
	if campaign_active and not _previous_campaign_reaction_active: # Detects the frame a campaign reaction begins.
		_begin_reaction() # Starts charge-up audio and clears any previous completion residue.
	if freeplay_active and not _previous_freeplay_reaction_active: # Detects the frame a freeplay reaction begins.
		_begin_reaction() # Uses the same physical combination cue for freeplay chemistry.
	if not campaign_active and _previous_campaign_reaction_active and _root.state.molecule_active: # Detects successful campaign finalization after CampaignSystem consumes the reactants.
		_finish_campaign_reaction() # Starts the completion burst, result reveal, and progression cue.
	if not freeplay_active and _previous_freeplay_reaction_active and _root.state.freeplay_products.size() > _previous_freeplay_product_count: # Detects a successfully retained freeplay product.
		_finish_freeplay_reaction() # Starts the same completion burst with sandbox-specific copy.
	_previous_campaign_reaction_active = campaign_active # Stores the campaign edge baseline for the next frame.
	_previous_freeplay_reaction_active = freeplay_active # Stores the freeplay edge baseline for the next frame.
	_previous_freeplay_product_count = _root.state.freeplay_products.size() # Stores the current retained-product count for freeplay success detection.
	if _completion_elapsed >= 0.0: # Advances staged result presentation only after a successful reaction.
		_completion_elapsed += delta # Moves the formula/name/completion/button reveal timeline forward.
		if _completion_is_campaign and not _root.state.molecule_active: # Detects reset or next-level navigation after campaign completion.
			_reset_completion() # Removes the old card, button, and particles as soon as the completed product leaves the workspace.
	_update_burst_particles(delta) # Advances completion particles independently from campaign or freeplay simulation.
	_update_next_level_button() # Positions and reveals the native progression control as the final campaign-completion beat.
	if campaign_active or freeplay_active or _completion_elapsed >= 0.0 or not _burst_particles.is_empty(): # Redraws only while reaction presentation is actually visible.
		queue_redraw() # Requests the current charge-up, particle, flash, and result-card frame.

func _draw() -> void: # Renders reaction energy, completion burst particles, and the staged successful-reaction card.
	if _root == null or not is_instance_valid(_root) or _root.state.mode_prompt_open: # Avoids drawing above the mode-selection modal or without an active game.
		return # Leaves the presentation layer visually empty.
	_draw_active_reaction() # Draws converging energy while campaign or freeplay reactants are moving together.
	_draw_burst_particles() # Draws every currently alive success particle.
	_draw_completion_flash() # Draws a brief radial success flash behind the completed product.
	_draw_result_card() # Draws the staged formula, name, and level/reaction completion message.

func _bind_scene(scene_root: BohrBuilderController) -> void: # Captures a ready controller and initializes transition baselines without fabricating a reaction edge.
	_root = scene_root # Retains the production controller used for workspace coordinate conversion and state inspection.
	_bind_completion_button() # Moves the editor-defined next-level button out of the sidebar and into the dedicated completion overlay.
	_previous_campaign_reaction_active = _root.state.reaction != null # Prevents an already-running reaction from replaying its start cue after scene binding.
	_previous_freeplay_reaction_active = _root.state.freeplay_reaction != null # Prevents an already-running freeplay reaction from replaying its start cue after scene binding.
	_previous_freeplay_product_count = _root.state.freeplay_products.size() # Establishes the existing retained-product baseline.
	_last_mode = _root.state.game_mode # Establishes the current mode without clearing presentation on the first bound frame.
	_reset_completion() # Starts with no stale result presentation or visible progression control.

func _unbind_scene() -> void: # Clears scene-specific references and transient visual state safely.
	_reset_completion() # Hides any staged native progression control while the old scene reference is still valid.
	_root = null # Drops the production controller reference.
	_previous_campaign_reaction_active = false # Clears the campaign transition baseline.
	_previous_freeplay_reaction_active = false # Clears the freeplay transition baseline.
	_previous_freeplay_product_count = 0 # Clears retained-product transition state.
	_last_mode = &"" # Clears mode tracking for the next scene binding.

func _bind_completion_button() -> void: # Reparents the existing editor-defined next-level button into the root completion overlay without creating duplicate UI.
	if _root == null or not is_instance_valid(_root.next_button): # Rejects incomplete controller startup defensively.
		return # Leaves progression untouched until a valid controller is available.
	var completion_overlay: Control = _root.get_node_or_null(^"CompletionOverlay") as Control # Resolves the dedicated editor-defined overlay container.
	if completion_overlay == null: # Rejects an invalid or outdated scene layout.
		return # Leaves the button at its original location rather than losing it.
	if _root.next_button.get_parent() != completion_overlay: # Moves the button only once per instantiated scene.
		_root.next_button.reparent(completion_overlay, false) # Removes progression from the sidebar while preserving the same Button instance and controller reference.
	_root.next_button.set_anchors_preset(Control.PRESET_TOP_LEFT) # Makes runtime card-relative positioning deterministic inside the full-screen overlay.
	_root.next_button.custom_minimum_size = Vector2(220.0, 42.0) # Keeps the primary completion action large enough for mouse, keyboard, and controller use.
	_root.next_button.size = Vector2(220.0, 42.0) # Establishes a usable size before the first responsive result-card positioning pass.
	_root.next_button.mouse_filter = Control.MOUSE_FILTER_IGNORE # Prevents hidden or fading progression controls from intercepting clicks.
	_root.next_button.visible = false # Keeps progression absent until a successful non-final campaign completion is fully revealed.
	_root.next_button.disabled = true # Prevents keyboard/controller activation before the staged reveal is complete.
	_root.next_button.modulate = Color(1.0, 1.0, 1.0, 0.0) # Starts the staged button fully transparent.

func _begin_reaction() -> void: # Starts the successful-combination build-up presentation when gameplay enters a reaction state.
	_reset_completion() # Ensures only the newest reaction owns the visual timeline and progression control.
	if _reaction_start_player != null: # Guards the generated audio player during unusual startup ordering.
		_reaction_start_player.play() # Plays the rising synthesized reaction cue immediately.

func _finish_campaign_reaction() -> void: # Captures campaign result data and starts the successful level-completion presentation.
	var entry: Dictionary = _root.campaign_system.current_level() # Reads the same authoritative campaign entry used by gameplay and molecule rendering.
	_completion_world_position = _root.state.molecule_position # Anchors the burst to the completed molecule centre.
	_completion_formula = String(entry["formula"]) # Stores the exact displayed campaign formula.
	_completion_name = _display_name(String(entry["name"])) # Stores the normal title-style molecule name.
	_completion_is_campaign = true # Marks this result as campaign progression.
	_completion_has_next_level = _root.state.current_level_index < _root.campaign.size() - 1 # Records whether progression exists beyond this completed campaign target.
	_hide_next_level_button() # Immediately removes CampaignSystem's sidebar visibility change before this post-controller presentation frame is drawn.
	if not _completion_has_next_level: # Detects the final generated campaign level.
		_completion_heading = "Campaign Complete" # Gives the final target a stronger campaign-scale completion heading.
		_completion_subheading = "All 200 Levels Complete" # Makes full campaign completion explicit.
	else: # Handles every ordinary successful campaign target.
		_completion_heading = "Level %02d Complete" % (_root.state.current_level_index + 1) # Identifies exactly which campaign level was cleared.
		_completion_subheading = "Next Level Unlocked" # Reinforces progression after the chemistry result reveal.
	_start_completion_presentation() # Starts the shared flash, particles, chime, and staged card timeline.

func _finish_freeplay_reaction() -> void: # Captures the newest retained freeplay product and starts a non-progression success presentation.
	var product: FreeplayProductState = _root.state.freeplay_products[_root.state.freeplay_products.size() - 1] # Reads the product just appended by FreeplaySystem.
	_completion_world_position = product.position # Anchors the burst to the sandbox product centre.
	_completion_formula = ReactionLibrary.pretty_formula_from_ascii(product.formula) # Converts the stored ASCII formula into normal display notation.
	_completion_name = _display_name(product.product_name) # Converts the known or verified product identifier into readable title text.
	_completion_is_campaign = false # Marks this result as a sandbox reaction rather than campaign progression.
	_completion_has_next_level = false # Keeps campaign progression controls absent from freeplay success presentation.
	_completion_heading = "Reaction Complete" # Gives freeplay a clear success state without implying campaign advancement.
	_completion_subheading = "Freeplay Continues" # Reinforces that the sandbox remains active after product formation.
	_start_completion_presentation() # Starts the shared flash, particles, chime, and staged card timeline.

func _start_completion_presentation() -> void: # Starts the shared success timeline after either campaign or freeplay reaction finalization.
	_completion_elapsed = 0.0 # Starts staged formula/name/completion reveal timing from zero.
	_hide_next_level_button() # Keeps progression unavailable until every preceding success-information beat has appeared.
	_spawn_burst_particles() # Creates the deterministic radial particle burst around the formed product.
	if _reaction_complete_player != null: # Guards the generated audio player during unusual startup ordering.
		_reaction_complete_player.play() # Plays the synthesized successful-reaction chord.
	queue_redraw() # Shows the first completion flash frame immediately.

func _reset_completion() -> void: # Clears transient result presentation without touching gameplay state.
	_hide_next_level_button() # Removes any completion action and restores its hidden non-interactive state.
	_completion_elapsed = -1.0 # Disables the completion timeline.
	_completion_world_position = Vector2.ZERO # Clears the old product anchor.
	_completion_formula = "" # Clears previous formula text.
	_completion_name = "" # Clears previous molecule/product name text.
	_completion_heading = "" # Clears previous completion heading.
	_completion_subheading = "" # Clears previous progression/sandbox subheading.
	_completion_is_campaign = false # Restores the neutral presentation type.
	_completion_has_next_level = false # Clears campaign progression availability.
	_next_button_focus_assigned = false # Allows the next successful campaign completion to focus its own progression button once.
	_burst_particles.clear() # Removes any remaining success particles immediately.
	queue_redraw() # Invalidates the cached CanvasItem draw commands so a dismissed completion card vanishes in the same frame.

func _hide_next_level_button() -> void: # Returns the shared native progression control to a completely hidden and non-interactive state.
	_next_button_focus_assigned = false # Allows a future staged reveal to assign focus once.
	if _root == null or not is_instance_valid(_root.next_button): # Tolerates startup, shutdown, and unrelated scene states safely.
		return # Leaves no native control to update.
	_root.next_button.visible = false # Removes progression from both the old sidebar layout and completion overlay.
	_root.next_button.disabled = true # Prevents hidden keyboard/controller activation.
	_root.next_button.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ensures hidden progression never blocks workspace pointer interaction.
	_root.next_button.modulate = Color(1.0, 1.0, 1.0, 0.0) # Resets the next staged fade-in to a known transparent state.

func _update_next_level_button() -> void: # Positions, fades, enables, and focuses progression inside the successful-reaction result card.
	if _root == null or not is_instance_valid(_root.next_button): # Rejects frames without the production progression control.
		return # Leaves presentation visual-only until the control exists.
	if not _completion_is_campaign or not _completion_has_next_level or _completion_elapsed < NEXT_BUTTON_REVEAL_TIME or not _root.state.molecule_active or _root.state.mode_prompt_open: # Requires a revealed non-final campaign success state with no modal in front.
		_hide_next_level_button() # Keeps progression completely unavailable outside its final success beat.
		return # Stops before positioning or enabling the button.
	var card_rect: Rect2 = _result_card_rect() # Reads the exact responsive rectangle used by the drawn successful-reaction card.
	if card_rect.size.x <= 0.0 or card_rect.size.y <= 0.0: # Protects unusual layout frames without usable workspace geometry.
		_hide_next_level_button() # Removes the button rather than leaving it at a stale screen position.
		return # Defers progression until layout becomes valid.
	var button_width: float = minf(240.0, maxf(180.0, card_rect.size.x - 28.0)) # Keeps the primary action comfortably wide while respecting narrow completion cards.
	var button_height: float = 42.0 # Matches the established primary-action height used elsewhere in the native interface.
	var button_overlay_rect: Rect2 = Rect2(Vector2(card_rect.position.x + (card_rect.size.x - button_width) * 0.5, card_rect.end.y - button_height - 12.0), Vector2(button_width, button_height)) # Centers progression inside the completion card footer.
	var button_parent: Control = _root.next_button.get_parent() as Control # Reads the full-screen completion overlay that owns the native button.
	if button_parent == null: # Rejects an unexpected reparenting failure.
		_hide_next_level_button() # Prevents a misplaced progression control from remaining interactive.
		return # Stops until the scene binding can be corrected.
	var presentation_transform: Transform2D = get_global_transform_with_canvas() # Converts result-card overlay coordinates into global canvas coordinates.
	var parent_inverse: Transform2D = button_parent.get_global_transform_with_canvas().affine_inverse() # Converts global canvas coordinates into the completion overlay's local space.
	var button_top_left: Vector2 = parent_inverse * (presentation_transform * button_overlay_rect.position) # Resolves the responsive button's local top-left corner.
	var button_bottom_right: Vector2 = parent_inverse * (presentation_transform * button_overlay_rect.end) # Resolves the responsive button's local bottom-right corner.
	_root.next_button.position = button_top_left # Places the real native button inside the drawn completion card.
	_root.next_button.size = button_bottom_right - button_top_left # Matches the real control bounds to the responsive card footer.
	var reveal_alpha: float = clampf((_completion_elapsed - NEXT_BUTTON_REVEAL_TIME) / NEXT_BUTTON_FADE_DURATION, 0.0, 1.0) # Converts the final completion beat into a short native-control fade.
	_root.next_button.visible = true # Makes the button render above the drawn result card as soon as its final beat begins.
	_root.next_button.modulate = Color(1.0, 1.0, 1.0, reveal_alpha) # Fades the native themed button smoothly into the card.
	var interactive: bool = reveal_alpha >= 0.95 # Delays activation until the button is effectively fully visible.
	_root.next_button.disabled = not interactive # Prevents premature keyboard/controller progression during the fade.
	_root.next_button.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE # Enables pointer targeting only when progression is visibly ready.
	if interactive and not _next_button_focus_assigned: # Gives the newly revealed completion action one deliberate focus transition.
		_root.next_button.grab_focus() # Makes Enter and Button_A immediately activate Next Level after the celebratory sequence.
		_next_button_focus_assigned = true # Prevents subsequent frames from repeatedly stealing focus.

func _reaction_progress() -> float: # Returns normalized progress for whichever reaction animation is currently active.
	if _root == null: # Rejects calls without an active controller.
		return -1.0 # Reports no active reaction.
	if _root.state.reaction != null: # Prioritizes automatic campaign reactions while one exists.
		return clampf(_root.state.reaction.elapsed / maxf(0.001, _root.state.reaction.duration), 0.0, 1.0) # Normalizes campaign reaction timing safely.
	if _root.state.freeplay_reaction != null: # Handles validated freeplay combination timing.
		return clampf(_root.state.freeplay_reaction.elapsed / maxf(0.001, _root.state.freeplay_reaction.duration), 0.0, 1.0) # Normalizes freeplay reaction timing safely.
	return -1.0 # Reports no active reaction when both state slots are empty.

func _reaction_world_center() -> Vector2: # Returns the fixed-world centre used by the active reaction animation.
	if _root != null and _root.state.freeplay_reaction != null: # Uses the selected-species average for freeplay reactions.
		return _root.state.freeplay_reaction.center # Returns the same bounded centre used by FreeplaySystem.
	return CAMPAIGN_CENTER # Uses the deterministic campaign product centre otherwise.

func _draw_active_reaction() -> void: # Draws converging rings and spokes that intensify as reactants approach their product layout.
	var progress: float = _reaction_progress() # Reads current normalized reaction timing.
	if progress < 0.0: # Skips charge-up visuals outside active reaction animation.
		return # Leaves completed/idle workspace untouched.
	var center: Vector2 = _overlay_from_world(_reaction_world_center()) # Converts the reaction centre into overlay-local coordinates.
	var eased: float = 1.0 - pow(1.0 - progress, 2.0) # Accelerates visual convergence as the reaction approaches completion.
	for ring_index: int in CHARGE_RING_COUNT: # Draws multiple energy rings at staggered radii.
		var phase: float = fmod(progress * 1.8 + float(ring_index) / float(CHARGE_RING_COUNT), 1.0) # Offsets ring contraction so the effect remains continuous.
		var radius: float = lerpf(190.0, 34.0, phase) # Contracts each ring toward the forming molecule.
		var alpha: float = (1.0 - phase) * (0.14 + eased * 0.34) # Fades rings as they reach the product centre while increasing overall intensity.
		draw_arc(center, radius, 0.0, TAU, 72, Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, alpha), 2.0 + eased * 1.5, true) # Draws one smooth converging reaction ring.
	for spoke_index: int in 12: # Draws short rotating radial streaks around the reaction centre.
		var angle: float = float(spoke_index) / 12.0 * TAU + progress * 2.4 # Rotates the energy spokes slowly during combination.
		var outer_radius: float = lerpf(145.0, 70.0, eased) # Pulls the spokes inward as the atoms converge.
		var inner_radius: float = outer_radius - 24.0 # Gives every spoke a compact luminous length.
		var start: Vector2 = center + Vector2(cos(angle), sin(angle)) * inner_radius # Calculates the inner spoke endpoint.
		var finish: Vector2 = center + Vector2(cos(angle), sin(angle)) * outer_radius # Calculates the outer spoke endpoint.
		draw_line(start, finish, Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.10 + eased * 0.34), 1.5 + eased, true) # Draws one rotating energy streak.
	var core_alpha: float = 0.05 + eased * eased * 0.28 # Builds a subtle central glow as the reaction reaches completion.
	draw_circle(center, 24.0 + eased * 22.0, Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, core_alpha)) # Draws the reaction-energy core beneath the converging atoms.

func _spawn_burst_particles() -> void: # Creates a deterministic radial success burst without allocating Godot particle nodes.
	_burst_particles.clear() # Removes any particles left from a previous completion.
	for index: int in BURST_PARTICLE_COUNT: # Creates the fixed number of lightweight burst particles.
		var normalized_index: float = float(index) / float(BURST_PARTICLE_COUNT) # Converts particle index into a stable 0–1 distribution value.
		var angle: float = normalized_index * TAU + sin(float(index) * 2.173) * 0.11 # Spreads particles radially with deterministic angular variation.
		var speed: float = 110.0 + fmod(float(index * 47), 175.0) # Varies particle speed without random-number state.
		var velocity: Vector2 = Vector2(cos(angle), sin(angle)) * speed # Converts radial direction and speed into fixed-world velocity.
		var particle_color: Color = COLOR_CYAN if index % 3 != 0 else COLOR_GOLD # Mixes cool reaction energy with warm success accents.
		_burst_particles.append({"position": _completion_world_position, "velocity": velocity, "age": 0.0, "life": 0.95 + fmod(float(index * 13), 45.0) / 100.0, "radius": 2.5 + float(index % 4), "color": particle_color}) # Stores one self-contained lightweight particle record.

func _update_burst_particles(delta: float) -> void: # Advances burst particles in fixed-world coordinates and removes expired records.
	for index: int in range(_burst_particles.size() - 1, -1, -1): # Iterates backward so expired particles can be removed safely.
		var particle: Dictionary = _burst_particles[index] # Reads one mutable particle record.
		var age: float = float(particle["age"]) + delta # Advances particle lifetime.
		if age >= float(particle["life"]): # Detects particles whose fade interval has completed.
			_burst_particles.remove_at(index) # Removes the expired particle immediately.
			continue # Moves to the next surviving particle.
		var velocity: Vector2 = particle["velocity"] as Vector2 # Reads current fixed-world particle velocity.
		velocity *= pow(0.24, delta) # Applies smooth drag so the burst expands rapidly and then settles.
		var particle_position: Vector2 = particle["position"] as Vector2 # Reads current fixed-world particle position.
		particle_position += velocity * delta # Integrates particle movement.
		particle_position.y += 18.0 * delta * age # Adds a slight downward arc as particle energy dissipates.
		particle["age"] = age # Stores updated particle age.
		particle["velocity"] = velocity # Stores drag-adjusted velocity.
		particle["position"] = particle_position # Stores updated fixed-world position.
		_burst_particles[index] = particle # Writes the updated record back into the typed dictionary array.

func _draw_burst_particles() -> void: # Draws surviving completion particles with a smooth lifetime fade.
	for particle: Dictionary in _burst_particles: # Reads every current lightweight particle record.
		var age: float = float(particle["age"]) # Reads current particle age.
		var life: float = maxf(0.001, float(particle["life"])) # Reads lifetime with a defensive non-zero floor.
		var fade: float = 1.0 - clampf(age / life, 0.0, 1.0) # Converts remaining lifetime into opacity.
		var particle_color: Color = particle["color"] as Color # Reads the particle's assigned success accent.
		var position: Vector2 = _overlay_from_world(particle["position"] as Vector2) # Converts fixed-world particle position into overlay-local coordinates.
		draw_circle(position, float(particle["radius"]) * (0.55 + fade * 0.45), Color(particle_color.r, particle_color.g, particle_color.b, fade * 0.9)) # Draws one shrinking and fading completion spark.

func _draw_completion_flash() -> void: # Draws a short expanding success flash behind the product immediately after formation.
	if _completion_elapsed < 0.0 or _completion_elapsed > 0.7: # Limits the flash to the opening part of the completion timeline.
		return # Leaves later result presentation clean and readable.
	var center: Vector2 = _overlay_from_world(_completion_world_position) # Converts the completed product centre into overlay coordinates.
	var progress: float = clampf(_completion_elapsed / 0.7, 0.0, 1.0) # Normalizes flash expansion timing.
	var alpha: float = (1.0 - progress) * 0.34 # Fades the flash rapidly after its impact frame.
	draw_circle(center, lerpf(32.0, 155.0, progress), Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, alpha * 0.22)) # Draws the broad warm completion glow.
	draw_arc(center, lerpf(42.0, 190.0, progress), 0.0, TAU, 80, Color(COLOR_WHITE.r, COLOR_WHITE.g, COLOR_WHITE.b, alpha), lerpf(5.0, 1.0, progress), true) # Draws the expanding bright success ring.

func _draw_result_card() -> void: # Draws the staged formula, product name, explicit completion state, and backing surface for campaign progression.
	if _completion_elapsed < 0.12 or _root == null: # Delays the card slightly so the product flash gets the first visual beat.
		return # Leaves the opening completion frame focused on the molecule itself.
	var card_rect: Rect2 = _result_card_rect() # Uses one shared responsive rectangle for both custom drawing and the native next-level control.
	if card_rect.size.x <= 0.0 or card_rect.size.y <= 0.0: # Protects unusual startup/layout frames.
		return # Defers the card until the workspace has a usable display rectangle.
	var reveal: float = clampf((_completion_elapsed - 0.12) / 0.28, 0.0, 1.0) # Fades and slightly expands the card into view.
	var background_alpha: float = 0.88 * reveal # Gives the result a strong but not fully opaque dark backing.
	draw_rect(card_rect, Color(0.0431, 0.0549, 0.0706, background_alpha), true) # Draws the dark native result-card surface.
	draw_rect(card_rect, Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.34 * reveal), false, 2.0) # Draws a cool chemistry-energy outline around the result card.
	var font: Font = ThemeDB.fallback_font # Uses Godot's built-in fallback font so the overlay needs no external assets.
	var content_width: float = card_rect.size.x - 28.0 # Reserves comfortable left and right padding for all centered text.
	var content_x: float = card_rect.position.x + 14.0 # Stores the common left edge used by centered draw-string calls.
	var card_y: float = card_rect.position.y # Stores the card top edge for staged typography positions.
	var formula_scale: float = 1.0 + sin(minf(1.0, maxf(0.0, (_completion_elapsed - 0.18) / 0.32)) * PI) * 0.10 # Adds one restrained pop to the formula reveal.
	if _completion_elapsed >= 0.18: # Reveals the product formula first.
		var formula_alpha: float = clampf((_completion_elapsed - 0.18) / 0.24, 0.0, 1.0) # Fades the formula in quickly after the card appears.
		var formula_size: int = int(round(28.0 * formula_scale)) # Applies the short successful-reaction pop to formula typography.
		draw_string(font, Vector2(content_x, card_y + 43.0), _completion_formula, HORIZONTAL_ALIGNMENT_CENTER, content_width, formula_size, Color(COLOR_WHITE.r, COLOR_WHITE.g, COLOR_WHITE.b, formula_alpha)) # Draws the main chemistry result prominently.
	if _completion_elapsed >= 0.48: # Reveals the molecule/product name as the second information beat.
		var name_alpha: float = clampf((_completion_elapsed - 0.48) / 0.26, 0.0, 1.0) # Fades the readable name in after the formula has landed.
		draw_string(font, Vector2(content_x, card_y + 72.0), _completion_name, HORIZONTAL_ALIGNMENT_CENTER, content_width, 16, Color(COLOR_MUTED.r, COLOR_MUTED.g, COLOR_MUTED.b, name_alpha)) # Draws the successful molecule/product name.
	if _completion_elapsed >= 0.78: # Reveals explicit level/reaction completion after the chemistry identity is established.
		var heading_alpha: float = clampf((_completion_elapsed - 0.78) / 0.24, 0.0, 1.0) # Fades in the success-state heading.
		draw_string(font, Vector2(content_x, card_y + 108.0), _completion_heading, HORIZONTAL_ALIGNMENT_CENTER, content_width, 18, Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, heading_alpha)) # Draws Level Complete, Campaign Complete, or Reaction Complete.
	if _completion_elapsed >= 1.08: # Reveals progression/sandbox continuity as the final information beat before the campaign button.
		var subheading_alpha: float = clampf((_completion_elapsed - 1.08) / 0.24, 0.0, 1.0) # Fades the final supporting line into view.
		draw_string(font, Vector2(content_x, card_y + 134.0), _completion_subheading, HORIZONTAL_ALIGNMENT_CENTER, content_width, 12, Color(COLOR_MUTED.r, COLOR_MUTED.g, COLOR_MUTED.b, subheading_alpha)) # Draws the next-level or freeplay continuation message.

func _result_card_rect() -> Rect2: # Calculates the shared responsive result-card geometry used by custom drawing and native progression controls.
	var workspace_rect: Rect2 = _workspace_overlay_rect() # Reads the responsive workspace rectangle in presentation-local coordinates.
	if workspace_rect.size.x <= 0.0 or workspace_rect.size.y <= 0.0: # Protects unusual startup/layout frames.
		return Rect2() # Reports no usable card until the workspace has valid geometry.
	var card_width: float = minf(RESULT_CARD_WIDTH, maxf(260.0, workspace_rect.size.x - 36.0)) # Keeps the card inside narrow responsive workspace bounds.
	var desired_height: float = RESULT_CARD_BUTTON_HEIGHT if _completion_has_next_level else RESULT_CARD_TEXT_HEIGHT # Reserves a footer only when a real next-level action exists.
	var available_height: float = maxf(126.0, workspace_rect.size.y - 36.0) # Leaves a small vertical workspace margin while preserving a readable minimum card.
	var card_height: float = minf(desired_height, available_height) # Shrinks the card only when responsive workspace height genuinely requires it.
	var card_x: float = workspace_rect.position.x + (workspace_rect.size.x - card_width) * 0.5 # Centers the card horizontally over the playable workspace.
	var card_y: float = workspace_rect.position.y + 18.0 # Places completion information near the top so it does not cover the formed molecule.
	return Rect2(Vector2(card_x, card_y), Vector2(card_width, card_height)) # Returns the final responsive completion-card rectangle.

func _workspace_overlay_rect() -> Rect2: # Converts the responsive workspace Control bounds into this overlay's local coordinate system.
	if _root == null or not is_instance_valid(_root.workspace): # Rejects missing workspace references defensively.
		return Rect2() # Reports an unusable empty rectangle.
	var workspace_global_rect: Rect2 = _root.workspace.get_global_rect() # Reads the actual displayed workspace bounds after responsive layout changes.
	var inverse: Transform2D = get_global_transform_with_canvas().affine_inverse() # Builds the overlay-local conversion from global canvas coordinates.
	var top_left: Vector2 = inverse * workspace_global_rect.position # Converts the displayed workspace top-left corner into overlay-local coordinates.
	var bottom_right: Vector2 = inverse * workspace_global_rect.end # Converts the displayed workspace bottom-right corner into overlay-local coordinates.
	return Rect2(top_left, bottom_right - top_left) # Returns the responsive workspace rectangle in overlay-local coordinates.

func _overlay_from_world(world_position: Vector2) -> Vector2: # Converts one fixed simulation-world position into this full-screen overlay's local coordinate space.
	if _root == null or not is_instance_valid(_root.workspace): # Rejects missing workspace references defensively.
		return Vector2.ZERO # Returns a neutral point when conversion is impossible.
	var workspace_local: Vector2 = _root.workspace.local_from_world(world_position) # Uses the production workspace's own letterbox/scale transform.
	var canvas_position: Vector2 = _root.workspace.get_global_transform_with_canvas() * workspace_local # Converts workspace-local coordinates into global canvas coordinates.
	return get_global_transform_with_canvas().affine_inverse() * canvas_position # Converts global canvas coordinates into this overlay's local coordinates.

func _build_reaction_start_sound() -> AudioStreamWAV: # Generates a short rising synthetic cue that communicates atoms entering a reaction state.
	var duration: float = 0.52 # Keeps the cue concise so it does not obscure the reaction animation itself.
	var sample_count: int = int(duration * float(AUDIO_MIX_RATE)) # Calculates mono PCM sample count.
	var pcm: PackedByteArray = PackedByteArray() # Stores little-endian signed sixteen-bit PCM bytes.
	pcm.resize(sample_count * 2) # Reserves exactly two bytes for every mono sample.
	for sample_index: int in sample_count: # Synthesizes the entire cue deterministically at startup.
		var time: float = float(sample_index) / float(AUDIO_MIX_RATE) # Converts sample index into seconds.
		var progress: float = time / duration # Normalizes the cue timeline.
		var frequency: float = lerpf(170.0, 620.0, progress * progress) # Sweeps upward faster near the end to reinforce converging energy.
		var envelope: float = sin(clampf(progress, 0.0, 1.0) * PI) # Applies a click-free attack and release envelope.
		var sample_value: float = sin(TAU * frequency * time) * 0.22 * envelope # Generates the primary rising sine tone.
		sample_value += sin(TAU * frequency * 2.01 * time) * 0.055 * envelope # Adds a quiet overtone for a more energetic synthetic texture.
		_write_pcm16_sample(pcm, sample_index, sample_value) # Encodes the mixed sample into the PCM byte buffer.
	return _stream_from_pcm(pcm) # Wraps the generated PCM bytes in a playable native AudioStreamWAV resource.

func _build_completion_sound() -> AudioStreamWAV: # Generates a short three-note success chord for successful campaign and freeplay reactions.
	var duration: float = 0.92 # Gives the completion sound enough sustain to accompany the staged result reveal.
	var sample_count: int = int(duration * float(AUDIO_MIX_RATE)) # Calculates mono PCM sample count.
	var pcm: PackedByteArray = PackedByteArray() # Stores little-endian signed sixteen-bit PCM bytes.
	pcm.resize(sample_count * 2) # Reserves exactly two bytes for every mono sample.
	var frequencies: PackedFloat32Array = PackedFloat32Array([523.25, 659.25, 783.99]) # Uses a bright C-major triad for an immediately readable success cue.
	for sample_index: int in sample_count: # Synthesizes the complete success chord deterministically at startup.
		var time: float = float(sample_index) / float(AUDIO_MIX_RATE) # Converts sample index into seconds.
		var mixed_sample: float = 0.0 # Accumulates staggered chord voices for the current sample.
		for voice_index: int in frequencies.size(): # Adds each note with a slight stagger to create a compact ascending chime.
			var voice_start: float = float(voice_index) * 0.085 # Delays successive notes just enough to read as a celebratory arpeggio.
			if time < voice_start: # Skips a voice until its staggered entry point.
				continue # Leaves this voice silent for the current sample.
			var voice_time: float = time - voice_start # Measures seconds since this note began.
			var remaining: float = clampf(1.0 - voice_time / maxf(0.001, duration - voice_start), 0.0, 1.0) # Creates the note's decaying sustain envelope.
			var attack: float = clampf(voice_time / 0.018, 0.0, 1.0) # Smooths the opening transient to avoid clicks.
			var envelope: float = attack * remaining * remaining # Combines fast attack with a soft quadratic decay.
			mixed_sample += sin(TAU * float(frequencies[voice_index]) * voice_time) * 0.16 * envelope # Adds the primary note voice.
			mixed_sample += sin(TAU * float(frequencies[voice_index]) * 2.0 * voice_time) * 0.025 * envelope # Adds a quiet octave harmonic for clarity.
		_write_pcm16_sample(pcm, sample_index, mixed_sample) # Encodes the mixed chord sample into the PCM byte buffer.
	return _stream_from_pcm(pcm) # Wraps the generated PCM bytes in a playable native AudioStreamWAV resource.

func _write_pcm16_sample(buffer: PackedByteArray, sample_index: int, value: float) -> void: # Encodes one normalized mono sample into little-endian signed sixteen-bit PCM bytes.
	var clamped_value: float = clampf(value, -1.0, 1.0) # Prevents generated waveforms from overflowing sixteen-bit PCM range.
	var signed_sample: int = int(round(clamped_value * 32767.0)) # Converts normalized audio amplitude into a signed sixteen-bit integer.
	var unsigned_sample: int = signed_sample & 0xffff # Preserves the two's-complement sixteen-bit representation for negative samples.
	buffer[sample_index * 2] = unsigned_sample & 0xff # Writes the low byte first for little-endian PCM.
	buffer[sample_index * 2 + 1] = (unsigned_sample >> 8) & 0xff # Writes the high byte second for little-endian PCM.

func _stream_from_pcm(pcm: PackedByteArray) -> AudioStreamWAV: # Creates a mono sixteen-bit WAV stream from generated raw PCM bytes.
	var stream: AudioStreamWAV = AudioStreamWAV.new() # Allocates the native in-memory audio stream.
	stream.format = AudioStreamWAV.FORMAT_16_BITS # Declares signed sixteen-bit PCM sample format.
	stream.mix_rate = AUDIO_MIX_RATE # Uses the same sample rate used during synthesis.
	stream.stereo = false # Keeps the compact generated cues mono and inexpensive.
	stream.data = pcm # Assigns the generated PCM bytes directly to the playable stream.
	return stream # Returns the fully configured native audio resource.

func _display_name(value: String) -> String: # Converts internal identifiers to the same capitalized display style used throughout the native UI.
	return value.replace("_", " ").capitalize() # Replaces underscores and capitalizes each displayed word.
