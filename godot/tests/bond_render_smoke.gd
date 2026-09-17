extends SceneTree # Runs the bond renderer in a real headless draw callback so runtime container typing is exercised.

class BondRenderProbe extends BohrWorkspace: # Reuses the production workspace renderer instead of duplicating its bond logic.
	var drew_once: bool = false # Prevents repeated smoke-test drawing while the quit request is processed.

	func _draw() -> void: # Executes only when Godot permits CanvasItem drawing calls.
		if drew_once: # Guards against an unexpected second draw notification.
			return # Leaves the already-tested frame unchanged.
		drew_once = true # Records that the production bond renderer is being exercised.
		_draw_bond_between(Vector2(40.0, 40.0), Vector2(160.0, 40.0), 1, 1.0) # Exercises a single bond.
		_draw_bond_between(Vector2(40.0, 90.0), Vector2(160.0, 90.0), 2, 1.0) # Exercises the two-offset double-bond path.
		_draw_bond_between(Vector2(40.0, 140.0), Vector2(160.0, 140.0), 3, 1.0) # Exercises the three-offset triple-bond path.
		get_tree().quit(0) # Reports success after all production bond paths run without a runtime error.

func _initialize() -> void: # Builds the minimum scene tree required for a valid Control draw notification.
	var probe: BondRenderProbe = BondRenderProbe.new() # Creates the production-workspace test subclass.
	probe.size = Vector2(200.0, 180.0) # Gives the CanvasItem a non-zero drawable area.
	root.add_child(probe) # Places the probe in the active viewport so Godot will issue draw notifications.
	probe.queue_redraw() # Requests the frame that executes the smoke-test bond calls.
