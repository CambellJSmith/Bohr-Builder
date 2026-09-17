class_name BohrResponsiveLayout # Adapts the native interface to the real window size without changing simulation coordinates.
extends Node # Runs independently from gameplay systems and does not use signals.

const COMPACT_WIDTH: float = 1180.0 # Starts reducing fixed UI widths before the original desktop layout becomes cramped.
const NARROW_WIDTH: float = 760.0 # Switches the workspace and sidebar into a vertical stack on genuinely narrow windows.
const TINY_WIDTH: float = 620.0 # Applies the tightest spacing and header simplification for very narrow windows.
const MIN_WORKSPACE_WIDTH: float = 260.0 # Keeps the interactive world large enough to remain usable.
const MIN_WORKSPACE_HEIGHT: float = 240.0 # Keeps the interactive world large enough vertically on short windows.

var _root: Control = null # References the active Bohr Builder root once its scene is ready.
var _app_margin: MarginContainer = null # Controls responsive outer padding.
var _app_shell: VBoxContainer = null # Controls vertical spacing between the header and workspace.
var _top_bar: HBoxContainer = null # Holds title and campaign header content.
var _title_block: VBoxContainer = null # Holds the application title and eyebrow.
var _level_header: HBoxContainer = null # Holds mode, level, and target readouts.
var _mode_readout: VBoxContainer = null # Holds current mode controls.
var _campaign_picker: VBoxContainer = null # Holds the level selector.
var _level_select: OptionButton = null # Selects the current campaign level.
var _target_readout: VBoxContainer = null # Holds target formula and name.
var _target_name: Label = null # Displays the guided target name.
var _canvas_panel: Panel = null # Contains the native simulation workspace.
var _status_banner: PanelContainer = null # Displays status text over the workspace.
var _sidebar: VBoxContainer = null # Holds campaign, particle, inspector, and action panels.
var _input_hint: Label = null # Holds the verbose multi-input help text.
var _particle_buttons: Array[Button] = [] # Stores the three particle-selection controls.
var _mode_panel: PanelContainer = null # Holds the opening mode chooser.
var _mode_buttons: Array[Button] = [] # Stores all three mode-choice controls.
var _workspace_box: BoxContainer = null # Replaces the fixed horizontal workspace row with a switchable box container.
var _mode_box: BoxContainer = null # Replaces the fixed horizontal mode row with a responsive box container.
var _sidebar_scroll: ScrollContainer = null # Adds vertical scrolling when sidebar content exceeds the available height.
var _last_size: Vector2 = Vector2(-1.0, -1.0) # Avoids recalculating layout every frame when the window is unchanged.

func _ready() -> void: # Enables lightweight polling because the project intentionally avoids signal-based architecture.
	set_process(true) # Watches for the game scene and real window-size changes.

func _process(_delta: float) -> void: # Binds the current scene and reapplies responsive rules only when necessary.
	var scene: Node = get_tree().current_scene # Resolves the currently running main scene.
	if scene == null or not scene.is_node_ready(): # Waits until all controller @onready references have resolved.
		return # Avoids restructuring the scene before gameplay initialization is complete.
	if _root == null or not is_instance_valid(_root) or _root != scene: # Detects first bind or a scene replacement.
		if scene.name != "Bohr Builder" or not scene is Control: # Ignores unrelated scenes.
			_root = null # Clears any stale root reference.
			return # Leaves non-game scenes untouched.
		_bind_scene(scene as Control) # Captures controls and installs responsive wrapper containers.
	if _root.size != _last_size: # Recalculates only after an actual logical window-size change.
		_last_size = _root.size # Remembers the new available UI size.
		_apply_layout() # Applies responsive sizes, spacing, orientation, and visibility.

