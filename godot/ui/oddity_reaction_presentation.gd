class_name OddityReactionPresentationLayer # Applies Oddity audio, reduced-motion, and flash-reduction preferences to the existing reaction presentation.
extends ReactionPresentationLayer # Reuses the established chemistry presentation while overriding only shared accessibility behavior.

func _ready() -> void: # Initializes the inherited presentation and then applies standard Oddity audio routing.
	super._ready() # Creates the existing reaction presentation state, generated sounds, and runtime layout bindings.
	if _reaction_start_player != null: # Confirms the inherited reaction-start player exists.
		_reaction_start_player.bus = &"Effects" # Routes the reaction build-up cue through the shared Effects bus.
	if _reaction_complete_player != null: # Confirms the inherited reaction-complete player exists.
		_reaction_complete_player.bus = &"Effects" # Routes the success chord through the shared Effects bus.

func _start_completion_presentation() -> void: # Starts completion presentation while respecting reduced-motion particle suppression.
	if not OdditySettings.reduce_motion_enabled(): # Uses the full authored presentation when reduced motion is disabled.
		super._start_completion_presentation() # Preserves the existing flash, burst, sound, and staged result sequence.
		return # Stops after the inherited full-motion setup.
	_completion_elapsed = 0.0 # Starts the completion timeline without animated burst allocation.
	_hide_next_level_button() # Keeps progression unavailable until the normal information reveal time.
	_burst_particles.clear() # Guarantees no stale completion particles survive into reduced-motion presentation.
	if _reaction_complete_player != null: # Preserves the non-visual success cue when audio is available.
		_reaction_complete_player.play() # Plays the existing successful-reaction chord through the Effects bus.
	queue_redraw() # Requests the static reduced-motion result presentation immediately.

func _update_burst_particles(delta: float) -> void: # Advances particles only when reduced motion is disabled.
	if OdditySettings.reduce_motion_enabled(): # Detects live reduced-motion activation during an existing completion.
		_burst_particles.clear() # Removes already-spawned non-essential motion immediately.
		return # Skips all particle integration while reduced motion is active.
	super._update_burst_particles(delta) # Preserves the authored particle simulation when full motion is allowed.

func _update_next_level_button() -> void: # Removes the progression-button fade while reduced motion is enabled.
	if not OdditySettings.reduce_motion_enabled(): # Uses the authored staged fade for normal presentation.
		super._update_next_level_button() # Preserves existing positioning, fade timing, and focus assignment.
		return # Stops after the inherited full-motion update.
	_update_next_level_button_without_motion() # Positions and reveals progression instantly at the normal reveal point.

func _draw() -> void: # Draws reaction presentation according to live motion and flash accessibility preferences.
	if _root == null or not is_instance_valid(_root) or _root.state.mode_prompt_open: # Avoids drawing above the mode/system modal or without an active game.
		return # Leaves the presentation layer visually empty in invalid or modal states.
	var reduce_motion: bool = OdditySettings.reduce_motion_enabled() # Reads the shared motion preference once for this draw pass.
	if not reduce_motion: # Keeps the authored converging rings and completion particles only when motion is allowed.
		_draw_active_reaction() # Draws the existing moving reaction-energy treatment.
		_draw_burst_particles() # Draws the existing moving success-particle burst.
	if not reduce_motion and not OdditySettings.flash_reduction_enabled(): # Requires both motion and flash effects to be allowed before drawing the expanding completion flash.
		_draw_completion_flash() # Draws the existing short success flash and expanding ring.
	if reduce_motion: # Uses a static information card when animation reduction is requested.
		_draw_reduced_motion_result_card() # Presents all completion information without fades, scaling pulses, or staged text motion.
	else: # Uses the authored staged card when full motion is allowed.
		_draw_result_card() # Draws the existing formula pop, staged text reveal, and result surface.

