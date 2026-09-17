class_name CampaignModePresenter # Keeps campaign information presentation identical between Guided and Formula modes except for atom requirements.
extends Node # Polls the active scene directly because this project intentionally avoids signal-based UI coordination.

const FORMULA_MODE: StringName = &"formula_only" # Identifies the campaign mode that hides only the atom requirement list.
const FREEPLAY_MODE: StringName = &"freeplay" # Identifies the non-campaign sandbox mode.
const TINY_WIDTH: float = 620.0 # Matches the responsive layout threshold for hiding the secondary target-name line.

var _root: BohrBuilderController = null # References the active native game controller after it has completed _ready().
var _product_name_label: Label = null # Adds the completed molecule name in Formula Mode to match Guided Mode rendering.

func _ready() -> void: # Enables lightweight polling without introducing signals.
	set_process(true) # Rechecks campaign presentation after controller-driven mode or level changes.

func _process(_delta: float) -> void: # Applies Formula Mode parity after the controller has updated its normal UI state.
	var scene: Node = get_tree().current_scene # Reads the currently running scene.
	if scene == null or not scene.is_node_ready() or not scene is BohrBuilderController: # Waits for the native game controller and ignores unrelated scenes.
		_unbind_scene() # Clears stale references if the game scene has gone away.
		return # Leaves unrelated scenes untouched.
	if _root == null or not is_instance_valid(_root) or _root != scene: # Detects the first usable frame or a scene replacement.
		_bind_scene(scene as BohrBuilderController) # Captures the controller and creates the Formula-only product-name overlay.
	if _root.state.game_mode == FORMULA_MODE: # Applies parity only while Formula Mode is active.
		_apply_formula_mode_parity() # Restores every Guided information surface except the requirement list.
	else: # Removes Formula-only supplemental rendering in other modes.
		_hide_product_name_overlay() # Lets Guided and Freeplay use their native presentation unchanged.

func _bind_scene(scene_root: BohrBuilderController) -> void: # Captures the ready controller and installs one non-interactive molecule-name label.
	_root = scene_root # Retains the live native controller.
	_product_name_label = Label.new() # Creates a lightweight label for the completed Formula Mode molecule name.
	_product_name_label.name = "Formula Product Name" # Gives the runtime helper a readable scene-tree name.
	_product_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE # Prevents the supplemental label from intercepting workspace input.
	_product_name_label.focus_mode = Control.FOCUS_NONE # Keeps keyboard/controller focus on real game controls.
	_product_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER # Centers the molecule name beneath the rendered product.
	_product_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER # Centers text inside its small runtime rectangle.
	_product_name_label.add_theme_color_override("font_color", Color(0.6157, 0.6471, 0.6824, 0.95)) # Matches the native completed-product name color.
	_product_name_label.z_index = 20 # Places the supplemental text above the workspace drawing surface.
	_product_name_label.visible = false # Keeps it hidden until a Formula Mode reaction completes.
	_root.workspace.add_child(_product_name_label) # Attaches the label to the responsive workspace so it follows resizing naturally.
	_root.formula_mode_button.text = "Formula Mode\n\nHide The Atom List\n\nShows The Same Names, Lesson, Equation And Target As Guided Mode, But Hides The Required Atom Types And Counts." # Describes the mode's only intended information difference.

func _unbind_scene() -> void: # Clears references when the active game scene is replaced.
	_root = null # Drops the controller reference.
	_product_name_label = null # Drops the runtime label reference with its owning scene.

func _apply_formula_mode_parity() -> void: # Makes Formula Mode informationally identical to Guided Mode apart from required-atom rows.
	var entry: Dictionary = _current_campaign_entry() # Reads the active level definition once for all presentation updates.
	if entry.is_empty(): # Protects startup before campaign generation has completed.
		return # Defers presentation until level data exists.
	_root.requirement_group.visible = false # Preserves Formula Mode's single intended difference: no atom recipe list.
	_root.guided_level_details.visible = true # Shows the same lesson and reaction equation as Guided Mode.
	_root.target_name.visible = _root.size.x >= TINY_WIDTH # Shows the same molecule name as Guided Mode while respecting the same responsive hiding threshold.
	_root.level_title.text = _display_name(String(entry["title"])) # Restores the normal campaign level title instead of the generic Formula Challenge label.
	_root.target_name.text = _display_name(String(entry["name"])) # Keeps the target molecule name synchronized with the active level.
	_root.level_lesson.text = _sentence_case(String(entry["lesson"])) # Keeps the same chemistry lesson visible as Guided Mode.
	_root.reaction_equation.text = String(entry["equation"]) # Keeps the same reaction equation visible as Guided Mode.
	_ensure_full_level_selector() # Restores molecule names to every Formula Mode level-selector entry.
	_restore_guided_default_status(entry) # Replaces only the Formula-specific default hint while preserving temporary status messages.
	_update_product_name_overlay(entry) # Shows the completed molecule name after a successful Formula Mode reaction.

func _current_campaign_entry() -> Dictionary: # Returns the active generated campaign level safely.
	if _root == null or _root.campaign.is_empty(): # Rejects unavailable controller or campaign data.
		return {} # Reports no active level.
	var index: int = clampi(_root.state.current_level_index, 0, _root.campaign.size() - 1) # Bounds the current campaign index defensively.
	return _root.campaign[index] # Returns the same dictionary used by Guided Mode.