func _bind_scene(scene_root: Control) -> void: # Captures the native interface after its controller has finished normal initialization.
	_root = scene_root # Retains the active game root.
	_app_margin = _root.get_node("AppMargin") as MarginContainer # Captures outer padding.
	_app_shell = _root.get_node("AppMargin/AppShell") as VBoxContainer # Captures main vertical layout.
	_top_bar = _root.get_node("AppMargin/AppShell/TopBar") as HBoxContainer # Captures the original desktop top bar.
	_title_block = _root.get_node("AppMargin/AppShell/TopBar/TitleBlock") as VBoxContainer # Captures application title content.
	_level_header = _root.get_node("AppMargin/AppShell/TopBar/LevelHeader") as HBoxContainer # Captures current campaign header.
	_mode_readout = _root.get_node("AppMargin/AppShell/TopBar/LevelHeader/ModeReadout") as VBoxContainer # Captures mode controls.
	_campaign_picker = _root.get_node("AppMargin/AppShell/TopBar/LevelHeader/CampaignPicker") as VBoxContainer # Captures campaign selector container.
	_level_select = _root.get_node("AppMargin/AppShell/TopBar/LevelHeader/CampaignPicker/LevelSelect") as OptionButton # Captures campaign selector itself.
	_target_readout = _root.get_node("AppMargin/AppShell/TopBar/LevelHeader/TargetReadout") as VBoxContainer # Captures target summary.
	_target_name = _root.get_node("AppMargin/AppShell/TopBar/LevelHeader/TargetReadout/TargetName") as Label # Captures optional guided target name.
	var original_workspace_layout: HBoxContainer = _root.get_node("AppMargin/AppShell/WorkspaceLayout") as HBoxContainer # Captures the fixed desktop workspace row before replacing it.
	_canvas_panel = original_workspace_layout.get_node("CanvasPanel") as Panel # Captures the simulation panel before restructuring.
	_sidebar = original_workspace_layout.get_node("Sidebar") as VBoxContainer # Captures sidebar before restructuring.
	_status_banner = _canvas_panel.get_node("StatusBanner") as PanelContainer # Captures the overlaid status banner.
	_input_hint = _sidebar.get_node("ParticleGroup/Margin/Content/InputHint") as Label # Captures the verbose input help text.
	_particle_buttons = [ # Stores particle buttons so their minimum widths can collapse with the sidebar.
		_sidebar.get_node("ParticleGroup/Margin/Content/ParticleGrid/ProtonButton") as Button, # Captures proton control.
		_sidebar.get_node("ParticleGroup/Margin/Content/ParticleGrid/NeutronButton") as Button, # Captures neutron control.
		_sidebar.get_node("ParticleGroup/Margin/Content/ParticleGrid/ElectronButton") as Button, # Captures electron control.
	] # Completes particle-button cache.
	_mode_panel = _root.get_node("ModeOverlay/Center/ModePanel") as PanelContainer # Captures opening mode panel.
	var original_mode_grid: HBoxContainer = _root.get_node("ModeOverlay/Center/ModePanel/ModeMargin/ModeContent/ModeGrid") as HBoxContainer # Captures fixed mode button row.
	_mode_buttons = [ # Stores mode controls before their parent is replaced.
		original_mode_grid.get_node("GuidedModeButton") as Button, # Captures guided mode.
		original_mode_grid.get_node("FormulaModeButton") as Button, # Captures formula-only mode.
		original_mode_grid.get_node("FreeplayModeButton") as Button, # Captures freeplay mode.
	] # Completes mode-button cache.
	_workspace_box = _replace_box_container(original_workspace_layout, "Responsive Workspace Layout") # Installs a box whose orientation can change at runtime.
	_mode_box = _replace_box_container(original_mode_grid, "Responsive Mode Grid") # Installs a switchable mode-choice box.
	_install_sidebar_scroll() # Makes all sidebar controls reachable on short windows and via controller focus.
	_last_size = Vector2(-1.0, -1.0) # Forces one complete layout pass after restructuring.

func _replace_box_container(original: BoxContainer, replacement_name: String) -> BoxContainer: # Replaces fixed HBox/VBox subclasses with a runtime-switchable BoxContainer.
	var parent_node: Node = original.get_parent() # Retains the original container parent.
	var child_index: int = original.get_index() # Retains original ordering within the parent container.
	var replacement: BoxContainer = BoxContainer.new() # Creates a native box whose vertical property can be changed at runtime.
	replacement.name = replacement_name # Gives the runtime node a readable scene-tree name.
	replacement.size_flags_horizontal = original.size_flags_horizontal # Preserves horizontal sizing behavior.
	replacement.size_flags_vertical = original.size_flags_vertical # Preserves vertical sizing behavior.
	replacement.size_flags_stretch_ratio = original.size_flags_stretch_ratio # Preserves proportional expansion.
	replacement.alignment = original.alignment # Preserves original child alignment.
	replacement.add_theme_constant_override("separation", original.get_theme_constant("separation")) # Preserves existing spacing until responsive rules override it.
	parent_node.add_child(replacement) # Adds replacement before moving existing child controls.
	parent_node.move_child(replacement, child_index) # Places replacement exactly where the original container lived.
	var children: Array[Node] = original.get_children() # Snapshots children because they will be moved during iteration.
	for child: Node in children: # Reparents every existing UI control without recreating it.
		original.remove_child(child) # Detaches the control from the obsolete fixed-orientation container.
		replacement.add_child(child) # Attaches the same control to the responsive container.
	original.queue_free() # Removes the now-empty original container after the current frame.
	return replacement # Returns the responsive replacement for later orientation changes.

