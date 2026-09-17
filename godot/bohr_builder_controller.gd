class_name BohrBuilderController # Owns native UI state, input routing, simulation updates, and direct system composition.
extends Control # Uses the root native Control as the single application coordinator.

const SAVE_PATH: String = "user://bohr_builder.cfg" # Stores campaign progress without browser localStorage.
const KEYBOARD_AIM_SPEED: float = 430.0 # Preserves the browser keyboard aim speed.
const CONTROLLER_AIM_SPEED: float = 520.0 # Preserves the browser controller aim speed.
const BUTTON_A: StringName = &"Button_A" # Activates focused UI or performs the contextual workspace action.
const BUTTON_B: StringName = &"Button_B" # Inspects the atom under the current aim point.
const BUTTON_X: StringName = &"Button_X" # Toggles scrap mode.
const BUTTON_Y: StringName = &"Button_Y" # Toggles freeplay reactant-selection mode.
const BUTTON_START: StringName = &"Button_Start" # Opens the mode chooser.
const BUTTON_BACK: StringName = &"Button_Back" # Resets the current level or freeplay workspace.
const BUTTON_LB: StringName = &"Button_LB" # Selects the previous particle type.
const BUTTON_RB: StringName = &"Button_RB" # Selects the next particle type.
const BUTTON_LT: StringName = &"Button_LT" # Selects the previous unlocked campaign level.
const BUTTON_RT: StringName = &"Button_RT" # Selects the next unlocked campaign level.
const BUTTON_L3: StringName = &"Button_L3" # Clears selected freeplay reactants.
const BUTTON_R3: StringName = &"Button_R3" # Reacts selected freeplay species or advances a completed campaign level.
const DPAD_NORTH: StringName = &"DPad_North" # Moves native interface focus upward.
const DPAD_SOUTH: StringName = &"DPad_South" # Moves native interface focus downward.
const DPAD_WEST: StringName = &"DPad_West" # Moves native interface focus left.
const DPAD_EAST: StringName = &"DPad_East" # Moves native interface focus right.
const STICK_LEFT_NORTH: StringName = &"StickLeft_North" # Supplies controller aim upward.
const STICK_LEFT_SOUTH: StringName = &"StickLeft_South" # Supplies controller aim downward.
const STICK_LEFT_WEST: StringName = &"StickLeft_West" # Supplies controller aim left.
const STICK_LEFT_EAST: StringName = &"StickLeft_East" # Supplies controller aim right.

@onready var mode_badge: Label = $AppMargin/AppShell/TopBar/LevelHeader/ModeReadout/ModeBadge # Displays the selected game mode.
@onready var mode_button: Button = $AppMargin/AppShell/TopBar/LevelHeader/ModeReadout/ModeButton # Opens the native mode chooser.
@onready var campaign_picker: VBoxContainer = $AppMargin/AppShell/TopBar/LevelHeader/CampaignPicker # Holds the campaign level selector.
@onready var level_select: OptionButton = $AppMargin/AppShell/TopBar/LevelHeader/CampaignPicker/LevelSelect # Selects any unlocked campaign level.
@onready var target_readout: VBoxContainer = $AppMargin/AppShell/TopBar/LevelHeader/TargetReadout # Holds current target formula and name.
@onready var target_formula: Label = $AppMargin/AppShell/TopBar/LevelHeader/TargetReadout/TargetFormula # Displays current target formula.
@onready var target_name: Label = $AppMargin/AppShell/TopBar/LevelHeader/TargetReadout/TargetName # Displays target name in guided mode.
@onready var workspace: BohrWorkspace = $AppMargin/AppShell/WorkspaceLayout/CanvasPanel/Workspace # Draws and receives native world interaction.
@onready var status_label: Label = $AppMargin/AppShell/WorkspaceLayout/CanvasPanel/StatusBanner/StatusText # Displays current game feedback.
@onready var campaign_level_group: PanelContainer = $AppMargin/AppShell/WorkspaceLayout/Sidebar/CampaignLevelGroup # Displays campaign metadata.
@onready var level_number: Label = $AppMargin/AppShell/WorkspaceLayout/Sidebar/CampaignLevelGroup/Margin/Content/Heading/LevelIdentity/LevelNumber # Displays current campaign number.
@onready var level_title: Label = $AppMargin/AppShell/WorkspaceLayout/Sidebar/CampaignLevelGroup/Margin/Content/Heading/LevelIdentity/LevelTitle # Displays current campaign title.
@onready var level_progress: Label = $AppMargin/AppShell/WorkspaceLayout/Sidebar/CampaignLevelGroup/Margin/Content/Heading/LevelProgress # Displays current campaign progress.
@onready var guided_level_details: VBoxContainer = $AppMargin/AppShell/WorkspaceLayout/Sidebar/CampaignLevelGroup/Margin/Content/GuidedDetails # Holds guided lesson and equation content.
@onready var level_lesson: Label = $AppMargin/AppShell/WorkspaceLayout/Sidebar/CampaignLevelGroup/Margin/Content/GuidedDetails/LevelLesson # Displays level lesson text.
@onready var reaction_equation: Label = $AppMargin/AppShell/WorkspaceLayout/Sidebar/CampaignLevelGroup/Margin/Content/GuidedDetails/EquationPanel/EquationMargin/EquationRow/EquationText # Displays guided reaction equation.
@onready var proton_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/ParticleGroup/Margin/Content/ParticleGrid/ProtonButton # Selects proton projectiles.
@onready var neutron_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/ParticleGroup/Margin/Content/ParticleGrid/NeutronButton # Selects neutron projectiles.
@onready var electron_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/ParticleGroup/Margin/Content/ParticleGrid/ElectronButton # Selects electron projectiles.
@onready var requirement_group: PanelContainer = $AppMargin/AppShell/WorkspaceLayout/Sidebar/RequirementGroup # Displays guided campaign requirements.
@onready var requirement_list: VBoxContainer = $AppMargin/AppShell/WorkspaceLayout/Sidebar/RequirementGroup/Margin/Content/RequirementList # Holds dynamic requirement rows.
@onready var requirement_hint: Label = $AppMargin/AppShell/WorkspaceLayout/Sidebar/RequirementGroup/Margin/Content/RequirementHint # Explains neutral or ionic matching rules.
@onready var freeplay_group: PanelContainer = $AppMargin/AppShell/WorkspaceLayout/Sidebar/FreeplayGroup # Displays manual reaction controls.
@onready var freeplay_selection: Label = $AppMargin/AppShell/WorkspaceLayout/Sidebar/FreeplayGroup/Margin/Content/FreeplaySelection # Displays current selected formula and charge.
@onready var react_select_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/FreeplayGroup/Margin/Content/FreeplayActions/ReactSelectButton # Toggles manual reactant selection.
@onready var clear_reactants_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/FreeplayGroup/Margin/Content/FreeplayActions/ClearReactantsButton # Clears manual reaction selection.
@onready var react_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/FreeplayGroup/Margin/Content/ReactButton # Attempts a manual freeplay reaction.
@onready var inspector_rows: VBoxContainer = $AppMargin/AppShell/WorkspaceLayout/Sidebar/InspectorGroup/Margin/Content/InspectorRows # Holds native atom inspector rows.
@onready var scrap_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/InspectorGroup/Margin/Content/Heading/ScrapButton # Toggles atom removal mode.
@onready var reset_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/ActionGroup/ResetButton # Resets the current level or workspace.
@onready var next_button: Button = $AppMargin/AppShell/WorkspaceLayout/Sidebar/ActionGroup/NextButton # Advances a completed campaign level.
@onready var mode_overlay: ColorRect = $ModeOverlay # Covers the app while choosing a game mode.
@onready var guided_mode_button: Button = $ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/ModeGrid/GuidedModeButton # Selects guided campaign mode.
@onready var formula_mode_button: Button = $ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/ModeGrid/FormulaModeButton # Selects formula-only campaign mode.
@onready var freeplay_mode_button: Button = $ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/ModeGrid/FreeplayModeButton # Selects open freeplay mode.