func _ensure_full_level_selector() -> void: # Rebuilds Formula Mode selector text only when the controller has stripped molecule names.
	if _root.level_select.item_count != _root.campaign.size(): # Detects an incomplete or newly rebuilt selector.
		_rebuild_full_level_selector() # Restores every campaign entry with its normal molecule name.
		return # Avoids duplicate comparison work after rebuilding.
	for index: int in _root.campaign.size(): # Checks each existing option against Guided Mode formatting.
		var expected_text: String = _level_selector_text(index, _root.campaign[index]) # Builds the normal campaign label for this level.
		if _root.level_select.get_item_text(index) != expected_text: # Detects Formula Mode's old formula-only text immediately.
			_rebuild_full_level_selector() # Replaces all entries in one consistent pass.
			return # Stops after repairing the selector.

func _rebuild_full_level_selector() -> void: # Builds the same numbered formula-and-name selector used by Guided Mode.
	_root.level_select.clear() # Removes Formula Mode's stripped selector entries.
	for index: int in _root.campaign.size(): # Adds all generated campaign levels in order.
		var entry: Dictionary = _root.campaign[index] # Reads one generated level definition.
		_root.level_select.add_item(_level_selector_text(index, entry), index) # Adds the Guided-equivalent number, formula and molecule name.
		_root.level_select.set_item_disabled(index, index > _root.state.unlocked_level) # Preserves the same campaign unlock restrictions.
	_root.level_select.select(clampi(_root.state.current_level_index, 0, _root.campaign.size() - 1)) # Keeps the active level selected after rebuilding.

func _level_selector_text(index: int, entry: Dictionary) -> String: # Formats one selector entry exactly like Guided Mode.
	var prefix: String = "%02d" % (index + 1) # Formats the one-based campaign level number.
	return "%s — %s — %s" % [prefix, String(entry["formula"]), _display_name(String(entry["name"]))] # Includes the same molecular formula and name as Guided Mode.

func _restore_guided_default_status(entry: Dictionary) -> void: # Replaces Formula Mode's special default hint without overwriting temporary gameplay feedback.
	var formula_only_status: String = "Target: %s — Work Out The Required Atoms And Build Them Anywhere In The Workspace" % String(entry["formula"]) # Reconstructs the old Formula-specific persistent status exactly.
	if _root.status_label.text != formula_only_status: # Preserves temporary messages such as inspection, scrapping, and reaction feedback.
		return # Leaves non-default status text untouched.
	_root.status_label.text = _guided_default_status(entry) # Substitutes the same persistent guidance Guided Mode would display.

func _guided_default_status(entry: Dictionary) -> String: # Mirrors the controller's Guided Mode persistent guidance for the active campaign level.
	if _root.state.current_level_index == 0: # Matches the dedicated first-level tutorial.
		return "Easy Start — Make Two Hydrogen Atoms: Fire A Proton To Start Each Nucleus, Then Capture One Electron On Each First Shell" # Returns the Guided opening instruction verbatim.
	if _root.state.current_level_index == 50: # Matches the dedicated ionic introduction.
		return "Ions Unlocked — Build The Listed Charged Atoms By Giving Them The Required Electron Totals" # Returns the Guided ion instruction verbatim.
	return "Build The Listed %s For %s Anywhere In The Workspace" % ["Ions" if String(entry["chemistry"]) == "ionic" else "Atoms", String(entry["formula"])] # Returns the normal Guided campaign instruction.

func _update_product_name_overlay(entry: Dictionary) -> void: # Adds the completed molecule name that the workspace natively draws only in Guided Mode.
	if _product_name_label == null or not is_instance_valid(_product_name_label) or not _root.state.molecule_active: # Requires a completed Formula Mode campaign reaction.
		_hide_product_name_overlay() # Removes stale product text while construction is still active.
		return # Stops before layout calculations.
	var workspace_size: Vector2 = _root.workspace.size # Reads the current responsive workspace dimensions.
	var scale_factor: float = minf(workspace_size.x / ChemistryData.WORLD_SIZE.x, workspace_size.y / ChemistryData.WORLD_SIZE.y) # Matches the workspace's fixed-world display scaling.
	var name_baseline: Vector2 = _root.workspace.local_from_world(_root.state.molecule_position + Vector2(0.0, 212.0)) # Converts the native Guided product-name baseline into displayed workspace coordinates.
	var label_height: float = maxf(20.0, 24.0 * scale_factor) # Reserves a readable text rectangle at small and large window sizes.
	var label_width: float = maxf(180.0, 420.0 * scale_factor) # Gives long molecule names enough centered horizontal space.
	_product_name_label.position = Vector2(workspace_size.x * 0.5 - label_width * 0.5, name_baseline.y - label_height * 0.72) # Aligns the Label visually with the Guided draw-string baseline.
	_product_name_label.size = Vector2(label_width, label_height) # Applies the responsive name rectangle.
	_product_name_label.add_theme_font_size_override("font_size", maxi(9, int(round(13.0 * scale_factor)))) # Scales the font with the same fixed-world transform used by Guided Mode.
	_product_name_label.text = _display_name(String(entry["name"])) # Displays the same completed molecule name as Guided Mode.
	_product_name_label.visible = true # Reveals the name only after the product exists.

func _hide_product_name_overlay() -> void: # Hides supplemental Formula Mode product text when it is not needed.
	if _product_name_label != null and is_instance_valid(_product_name_label): # Checks the runtime label still belongs to a live scene.
		_product_name_label.visible = false # Removes it outside a completed Formula Mode reaction.

func _display_name(value: String) -> String: # Converts internal identifiers to the same capitalized display names used by the controller.
	return value.replace("_", " ").capitalize() # Matches the controller's native UI name formatting.

func _sentence_case(value: String) -> String: # Matches the controller's lesson sentence formatting.
	if value.is_empty(): # Handles an empty lesson safely.
		return value # Returns empty text unchanged.
	return value.substr(0, 1).to_upper() + value.substr(1) # Capitalizes only the opening character while preserving chemistry notation.