func _install_sidebar_scroll() -> void: # Wraps the existing sidebar in a native ScrollContainer without changing controller references.
	var parent_box: BoxContainer = _sidebar.get_parent() as BoxContainer # Resolves the new responsive workspace container.
	var child_index: int = _sidebar.get_index() # Retains the sidebar's position after the workspace panel.
	parent_box.remove_child(_sidebar) # Temporarily detaches the existing sidebar control.
	_sidebar_scroll = ScrollContainer.new() # Creates native vertical scrolling for constrained heights.
	_sidebar_scroll.name = "Sidebar Scroll" # Gives the runtime node a readable scene-tree name.
	_sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED # Prevents unwanted sideways scrolling.
	_sidebar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO # Shows vertical scrolling only when content actually overflows.
	_sidebar_scroll.follow_focus = true # Keeps keyboard/controller-focused controls visible automatically.
	_sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL # Uses the full workspace height on desktop layouts.
	parent_box.add_child(_sidebar_scroll) # Adds the scrolling viewport to the workspace layout.
	parent_box.move_child(_sidebar_scroll, child_index) # Restores the sidebar's original ordering.
	_sidebar_scroll.add_child(_sidebar) # Places all existing sidebar panels inside the scrolling viewport.
	_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Makes sidebar sections match the scroll viewport width.
	_sidebar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN # Keeps sidebar content at its natural height so overflow becomes scrollable.