var state: BohrGameState = BohrGameState.new() # Stores all mutable gameplay state.
var physics: BohrPhysicsSystem # Owns particle and atom simulation behavior.
var campaign_system: CampaignSystem # Owns automatic campaign matching and progression.
var freeplay_system: FreeplaySystem # Owns manual reaction selection and validation.
var campaign: Array[Dictionary] = [] # Caches generated campaign data for UI access.
var _status_deadline_ms: int = 0 # Stores temporary status expiration time or zero for persistent text.
var _requirement_signature: String = "" # Avoids rebuilding unchanged requirement UI every frame.
var _last_level_select_index: int = -1 # Tracks OptionButton selection because architecture intentionally avoids signals.

func _ready() -> void: # Initializes native state, composed systems, UI, persistence, and the opening mode chooser.
	campaign = CampaignData.levels() # Generates and caches the exact two-hundred-level campaign.
	state.unlocked_level = _read_unlocked_level() # Restores persistent campaign progression from user storage.
	physics = BohrPhysicsSystem.new(state, self) # Creates the native particle/atom physics component.
	campaign_system = CampaignSystem.new(state, self, physics) # Creates the native campaign component.
	freeplay_system = FreeplaySystem.new(state, self) # Creates the native freeplay component.
	workspace.configure(state, physics, campaign_system) # Binds native rendering to shared state and systems.
	populate_level_select() # Builds the native selector using current unlock state.
	_update_particle_buttons() # Reflects the default loaded proton.
	reset_game() # Initializes all world/UI state through the same normal reset path.
	open_mode_overlay() # Preserves the browser behavior that requires a mode choice at launch.
	set_process(true) # Enables native simulation, polling, and redraw updates.

func _process(delta: float) -> void: # Runs native input polling, simulation systems, optional network verification, and UI refresh.
	var frame_delta: float = minf(0.025, delta) # Preserves the browser requestAnimationFrame delta clamp.
	_process_aim_input(frame_delta) # Applies held keyboard and analog-controller aim movement.
	freeplay_system.process_network() # Advances optional PubChem verification without blocking.
	if not state.mode_prompt_open: # Pauses world simulation while the mode chooser is visible.
		if state.game_mode == &"freeplay": # Runs freeplay-specific world flow.
			if state.freeplay_reaction != null: # Gives reaction animation exclusive control of selected atoms.
				freeplay_system.update_reaction(frame_delta) # Advances manual product combination.
			else: # Runs ordinary freeplay construction.
				physics.update_particles(frame_delta, 1.0) # Advances projectiles with stable freeplay assistance.
				physics.update_atoms(frame_delta) # Advances atom drift and boundaries.
		else: # Runs guided or formula-only campaign flow.
			if state.reaction == null and not state.molecule_active: # Runs ordinary campaign construction before reaction readiness.
				physics.update_particles(frame_delta, float(campaign_system.current_level()["assist"])) # Advances projectiles with current level assistance.
				physics.update_atoms(frame_delta) # Advances atom drift and boundaries.
				campaign_system.check_reaction_ready() # Starts automatic combination immediately when requirements are met.
			elif state.reaction != null: # Runs deterministic campaign product combination.
				campaign_system.update_reaction(frame_delta) # Advances campaign reaction animation.
		if state.pointer_down: # Preserves click/space/controller held continuous firing.
			physics.fire_particle(float(Time.get_ticks_msec())) # Attempts another rate-limited projectile shot.
	_update_status_timeout() # Restores default feedback when a temporary message expires.
	_poll_level_select() # Applies native OptionButton selection changes without connecting signals.
	refresh_requirement_ui() # Updates guided requirement counters only when their signature changes.
	refresh_freeplay_ui() # Keeps manual reaction controls synchronized with live state.
	workspace.queue_redraw() # Requests one native world redraw for animation and state changes.

func _input(event: InputEvent) -> void: # Routes mouse, keyboard, and controller events without signal connections.
	if event is InputEventMouseMotion: # Tracks pointer aim only while the cursor is over the native workspace.
		var motion: InputEventMouseMotion = event # Narrows the event to mouse motion.
		if workspace.get_global_rect().has_point(motion.position): # Tests against displayed workspace bounds.
			var local_position: Vector2 = workspace.get_global_transform_with_canvas().affine_inverse() * motion.position # Converts viewport coordinates to workspace-local coordinates.
			if workspace.local_point_is_world(local_position): # Ignores letterbox margins outside the fixed world.
				state.pointer_position = workspace.world_from_local(local_position) # Updates fixed simulation aim coordinates.
		return # Leaves GUI hover handling to native Controls.
	if event is InputEventMouseButton: # Handles workspace clicks and native buttons directly.
		_handle_mouse_button(event) # Routes the mouse button through contextual native actions.
		return # Stops custom event analysis after mouse handling.
	if event is InputEventKey: # Handles keyboard shortcuts and workspace actions.
		_handle_key_event(event) # Routes the key event through native focus-aware controls.
		return # Stops custom event analysis after keyboard handling.
	_handle_controller_event(event) # Handles named Godot joypad actions for all remaining input events.

func set_status(message: String, duration_seconds: float = 1.8) -> void: # Displays native status feedback with optional automatic expiry.
	status_label.text = message # Writes the requested feedback message.
	_status_deadline_ms = Time.get_ticks_msec() + int(duration_seconds * 1000.0) if duration_seconds > 0.0 else 0 # Stores expiry time or makes the message persistent.