func _draw_reduced_motion_result_card() -> void: # Draws a static completion card without animated opacity or scale changes.
	if _completion_elapsed < 0.12 or _root == null: # Preserves the short product-first beat while avoiding continuous animation.
		return # Leaves the opening completion instant focused on the formed product.
	var card_rect: Rect2 = _result_card_rect() # Uses the established responsive completion-card geometry.
	if card_rect.size.x <= 0.0 or card_rect.size.y <= 0.0: # Protects unusual startup or layout frames.
		return # Defers drawing until the responsive workspace has valid geometry.
	draw_rect(card_rect, Color(0.0431, 0.0549, 0.0706, 0.88), true) # Draws the fully established dark result-card surface without a fade.
	draw_rect(card_rect, Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.34), false, 2.0) # Draws the established chemistry accent outline at fixed opacity.
	var font: Font = ThemeDB.fallback_font # Uses the same built-in font as the normal completion presentation.
	var content_width: float = card_rect.size.x - 28.0 # Reserves the established left and right card padding.
	var content_x: float = card_rect.position.x + 14.0 # Stores the common text origin used for centered drawing.
	var card_y: float = card_rect.position.y # Stores the static card top edge.
	draw_string(font, Vector2(content_x, card_y + 43.0), _completion_formula, HORIZONTAL_ALIGNMENT_CENTER, content_width, 28, COLOR_WHITE) # Draws the product formula at its final authored size with no pop animation.
	draw_string(font, Vector2(content_x, card_y + 72.0), _completion_name, HORIZONTAL_ALIGNMENT_CENTER, content_width, 16, COLOR_MUTED) # Draws the product name immediately at final opacity.
	draw_string(font, Vector2(content_x, card_y + 108.0), _completion_heading, HORIZONTAL_ALIGNMENT_CENTER, content_width, 18, COLOR_GOLD) # Draws the completion heading immediately at final opacity.
	draw_string(font, Vector2(content_x, card_y + 134.0), _completion_subheading, HORIZONTAL_ALIGNMENT_CENTER, content_width, 12, COLOR_MUTED) # Draws the supporting progression text immediately at final opacity.

func _update_next_level_button_without_motion() -> void: # Positions and activates the real next-level button instantly once its normal reveal time arrives.
	if _root == null or not is_instance_valid(_root.next_button): # Rejects frames without the production progression control.
		return # Leaves presentation visual-only until the control exists.
	if not _completion_is_campaign or not _completion_has_next_level or _completion_elapsed < NEXT_BUTTON_REVEAL_TIME or not _root.state.molecule_active or _root.state.mode_prompt_open: # Requires the same valid non-final campaign completion state as the normal presentation.
		_hide_next_level_button() # Keeps progression completely unavailable before the established reveal point.
		return # Stops before positioning or enabling the button.
	var card_rect: Rect2 = _result_card_rect() # Reads the responsive completion rectangle shared with the static card.
	if card_rect.size.x <= 0.0 or card_rect.size.y <= 0.0: # Protects unusual layout frames without valid geometry.
		_hide_next_level_button() # Removes the button rather than leaving stale bounds onscreen.
		return # Defers progression until layout becomes valid.
	var button_width: float = minf(240.0, maxf(180.0, card_rect.size.x - 28.0)) # Matches the normal responsive progression width.
	var button_height: float = 42.0 # Matches the established primary-action height.
	var button_overlay_rect: Rect2 = Rect2(Vector2(card_rect.position.x + (card_rect.size.x - button_width) * 0.5, card_rect.end.y - button_height - 12.0), Vector2(button_width, button_height)) # Centers progression inside the result-card footer.
	var button_parent: Control = _root.next_button.get_parent() as Control # Reads the full-screen completion overlay that owns the native button.
	if button_parent == null: # Rejects an unexpected runtime reparenting failure.
		_hide_next_level_button() # Prevents a misplaced control from remaining interactive.
		return # Stops until scene binding is valid.
	var presentation_transform: Transform2D = get_global_transform_with_canvas() # Converts presentation-local coordinates into global canvas coordinates.
	var parent_inverse: Transform2D = button_parent.get_global_transform_with_canvas().affine_inverse() # Converts global canvas coordinates into the button parent's local coordinates.
	var button_top_left: Vector2 = parent_inverse * (presentation_transform * button_overlay_rect.position) # Resolves the responsive button's local top-left corner.
	var button_bottom_right: Vector2 = parent_inverse * (presentation_transform * button_overlay_rect.end) # Resolves the responsive button's local bottom-right corner.
	_root.next_button.position = button_top_left # Places the real button inside the static completion card.
	_root.next_button.size = button_bottom_right - button_top_left # Matches the real control bounds to the responsive footer.
	_root.next_button.visible = true # Reveals progression instantly with no fade animation.
	_root.next_button.modulate = Color.WHITE # Uses final opacity immediately under reduced-motion mode.
	_root.next_button.disabled = false # Makes progression available at the established reveal time.
	_root.next_button.mouse_filter = Control.MOUSE_FILTER_STOP # Enables normal pointer interaction immediately.
	if not _next_button_focus_assigned: # Assigns focus once when progression becomes available.
		_root.next_button.grab_focus() # Makes Enter and Button_A immediately activate the next level.
		_next_button_focus_assigned = true # Prevents repeated focus stealing on later frames.