func _apply_layout() -> void: # Applies responsive rules for the currently available native window dimensions.
	if _root == null or _workspace_box == null or _sidebar_scroll == null: # Guards against incomplete scene binding.
		return # Leaves layout unchanged until all responsive components exist.
	var viewport_size: Vector2 = _root.size # Reads actual logical window dimensions because stretch mode is disabled.
	var compact: bool = viewport_size.x < COMPACT_WIDTH # Detects reduced-width desktop or split-screen windows.
	var narrow: bool = viewport_size.x < NARROW_WIDTH # Detects windows that need a vertical workspace/sidebar stack.
	var tiny: bool = viewport_size.x < TINY_WIDTH # Detects the tightest header presentation.
	var outer_margin: int = 8 if narrow else 12 if compact else 18 # Reduces dead space as available width decreases.
	_app_margin.add_theme_constant_override("margin_left", outer_margin) # Applies responsive left padding.
	_app_margin.add_theme_constant_override("margin_top", outer_margin) # Applies responsive top padding.
	_app_margin.add_theme_constant_override("margin_right", outer_margin) # Applies responsive right padding.
	_app_margin.add_theme_constant_override("margin_bottom", outer_margin) # Applies responsive bottom padding.
	_app_shell.add_theme_constant_override("separation", 8 if compact else 14) # Tightens vertical spacing on smaller windows.
	_top_bar.add_theme_constant_override("separation", 10 if compact else 20) # Tightens header spacing before controls begin wrapping visually.
	_level_header.add_theme_constant_override("separation", 8 if compact else 18) # Reduces gaps between mode, level, and target controls.
	_title_block.visible = not tiny # Preserves maximum space for functional controls on very narrow windows.
	var header_available: float = maxf(360.0, viewport_size.x - float(outer_margin * 2)) # Computes usable header width.
	var picker_width: float = clampf(header_available * 0.22, 150.0, 230.0) # Scales campaign selector with available width.
	var target_width: float = clampf(header_available * 0.14, 96.0, 150.0) # Scales target readout with available width.
	var mode_width: float = clampf(header_available * 0.11, 88.0, 110.0) # Scales mode block with available width.
	_mode_readout.custom_minimum_size = Vector2(mode_width, 0.0) # Removes the previous fixed desktop width.
	_campaign_picker.custom_minimum_size = Vector2(picker_width, 0.0) # Lets campaign controls shrink naturally.
	_level_select.custom_minimum_size = Vector2(picker_width, 34.0 if compact else 36.0) # Keeps level selector usable while shrinking horizontally.
	_target_readout.custom_minimum_size = Vector2(target_width, 0.0) # Lets target summary participate in responsive sizing.
	_target_name.visible = not tiny # Hides only the redundant written target name at extremely narrow widths while formula remains visible.
	_workspace_box.vertical = narrow # Stacks world above sidebar on narrow windows and keeps desktop side-by-side otherwise.
	_workspace_box.add_theme_constant_override("separation", 8 if compact else 14) # Scales workspace/sidebar gap with window size.
	_canvas_panel.custom_minimum_size = Vector2(MIN_WORKSPACE_WIDTH, MIN_WORKSPACE_HEIGHT) # Removes the previous forced 800×600 desktop minimum.
	_canvas_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Gives remaining horizontal room to the simulation.
	_canvas_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL # Gives remaining vertical room to the simulation.
	_canvas_panel.size_flags_stretch_ratio = 1.65 if narrow else 1.0 # Favors the world over sidebar when stacked vertically.
	if narrow: # Configures the sidebar as a full-width lower pane.
		_sidebar_scroll.custom_minimum_size = Vector2(0.0, 180.0) # Reserves a useful scrollable control area without dominating the workspace.
		_sidebar_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Matches the full available window width.
		_sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL # Shares remaining vertical space with the world.
		_sidebar_scroll.size_flags_stretch_ratio = 1.0 # Gives sidebar a smaller share than the workspace.
		_sidebar.custom_minimum_size = Vector2(0.0, 0.0) # Allows sidebar sections to match any narrow viewport width.
	else: # Configures the sidebar as a responsive desktop column.
		var sidebar_width: float = clampf(viewport_size.x * 0.22, 220.0, 320.0) # Scales sidebar width instead of locking it at 290 pixels.
		_sidebar_scroll.custom_minimum_size = Vector2(sidebar_width, 0.0) # Gives the column a predictable responsive width.
		_sidebar_scroll.size_flags_horizontal = Control.SIZE_SHRINK_END # Leaves remaining width to the simulation panel.
		_sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL # Matches workspace height and scrolls internally when needed.
		_sidebar_scroll.size_flags_stretch_ratio = 1.0 # Restores neutral expansion weighting.
		_sidebar.custom_minimum_size = Vector2(sidebar_width, 0.0) # Keeps inner panel widths synchronized with the scroll viewport.
	for particle_button: Button in _particle_buttons: # Removes fixed eighty-two-pixel button widths that could overflow a narrow sidebar.
		particle_button.custom_minimum_size = Vector2(0.0, 54.0 if compact else 60.0) # Lets the GridContainer divide available width evenly.
	_input_hint.visible = viewport_size.y >= 620.0 or narrow # Hides verbose help only when a short desktop-height window needs the vertical room.
	_status_banner.anchor_left = 0.0 # Anchors status banner to the workspace's left edge.
	_status_banner.anchor_right = 1.0 # Anchors status banner to the workspace's right edge.
	_status_banner.anchor_top = 1.0 # Anchors status banner vertically to the bottom edge.
	_status_banner.anchor_bottom = 1.0 # Keeps status banner bottom-relative during resizing.
	_status_banner.offset_left = 12.0 # Preserves the original inner left inset.
	_status_banner.offset_right = -12.0 # Replaces the old fixed 760-pixel right edge with a true responsive inset.
	_status_banner.offset_top = -58.0 # Preserves original status height.
	_status_banner.offset_bottom = -12.0 # Preserves original bottom inset.
	var mode_width_limit: float = maxf(300.0, viewport_size.x - float(outer_margin * 2 + 24)) # Keeps the modal inside the actual window width.
	_mode_panel.custom_minimum_size = Vector2(minf(760.0, mode_width_limit), 0.0) # Removes the mode chooser's hard 760-pixel minimum on small displays.
	_mode_box.vertical = viewport_size.x < 700.0 # Stacks mode cards vertically when three readable columns no longer fit.
	_mode_box.add_theme_constant_override("separation", 8 if compact else 10) # Maintains consistent spacing in either orientation.
	for mode_button: Button in _mode_buttons: # Resizes all mode cards consistently.
		mode_button.custom_minimum_size = Vector2(0.0, 112.0 if _mode_box.vertical else 180.0) # Uses compact rows on narrow screens and original cards on desktop.