func refresh_inspector() -> void: # Rebuilds the native atom inspector for the currently selected species.
	_clear_container(inspector_rows) # Removes previously generated inspector rows.
	var atom: AtomState = physics.find_atom_by_id(state.selected_atom_id) if state.selected_atom_id >= 0 else null # Resolves the selected live atom.
	if atom == null: # Displays the browser-equivalent empty inspector state.
		var empty_label: Label = Label.new() # Creates one native informational label.
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # Allows the sidebar message to wrap naturally.
		empty_label.add_theme_color_override("font_color", Color(0.6157, 0.6471, 0.6824, 1.0)) # Matches muted browser text.
		empty_label.text = "Select Or Inspect An Atom Or Ion" if state.game_mode == &"freeplay" else "Reaction Complete" if state.molecule_active else "Select An Atom To Inspect It" # Chooses the context-appropriate empty message.
		inspector_rows.add_child(empty_label) # Adds the message to the native inspector.
		return # Stops before building species rows.
	var charge: int = atom.protons - atom.electrons # Calculates formal charge.
	var mass_number: int = atom.protons + atom.neutrons # Calculates isotope mass number.
	_add_inspector_heading(_display_name(_isotope_label(atom)), ChemistryData.element_symbol(atom.protons) + ChemistryData.superscript_charge(charge)) # Displays isotope and notation heading.
	_add_inspector_row("Element", _display_name(ChemistryData.element_name(atom.protons))) # Displays official element name.
	_add_inspector_row("Atomic Number", str(atom.protons)) # Displays atomic number.
	_add_inspector_row("Protons", str(atom.protons)) # Displays proton count.
	_add_inspector_row("Neutrons", str(atom.neutrons)) # Displays neutron count.
	_add_inspector_row("Electrons", str(atom.electrons)) # Displays electron count.
	_add_inspector_row("Mass Number", str(mass_number)) # Displays isotope mass number.
	_add_inspector_row("Charge", "Neutral" if charge == 0 else ("+%d" % charge if charge > 0 else str(charge))) # Displays formal charge.

func refresh_requirement_ui() -> void: # Rebuilds guided requirement counters only when displayed values change.
	if state.game_mode != &"guided": # Clears counters outside guided campaign mode.
		_requirement_signature = "" # Invalidates cached guided signature.
		_clear_container(requirement_list) # Removes any stale guided rows.
		return # Leaves the hidden group empty.
	var rows: Array[Dictionary] = [] # Stores current grouped requirement progress.
	for requirement: Dictionary in campaign_system.requirement_groups(): # Evaluates each unique requested species.
		var valid_count: int = 0 # Counts exact world matches.
		for atom: AtomState in state.atoms: # Checks every live atom.
			if campaign_system.atom_matches(atom, String(requirement["atom_key"])): # Requires exact isotope and charge.
				valid_count += 1 # Adds one completed matching species.
		valid_count = mini(valid_count, int(requirement["count"])) # Caps display progress at the requested total.
		rows.append({"atom_key": requirement["atom_key"], "valid_count": valid_count, "count": requirement["count"]}) # Stores one display row.
	var signature_parts: Array[String] = [] # Builds a compact change signature.
	for row: Dictionary in rows: # Encodes every displayed count.
		signature_parts.append("%s:%d/%d" % [String(row["atom_key"]), int(row["valid_count"]), int(row["count"])]) # Adds one row signature.
	var signature: String = "%d|%s|%s" % [state.current_level_index, "|".join(signature_parts), "done" if state.molecule_active else "active"] # Includes level and completion state.
	if signature == _requirement_signature: # Avoids rebuilding identical native controls every frame.
		return # Leaves current rows untouched.
	_requirement_signature = signature # Caches the new displayed state.
	_clear_container(requirement_list) # Removes previous rows before rebuilding.
	for row: Dictionary in rows: # Builds one native HBox row per grouped requirement.
		var row_box: HBoxContainer = HBoxContainer.new() # Creates a native two-column row.
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Uses full sidebar width.
		var name_label: Label = Label.new() # Creates species name label.
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Pushes count to the right edge.
		name_label.text = _display_name(String(ChemistryData.ATOMS[String(row["atom_key"])]["label"])) # Displays isotope/ion label using native UI naming.
		var count_label: Label = Label.new() # Creates progress count label.
		count_label.text = "%d / %d" % [int(row["valid_count"]), int(row["count"])] # Displays completed versus required count.
		row_box.add_child(name_label) # Adds species name to the row.
		row_box.add_child(count_label) # Adds progress count to the row.
		requirement_list.add_child(row_box) # Adds the completed row to the requirement list.

func refresh_freeplay_ui() -> void: # Synchronizes manual reaction summary, button availability, and selection-mode labels.
	if state.game_mode != &"freeplay": # Avoids unnecessary updates outside freeplay.
		return # Leaves hidden native controls unchanged.
	freeplay_system.sanitize_selection() # Removes identifiers for atoms that no longer exist.
	var selected: Array[AtomState] = freeplay_system.selected_atoms() # Resolves live selected species.
	if selected.is_empty(): # Displays the empty selection state.
		freeplay_selection.text = "No Reactants Selected" # Matches the browser meaning using native title-style UI text.
	else: # Displays formula, count, and charge for current selection.
		var formula: String = ReactionLibrary.pretty_formula_from_ascii(ReactionLibrary.ascii_formula_from_atoms(selected)) # Formats selected composition.
		var charge: int = ReactionLibrary.total_charge(selected) # Calculates net formal charge.
		var charge_text: String = "Neutral Total" if charge == 0 else "Net Charge %s%d" % ["+" if charge > 0 else "", charge] # Formats charge summary.
		freeplay_selection.text = "%s\n%d Selected Species · %s" % [formula, selected.size(), charge_text] # Displays browser-equivalent selection summary.
	react_button.disabled = selected.size() < 2 or state.freeplay_reaction != null or state.freeplay_verifying # Enables reaction only for a valid-sized idle selection.
	clear_reactants_button.disabled = selected.is_empty() or state.freeplay_reaction != null or state.freeplay_verifying # Enables clear only when there is something to clear.
	react_select_button.disabled = state.freeplay_reaction != null or state.freeplay_verifying # Prevents changing selection mode while reaction/verification is active.
	react_select_button.button_pressed = state.freeplay_select_mode # Reflects selection mode using native toggle state.
	react_select_button.text = "Selecting Reactants" if state.freeplay_select_mode else "Select Reactants" # Displays current mode action label.

func populate_level_select() -> void: # Rebuilds the native campaign selector while respecting unlock state and information mode.
	level_select.clear() # Removes all previously generated level options.
	for index: int in campaign.size(): # Adds every generated campaign level in order.
		var entry: Dictionary = campaign[index] # Reads one level definition.
		var prefix: String = "%02d" % (index + 1) # Formats one-based level number.
		var text: String = "%s — %s" % [prefix, String(entry["formula"])] if state.game_mode == &"formula_only" else "%s — %s — %s" % [prefix, String(entry["formula"]), _display_name(String(entry["name"]))] # Applies formula-only information hiding.
		level_select.add_item(text, index) # Adds the native selector option using level index as item ID.
		level_select.set_item_disabled(index, index > state.unlocked_level) # Prevents selecting locked levels.
	level_select.select(clampi(state.current_level_index, 0, campaign.size() - 1)) # Keeps selector synchronized with active level.
	_last_level_select_index = level_select.selected # Updates the signal-free polling baseline.

func set_next_button_visible(visible: bool) -> void: # Updates native next-level progression visibility.
	next_button.visible = visible and state.game_mode != &"freeplay" # Never exposes campaign progression inside freeplay.

func save_progress() -> void: # Persists the highest unlocked campaign level to user storage.
	var config: ConfigFile = ConfigFile.new() # Allocates a small native configuration file.
	config.set_value("campaign", "unlocked_level", state.unlocked_level) # Stores the zero-based highest unlocked level.
	var error: Error = config.save(SAVE_PATH) # Writes progress atomically through Godot's user directory.
	if error != OK: # Reports persistence failure without interrupting gameplay.
		push_warning("Bohr Builder could not save campaign progress: %s" % error_string(error)) # Logs the native file error.

func reset_game() -> void: # Restores the current campaign level or clears the complete freeplay workspace.
	state.clear_world() # Clears simulation objects and transient interaction state.
	scrap_button.button_pressed = false # Reflects disabled scrap mode in native UI.
	scrap_button.text = "Scrap Mode" # Restores native action label.
	react_select_button.button_pressed = false # Reflects disabled reactant-selection mode.
	react_select_button.text = "Select Reactants" # Restores native action label.
	reset_button.text = "Clear Workspace" if state.game_mode == &"freeplay" else "Reset Level" # Preserves mode-specific reset meaning.
	set_next_button_visible(false) # Hides progression until the campaign target is formed again.
	_requirement_signature = "" # Forces guided counters to rebuild for the fresh world.
	set_status(_level_default_status(), 0.0) # Displays persistent mode/level guidance.
	refresh_requirement_ui() # Rebuilds guided requirement counters.
	refresh_inspector() # Restores the empty inspector.
	refresh_freeplay_ui() # Restores freeplay selection controls when applicable.
	workspace.queue_redraw() # Refreshes the cleared native world immediately.

func open_mode_overlay() -> void: # Pauses world interaction and shows the native three-mode chooser.
	state.pointer_down = false # Releases any continuous fire state.
	state.mode_prompt_open = true # Pauses simulation updates.
	mode_overlay.visible = true # Shows the native modal overlay.
	guided_mode_button.grab_focus() # Places keyboard/controller focus inside the modal immediately.

func _set_game_mode(mode: StringName) -> void: # Applies campaign-information rules or enters the open freeplay sandbox.
	if mode != &"guided" and mode != &"formula_only" and mode != &"freeplay": # Rejects unknown internal modes.
		return # Leaves current mode unchanged.
	state.game_mode = mode # Stores the selected native game mode.
	state.mode_prompt_open = false # Resumes world simulation.
	mode_overlay.visible = false # Hides the mode chooser.
	mode_badge.text = _display_name(String(mode)) # Displays the selected mode using native UI naming.
	var is_freeplay: bool = mode == &"freeplay" # Calculates freeplay visibility once.
	campaign_picker.visible = not is_freeplay # Hides level selector in freeplay.
	target_readout.visible = not is_freeplay # Hides campaign target in freeplay.
	campaign_level_group.visible = not is_freeplay # Hides campaign metadata in freeplay.
	freeplay_group.visible = is_freeplay # Shows manual reaction controls only in freeplay.
	requirement_group.visible = mode == &"guided" # Shows exact atom requirements only in guided mode.
	guided_level_details.visible = mode == &"guided" # Shows lesson/equation only in guided mode.
	target_name.visible = mode == &"guided" # Shows target chemical name only in guided mode.
	_requirement_signature = "" # Forces visibility-dependent requirement refresh.
	populate_level_select() # Applies formula-only versus guided selector text.
	_update_level_ui() # Refreshes campaign metadata and information hiding.
	reset_game() # Starts the selected mode with a clean workspace.
	workspace.grab_focus() # Returns keyboard/controller focus to construction after choosing a mode.

func _load_level(index: int) -> void: # Switches to an unlocked campaign level and restores a clean world.
	if state.game_mode == &"freeplay": # Ignores campaign changes while freeplay is active.
		return # Leaves freeplay untouched.
	state.current_level_index = clampi(index, 0, mini(state.unlocked_level, campaign.size() - 1)) # Prevents selecting locked or invalid levels.
	populate_level_select() # Synchronizes native selector and disabled options.
	_update_level_ui() # Refreshes target and guidance.
	reset_game() # Clears world state for the selected level.

func _update_level_ui() -> void: # Refreshes native campaign metadata while respecting information mode.
	if campaign.is_empty(): # Protects startup before generated data exists.
		return # Leaves placeholders unchanged.
	var entry: Dictionary = campaign_system.current_level() # Reads active campaign target.
	level_number.text = "Level %02d" % (state.current_level_index + 1) # Displays one-based level number.
	level_title.text = "Formula Challenge" if state.game_mode == &"formula_only" else _display_name(String(entry["title"])) # Preserves formula-only title hiding.
	level_progress.text = "%d / %d" % [state.current_level_index + 1, campaign.size()] # Displays current campaign progress.
	level_lesson.text = _sentence_case(String(entry["lesson"])) # Displays the same lesson content in native UI formatting.
	target_formula.text = String(entry["formula"]) # Displays target formula.
	target_name.text = _display_name(String(entry["name"])) # Displays guided chemical name.
	reaction_equation.text = String(entry["equation"]) # Displays guided reaction equation.
	requirement_hint.text = "Atoms Count Only When Proton, Neutron And Electron Totals Match The Requested Neutral Isotope." if state.current_level_index < 50 else "Ions Count Only When Proton, Neutron And Electron Totals Match The Requested Isotope And Ionic Charge." # Preserves neutral/ionic matching explanation.

func _level_default_status() -> String: # Returns persistent native guidance appropriate to the active mode and campaign position.
	if state.game_mode == &"freeplay": # Describes open sandbox flow.
		return "Freeplay — Build Any Element 1–118 Or Ion, Select Reactants Manually, Then Press React Selected" # Preserves browser guidance meaning.
	if state.game_mode == &"formula_only": # Describes hidden-recipe campaign flow.
		return "Target: %s — Work Out The Required Atoms And Build Them Anywhere In The Workspace" % String(campaign_system.current_level()["formula"]) # Preserves formula-only instruction.
	if state.current_level_index == 0: # Gives the dedicated first-level tutorial.
		return "Easy Start — Make Two Hydrogen Atoms: Fire A Proton To Start Each Nucleus, Then Capture One Electron On Each First Shell" # Preserves original tutorial content.
	if state.current_level_index == 50: # Gives the dedicated ion introduction.
		return "Ions Unlocked — Build The Listed Charged Atoms By Giving Them The Required Electron Totals" # Preserves ion introduction guidance.
	return "Build The Listed %s For %s Anywhere In The Workspace" % ["Ions" if String(campaign_system.current_level()["chemistry"]) == "ionic" else "Atoms", String(campaign_system.current_level()["formula"])] # Provides generic campaign guidance.

func _read_unlocked_level() -> int: # Restores the highest unlocked campaign level from native user storage.
	var config: ConfigFile = ConfigFile.new() # Allocates native configuration reader.
	var error: Error = config.load(SAVE_PATH) # Attempts to read prior progress.
	if error != OK: # Treats missing or unreadable progress as a fresh campaign.
		return 0 # Starts with only the opening level unlocked.
	return clampi(int(config.get_value("campaign", "unlocked_level", 0)), 0, maxi(0, campaign.size() - 1)) # Validates restored progression against current campaign length.

func _handle_mouse_button(event: InputEventMouseButton) -> void: # Routes mouse buttons between native workspace actions and native UI controls.
	var workspace_hit: bool = workspace.get_global_rect().has_point(event.position) # Tests whether the pointer lies over the workspace Control.
	if workspace_hit: # Handles pointer actions directly on the simulation surface.
		var local_position: Vector2 = workspace.get_global_transform_with_canvas().affine_inverse() * event.position # Converts viewport coordinates to workspace local coordinates.
		if workspace.local_point_is_world(local_position): # Ignores any letterbox margin.
			state.pointer_position = workspace.world_from_local(local_position) # Updates fixed world aim before applying the click.
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed: # Maps right-click to atom inspection.
				_inspect_atom_at_pointer() # Updates selected atom and native inspector.
				workspace.grab_focus() # Moves keyboard focus to the workspace after direct interaction.
				get_viewport().set_input_as_handled() # Prevents context behavior elsewhere.
				return # Stops mouse routing.
			if event.button_index == MOUSE_BUTTON_LEFT: # Maps left click/hold to contextual primary action.
				if event.pressed: # Handles start of click/hold.
					workspace.grab_focus() # Gives construction focus to the world.
					_perform_primary_action(true) # Fires, scraps, or toggles a reactant contextually.
				else: # Handles mouse-button release.
					_release_primary_action() # Ends continuous fire.
				get_viewport().set_input_as_handled() # Keeps native GUI from treating the world click as another action.
				return # Stops mouse routing.
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed: # Handles clicks on native buttons without connecting signals.
		var hovered: Control = get_viewport().gui_get_hovered_control() # Reads the deepest native control under the pointer.
		var actionable: Control = _find_actionable_control(hovered) # Resolves a known button ancestor if one exists.
		if actionable is OptionButton: # Leaves native OptionButton popup behavior intact.
			return # Selection changes are applied by process polling.
		if actionable is Button: # Handles any known native action button.
			var button: Button = actionable # Narrows the native control type.
			button.grab_focus() # Preserves native mouse focus behavior explicitly.
			_handle_button_action(button.name) # Performs the semantic button action directly.
			get_viewport().set_input_as_handled() # Prevents a second native button activation path.

func _handle_key_event(event: InputEventKey) -> void: # Handles keyboard shortcuts while preserving native focus semantics.
	if not event.pressed or event.echo: # Processes only distinct key presses here; held aiming is polled in process.
		if event.keycode == KEY_SPACE and not event.pressed: # Releases held keyboard fire on Space key-up.
			_release_primary_action() # Ends continuous firing.
		return # Ignores other releases and key-repeat events.
	if state.mode_prompt_open: # Traps keyboard interaction inside the native mode modal.
		if event.keycode == KEY_TAB or event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT or event.keycode == KEY_UP or event.keycode == KEY_DOWN: # Cycles among the three visible mode cards.
			_navigate_mode_focus(-1 if event.shift_pressed or event.keycode == KEY_LEFT or event.keycode == KEY_UP else 1) # Moves modal focus predictably.
			get_viewport().set_input_as_handled() # Prevents focus escaping behind the modal.
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE: # Activates the focused mode card.
			_activate_focused_control(true) # Applies selected mode.
			get_viewport().set_input_as_handled() # Prevents duplicate native activation.
		return # Blocks background shortcuts while modal is open.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads current native keyboard focus.
	if focus_owner is OptionButton: # Leaves level selector keyboard navigation native and isolated.
		return # Blocks global shortcuts exactly as browser select focus did.
	if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER: # Routes focused activation or workspace primary action.
		if focus_owner is Button: # Activates the focused native button.
			_handle_button_action(focus_owner.name) # Performs its semantic action directly.
		else: # Uses the workspace as the primary target otherwise.
			workspace.grab_focus() # Ensures arrow aiming and visible focus move to the world.
			_perform_primary_action(event.keycode == KEY_SPACE) # Holds fire for Space and uses a one-shot action for Enter.
		get_viewport().set_input_as_handled() # Prevents duplicate GUI key activation.
		return # Stops shortcut processing.
	if event.keycode == KEY_1: set_selected_particle(&"proton") # Maps number one to proton selection.
	elif event.keycode == KEY_2: set_selected_particle(&"neutron") # Maps number two to neutron selection.
	elif event.keycode == KEY_3: set_selected_particle(&"electron") # Maps number three to electron selection.
	elif event.keycode == KEY_I: _inspect_atom_at_pointer() # Maps I to atom inspection.
	elif event.keycode == KEY_X: _toggle_scrap_mode() # Maps X to scrap mode.
	elif event.keycode == KEY_F and state.game_mode == &"freeplay": _toggle_reactant_selection() # Maps F to freeplay selection mode.
	elif event.keycode == KEY_C and state.game_mode == &"freeplay": freeplay_system.clear_selection() # Maps C to clear selected reactants.
	elif event.keycode == KEY_R: reset_game() # Maps R to reset/clear workspace.
	elif event.keycode == KEY_M: open_mode_overlay() # Maps M to the mode chooser.
	elif event.keycode == KEY_Q: _cycle_particle(-1) # Maps Q to previous particle.
	elif event.keycode == KEY_E: _cycle_particle(1) # Maps E to next particle.
	elif event.keycode == KEY_BRACKETLEFT: _cycle_campaign_level(-1) # Maps left bracket to previous unlocked level.
	elif event.keycode == KEY_BRACKETRIGHT: _cycle_campaign_level(1) # Maps right bracket to next unlocked level.
	elif event.keycode == KEY_N: _context_progress_action() # Maps N to react or next level contextually.
	else: return # Leaves unrelated keys to native Controls.
	get_viewport().set_input_as_handled() # Prevents handled shortcuts from reaching another native control.

func _handle_controller_event(event: InputEvent) -> void: # Handles named Godot controller actions through the project's Input Map.
	if event.is_action_pressed(DPAD_NORTH): _navigate_focus(&"up") # Moves native UI focus upward.
	elif event.is_action_pressed(DPAD_SOUTH): _navigate_focus(&"down") # Moves native UI focus downward.
	elif event.is_action_pressed(DPAD_WEST): _navigate_focus(&"left") # Moves native UI focus left.
	elif event.is_action_pressed(DPAD_EAST): _navigate_focus(&"right") # Moves native UI focus right.
	elif event.is_action_pressed(BUTTON_A): _activate_focused_control(true) # Performs focused activation or primary workspace action.
	elif event.is_action_released(BUTTON_A): _activate_focused_control(false) # Releases held primary fire when applicable.
	elif event.is_action_pressed(BUTTON_B): _inspect_atom_at_pointer() # Inspects aimed atom.
	elif event.is_action_pressed(BUTTON_X): _toggle_scrap_mode() # Toggles scrap mode.
	elif event.is_action_pressed(BUTTON_Y) and state.game_mode == &"freeplay": _toggle_reactant_selection() # Toggles freeplay selection mode.
	elif event.is_action_pressed(BUTTON_START): open_mode_overlay() # Opens mode chooser.
	elif event.is_action_pressed(BUTTON_BACK): reset_game() # Resets current level/workspace.
	elif event.is_action_pressed(BUTTON_LB): _cycle_particle(-1) # Selects previous particle.
	elif event.is_action_pressed(BUTTON_RB): _cycle_particle(1) # Selects next particle.
	elif event.is_action_pressed(BUTTON_LT): _cycle_campaign_level(-1) # Selects previous unlocked level.
	elif event.is_action_pressed(BUTTON_RT): _cycle_campaign_level(1) # Selects next unlocked level.
	elif event.is_action_pressed(BUTTON_L3) and state.game_mode == &"freeplay": freeplay_system.clear_selection() # Clears manual reaction selection.
	elif event.is_action_pressed(BUTTON_R3): _context_progress_action() # Reacts or advances contextually.
	else: return # Ignores unrelated controller events.
	get_viewport().set_input_as_handled() # Prevents the same joypad event from activating built-in UI actions a second time.

func _process_aim_input(delta: float) -> void: # Applies held keyboard and analog-controller aiming in fixed simulation coordinates.
	if state.mode_prompt_open: # Disables world aiming behind the mode chooser.
		return # Leaves pointer unchanged.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads current native focus for keyboard arrow semantics.
	var keyboard_axis: Vector2 = Vector2.ZERO # Accumulates keyboard aim direction.
	if not (focus_owner is OptionButton): # Matches browser behavior that select controls consume keyboard shortcuts.
		keyboard_axis.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)) # Uses WASD horizontally from any non-selector focus.
		keyboard_axis.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)) # Uses WASD vertically from any non-selector focus.
		if focus_owner == workspace: # Adds arrow-key aiming only while the workspace owns focus.
			keyboard_axis.x += float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)) # Adds horizontal arrow aim.
			keyboard_axis.y += float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP)) # Adds vertical arrow aim.
	if keyboard_axis.length_squared() > 0.0: # Applies keyboard aim only while a direction is held.
		workspace.grab_focus() # Moves focus to the workspace like the browser keyboard layer.
		_move_aim(keyboard_axis, KEYBOARD_AIM_SPEED, delta) # Updates fixed-world pointer.
	var controller_axis: Vector2 = Input.get_vector(STICK_LEFT_WEST, STICK_LEFT_EAST, STICK_LEFT_NORTH, STICK_LEFT_SOUTH, 0.20) # Reads a circular-deadzone left-stick vector using Godot's recommended API.
	if controller_axis.length_squared() > 0.0001: # Applies analog aim only outside the deadzone.
		workspace.grab_focus() # Moves native focus to the world when the stick is used.
		_move_aim(controller_axis, CONTROLLER_AIM_SPEED, delta) # Updates fixed-world pointer proportionally to stick displacement.

func _move_aim(axis: Vector2, speed: float, delta: float) -> void: # Moves and clamps the fixed simulation aim point.
	var normalized_axis: Vector2 = axis.limit_length(1.0) # Prevents diagonal movement exceeding the intended speed.
	state.pointer_position += normalized_axis * speed * delta # Integrates aim movement.
	state.pointer_position.x = clampf(state.pointer_position.x, 8.0, ChemistryData.WORLD_SIZE.x - 8.0) # Constrains horizontal aim to the playable world.
	state.pointer_position.y = clampf(state.pointer_position.y, 8.0, ChemistryData.WORLD_SIZE.y - 82.0) # Keeps aim above the cannon floor just like the browser controller layer.

func _perform_primary_action(hold_fire: bool) -> void: # Performs fire, scrap, or reactant toggle depending on current workspace mode.
	if state.mode_prompt_open: # Blocks world actions behind the mode chooser.
		return # Leaves world unchanged.
	var atom: AtomState = physics.pick_atom_at(state.pointer_position) # Resolves any atom under current aim.
	if state.game_mode == &"freeplay" and state.freeplay_select_mode: # Uses primary action to toggle reactants while selecting.
		if atom != null and state.freeplay_reaction == null and not state.freeplay_verifying: # Requires an idle live atom.
			freeplay_system.toggle_reactant(atom) # Toggles the aimed species in the manual reaction set.
		return # Never fires while selection mode is active.
	if state.scrap_mode: # Uses primary action to remove atoms while scrapping.
		_scrap_atom(atom) # Removes the aimed atom when possible.
		return # Never fires while scrap mode is active.
	state.pointer_down = hold_fire # Enables continuous fire only for a held primary action.
	physics.fire_particle(float(Time.get_ticks_msec())) # Attempts the initial fixed-speed shot immediately.

func _release_primary_action() -> void: # Releases continuous primary fire.
	state.pointer_down = false # Stops frame-by-frame fire attempts.

func _inspect_atom_at_pointer() -> void: # Selects and displays the atom under current aim point.
	var atom: AtomState = physics.pick_atom_at(state.pointer_position) # Resolves topmost aimed atom.
	state.selected_atom_id = atom.id if atom != null else -1 # Stores selection or clears it when empty.
	refresh_inspector() # Rebuilds native inspector immediately.
	set_status("Inspecting %s" % _display_name(_isotope_label(atom)) if atom != null else "No Atom Under Aim") # Reports inspection result.

func _scrap_atom(atom: AtomState) -> void: # Removes one aimed atom when no reaction owns the world.
	if atom == null or state.reaction != null or state.freeplay_reaction != null or state.freeplay_verifying: # Rejects invalid or locked removal attempts.
		return # Leaves world state unchanged.
	for index: int in range(state.atoms.size() - 1, -1, -1): # Locates the atom by identifier.
		if state.atoms[index].id == atom.id: # Matches the aimed atom.
			state.atoms.remove_at(index) # Removes it from world state.
			break # Stops after the unique identifier is removed.
	state.freeplay_selected_ids.erase(atom.id) # Removes any manual selection reference.
	state.selected_atom_id = -1 # Clears inspector selection.
	set_status("Atom Scrapped") # Reports removal.
	refresh_inspector() # Restores empty inspector.
	refresh_freeplay_ui() # Updates selection summary after removal.

func _toggle_scrap_mode() -> void: # Toggles atom-removal mode and disables manual reactant selection.
	if state.reaction != null or state.freeplay_reaction != null or state.freeplay_verifying: # Blocks mode changes during locked interactions.
		return # Leaves current modes unchanged.
	state.scrap_mode = not state.scrap_mode # Toggles removal mode.
	state.freeplay_select_mode = false # Makes scrap and reactant-selection modes mutually exclusive.
	scrap_button.button_pressed = state.scrap_mode # Reflects active mode in native toggle styling.
	scrap_button.text = "Scrap Mode On" if state.scrap_mode else "Scrap Mode" # Displays explicit state.
	react_select_button.button_pressed = false # Clears freeplay selection toggle styling.
	react_select_button.text = "Select Reactants" # Restores freeplay selection action label.
	set_status("Select An Atom With The Primary Action To Remove It" if state.scrap_mode else "Scrap Mode Disabled") # Explains active removal behavior.
	workspace.grab_focus() # Returns controller/keyboard focus to aimed interaction.

func _toggle_reactant_selection() -> void: # Toggles freeplay manual reactant selection and disables scrap mode.
	if state.game_mode != &"freeplay" or state.freeplay_reaction != null or state.freeplay_verifying: # Restricts selection mode to idle freeplay.
		return # Leaves state unchanged.
	state.freeplay_select_mode = not state.freeplay_select_mode # Toggles manual selection behavior.
	state.scrap_mode = false # Makes selection and scrap modes mutually exclusive.
	scrap_button.button_pressed = false # Clears native scrap toggle styling.
	scrap_button.text = "Scrap Mode" # Restores scrap label.
	react_select_button.button_pressed = state.freeplay_select_mode # Reflects selection mode natively.
	react_select_button.text = "Selecting Reactants" if state.freeplay_select_mode else "Select Reactants" # Displays current selection state.
	set_status("Select Atoms Or Ions With The Primary Action" if state.freeplay_select_mode else _level_default_status()) # Explains manual selection behavior.
	workspace.grab_focus() # Returns controller/keyboard focus to aimed interaction.

func set_selected_particle(kind: StringName) -> void: # Changes the projectile loaded into the native particle cannon.
	if kind != &"proton" and kind != &"neutron" and kind != &"electron": # Rejects unknown particle names.
		return # Leaves current selection unchanged.
	state.selected_particle = kind # Stores the new cannon projectile type.
	_update_particle_buttons() # Reflects selection using native toggle states.

func _cycle_particle(direction: int) -> void: # Selects previous or next particle type cyclically.
	const ORDER: Array[StringName] = [&"proton", &"neutron", &"electron"] # Preserves browser particle order.
	var index: int = ORDER.find(state.selected_particle) # Finds current selection index.
	if index < 0: index = 0 # Falls back safely to proton.
	set_selected_particle(ORDER[posmod(index + direction, ORDER.size())]) # Applies wrapped particle selection.

func _cycle_campaign_level(direction: int) -> void: # Moves to an adjacent unlocked campaign level.
	if state.game_mode == &"freeplay" or state.mode_prompt_open: # Blocks campaign navigation in freeplay or modal state.
		return # Leaves current level unchanged.
	var max_level: int = mini(state.unlocked_level, campaign.size() - 1) # Calculates highest selectable level.
	var next_index: int = clampi(state.current_level_index + direction, 0, max_level) # Computes bounded adjacent level.
	if next_index != state.current_level_index: # Avoids unnecessary reset at an edge.
		_load_level(next_index) # Loads the adjacent unlocked level.

func _context_progress_action() -> void: # Reacts selected freeplay species or advances a completed campaign level.
	if state.game_mode == &"freeplay": # Uses context action for manual reaction in freeplay.
		if not react_button.disabled: # Requires the same native availability as clicking React Selected.
			freeplay_system.attempt_reaction() # Starts validation/reaction.
	elif next_button.visible: # Uses context action for campaign progression only after completion.
		_load_level(state.current_level_index + 1) # Advances to the newly unlocked next level.

func _handle_button_action(button_name: StringName) -> void: # Maps native Button node names to semantic game actions without signals.
	match button_name: # Dispatches known editor-defined controls.
		&"ModeButton": open_mode_overlay() # Opens mode chooser.
		&"ProtonButton": set_selected_particle(&"proton") # Loads proton.
		&"NeutronButton": set_selected_particle(&"neutron") # Loads neutron.
		&"ElectronButton": set_selected_particle(&"electron") # Loads electron.
		&"ReactSelectButton": _toggle_reactant_selection() # Toggles freeplay reactant selection.
		&"ClearReactantsButton": freeplay_system.clear_selection() # Clears selected freeplay species.
		&"ReactButton": freeplay_system.attempt_reaction() # Attempts a manual freeplay product.
		&"ScrapButton": _toggle_scrap_mode() # Toggles atom removal.
		&"ResetButton": reset_game() # Resets current mode workspace.
		&"NextButton": _load_level(state.current_level_index + 1) # Advances completed campaign level.
		&"GuidedModeButton": _set_game_mode(&"guided") # Enters guided campaign.
		&"FormulaModeButton": _set_game_mode(&"formula_only") # Enters formula-only campaign.
		&"FreeplayModeButton": _set_game_mode(&"freeplay") # Enters open sandbox.
		_: pass # Ignores unrecognized native buttons.

func _activate_focused_control(pressed: bool) -> void: # Performs controller/keyboard accept behavior on the currently focused native control.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() # Reads current native GUI focus.
	if not pressed: # Handles release edge for held workspace fire.
		if focus_owner == workspace: # Releases only when the workspace owns primary action.
			_release_primary_action() # Stops continuous fire.
		return # Ignores release for ordinary buttons.
	if state.mode_prompt_open: # Restricts activation to visible mode cards.
		if focus_owner is Button: # Activates whichever mode card owns focus.
			_handle_button_action(focus_owner.name) # Applies the selected game mode.
		else: # Restores focus if it was unexpectedly lost.
			guided_mode_button.grab_focus() # Returns to the first mode card.
		return # Blocks background activation.
	if focus_owner == workspace or focus_owner == null: # Uses primary world action when workspace or nothing owns focus.
		workspace.grab_focus() # Ensures visible focus belongs to the world.
		_perform_primary_action(true) # Starts contextual primary action with held-fire support.
		return # Stops GUI activation.
	if focus_owner is OptionButton: # Uses controller accept on level selector without requiring popup navigation.
		_cycle_campaign_level(1) # Advances to the next unlocked level.
		return # Stops further activation.
	if focus_owner is Button: # Activates any focused native action button.
		_handle_button_action(focus_owner.name) # Performs semantic action directly.

func _navigate_focus(direction: StringName) -> void: # Moves controller focus spatially between visible native UI controls.
	if state.mode_prompt_open: # Keeps D-pad focus trapped inside mode chooser.
		_navigate_mode_focus(-1 if direction == &"left" or direction == &"up" else 1) # Cycles mode cards based on navigation direction.
		return # Blocks background navigation.
	var controls: Array[Control] = _focusable_controls() # Builds current visible/focusable control set.
	if controls.is_empty(): # Handles unexpected empty native UI safely.
		return # Leaves focus unchanged.
	var active: Control = get_viewport().gui_get_focus_owner() # Reads current focus owner.
	if active == level_select and (direction == &"up" or direction == &"down"): # Gives level selector direct D-pad level cycling.
		_cycle_campaign_level(-1 if direction == &"up" else 1) # Changes adjacent unlocked level.
		return # Keeps focus on selector.
	if not controls.has(active): # Restores focus to the world if current owner is hidden or invalid.
		workspace.grab_focus() # Uses workspace as default native focus.
		return # Stops navigation after recovery.
	var source_rect: Rect2 = active.get_global_rect() # Reads current control screen rectangle.
	var source_center: Vector2 = source_rect.get_center() # Calculates spatial navigation origin.
	var best_control: Control = null # Stores the closest control in requested direction.
	var best_score: float = INF # Stores weighted primary/secondary distance.
	for candidate: Control in controls: # Evaluates every other visible focus target.
		if candidate == active: # Skips current focus owner.
			continue # Moves to next candidate.
		var delta: Vector2 = candidate.get_global_rect().get_center() - source_center # Calculates spatial offset.
		var primary: float = -delta.x if direction == &"left" else delta.x if direction == &"right" else -delta.y if direction == &"up" else delta.y # Projects offset onto requested direction.
		if primary <= 1.0: # Rejects controls not meaningfully in the requested direction.
			continue # Moves to next candidate.
		var secondary: float = absf(delta.y) if direction == &"left" or direction == &"right" else absf(delta.x) # Measures perpendicular distance.
		var score: float = primary + secondary * 0.55 # Matches browser spatial focus weighting.
		if score < best_score: # Chooses the closest directional candidate.
			best_score = score # Stores improved distance score.
			best_control = candidate # Stores improved focus target.
	if best_control != null: # Applies focus only when a directional target exists.
		best_control.grab_focus() # Moves native focus and allows ScrollContainer/Control focus visibility behavior.

func _navigate_mode_focus(direction: int) -> void: # Cycles focus among three native mode cards while the modal is open.
	var cards: Array[Button] = [guided_mode_button, formula_mode_button, freeplay_mode_button] # Stores modal focus order.
	var active: Control = get_viewport().gui_get_focus_owner() # Reads current modal focus.
	var index: int = cards.find(active) # Finds active card index.
	if index < 0: index = 0 # Falls back to the first card.
	cards[posmod(index + direction, cards.size())].grab_focus() # Applies wrapped modal focus movement.

func _focusable_controls() -> Array[Control]: # Returns visible enabled controls used by controller spatial navigation.
	var candidates: Array[Control] = [workspace, mode_button, level_select, proton_button, neutron_button, electron_button, react_select_button, clear_reactants_button, react_button, scrap_button, reset_button, next_button] # Defines semantic navigation targets.
	var available: Array[Control] = [] # Collects controls currently eligible for focus.
	for control: Control in candidates: # Filters the candidate list.
		if not control.is_visible_in_tree(): # Rejects hidden mode-specific controls.
			continue # Moves to next candidate.
		if control is BaseButton and (control as BaseButton).disabled: # Rejects disabled buttons.
			continue # Moves to next candidate.
		available.append(control) # Adds the usable focus target.
	return available # Returns current native focus graph candidates.

func _find_actionable_control(control: Control) -> Control: # Walks from the deepest hovered Control to a known actionable ancestor.
	var current: Node = control # Starts with the leaf hover target.
	while current != null and current != self: # Walks upward until root controller.
		if current == workspace or current is Button or current is OptionButton: # Recognizes native interaction surfaces.
			return current as Control # Returns the first actionable ancestor.
		current = current.get_parent() # Continues toward root.
	return null # Reports no custom action target.

func _poll_level_select() -> void: # Applies mouse/native selector changes without connecting an item-selected signal.
	if state.game_mode == &"freeplay" or state.mode_prompt_open or level_select.selected < 0: # Ignores inactive selector states.
		return # Leaves active campaign unchanged.
	if level_select.selected == _last_level_select_index: # Avoids repeated loads when selection has not changed.
		return # Leaves world state untouched.
	_last_level_select_index = level_select.selected # Stores the new native selection baseline.
	if level_select.selected <= state.unlocked_level: # Applies only an unlocked item.
		_load_level(level_select.selected) # Switches to the selected campaign target.
	else: # Restores current level if a locked item somehow becomes selected.
		level_select.select(state.current_level_index) # Reasserts valid active selection.

func _update_status_timeout() -> void: # Restores persistent default/completion feedback after temporary status messages expire.
	if _status_deadline_ms <= 0 or Time.get_ticks_msec() < _status_deadline_ms: # Leaves persistent or still-active messages unchanged.
		return # Defers restoration.
	_status_deadline_ms = 0 # Clears expiry state.
	if state.game_mode == &"freeplay": # Restores freeplay guidance after temporary feedback.
		status_label.text = _level_default_status() # Displays persistent sandbox guidance.
	elif state.molecule_active: # Restores completed campaign status after temporary feedback.
		status_label.text = "%s Formed — Level Complete" % String(campaign_system.current_level()["formula"]) # Displays persistent completion state.
	else: # Restores active campaign construction guidance.
		status_label.text = _level_default_status() # Displays persistent level guidance.

func _update_particle_buttons() -> void: # Reflects cannon particle selection using native toggle-button states.
	proton_button.button_pressed = state.selected_particle == &"proton" # Marks proton button selected when loaded.
	neutron_button.button_pressed = state.selected_particle == &"neutron" # Marks neutron button selected when loaded.
	electron_button.button_pressed = state.selected_particle == &"electron" # Marks electron button selected when loaded.

func _isotope_label(atom: AtomState) -> String: # Returns the most specific campaign isotope/ion label for a live atom.
	if atom == null: # Handles empty inspector calls defensively.
		return "" # Returns no label.
	for key: String in ChemistryData.ATOMS: # Searches every campaign definition.
		var definition: Dictionary = ChemistryData.ATOMS[key] # Reads one exact species definition.
		if atom.protons == int(definition["protons"]) and atom.neutrons == int(definition["neutrons"]) and atom.electrons == int(definition["electrons"]): # Matches exact particle totals.
			return String(definition["label"]) # Returns curated isotope/ion label.
	return "%s-%d" % [ChemistryData.element_name(atom.protons), atom.protons + atom.neutrons] # Falls back to element and mass number.

func _add_inspector_heading(name_text: String, notation: String) -> void: # Adds the native inspector's identity heading row.
	var row: HBoxContainer = HBoxContainer.new() # Creates native two-column heading.
	var name_label: Label = Label.new() # Creates isotope/name label.
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Pushes notation to the right edge.
	name_label.text = name_text # Displays formatted species identity.
	name_label.add_theme_font_size_override("font_size", 16) # Matches browser heading emphasis.
	var notation_label: Label = Label.new() # Creates symbol/charge notation label.
	notation_label.text = notation # Displays element symbol and superscript charge.
	notation_label.add_theme_color_override("font_color", Color(0.6157, 0.6471, 0.6824, 1.0)) # Matches muted browser notation.
	row.add_child(name_label) # Adds identity to heading.
	row.add_child(notation_label) # Adds notation to heading.
	inspector_rows.add_child(row) # Adds heading row to native inspector.

func _add_inspector_row(label_text: String, value_text: String) -> void: # Adds one native inspector property/value row.
	var row: HBoxContainer = HBoxContainer.new() # Creates native two-column property row.
	var name_label: Label = Label.new() # Creates property name label.
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Pushes value to right edge.
	name_label.text = label_text # Displays property name.
	name_label.add_theme_color_override("font_color", Color(0.6157, 0.6471, 0.6824, 1.0)) # Matches muted browser labels.
	var value_label: Label = Label.new() # Creates property value label.
	value_label.text = value_text # Displays current atom value.
	row.add_child(name_label) # Adds property name.
	row.add_child(value_label) # Adds property value.
	inspector_rows.add_child(row) # Adds row to native inspector.

func _clear_container(container: Container) -> void: # Removes dynamically generated native UI children immediately and safely.
	for child: Node in container.get_children(): # Reads every existing generated child.
		container.remove_child(child) # Detaches it immediately so layout no longer includes it this frame.
		child.queue_free() # Schedules native object cleanup at frame end.

func _display_name(value: String) -> String: # Converts internal browser identifiers to the project's requested UI naming format.
	return value.replace("_", " ").capitalize() # Replaces underscores and capitalizes every word.

func _sentence_case(value: String) -> String: # Converts browser lowercase instructional prose to native readable sentence casing.
	if value.is_empty(): # Handles an empty lesson safely.
		return value # Returns no text.
	return value.substr(0, 1).to_upper() + value.substr(1) # Capitalizes only the opening character while preserving chemistry text.
