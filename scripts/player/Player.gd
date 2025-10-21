extends CharacterBody2D
# Godot 4.5 — code-only click-to-move

var agent: NavigationAgent2D
@export var move_speed: float = 240.0
@export var accel: float = 12.0

func _ready() -> void:
	# Ensure NavigationAgent2D child exists
	agent = get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if agent == null:
		agent = NavigationAgent2D.new()
		agent.name = "NavigationAgent2D"
		add_child(agent)

	# Agent tuning
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0
	agent.avoidance_enabled = false

	# Make sure there's a nav region to walk on (dev convenience)
	_ensure_nav_region_for_testing()

	# Console commands (dev helpers)
	if Engine.is_editor_hint() == false:
		_register_console_cmds()

func _unhandled_input(event: InputEvent) -> void:
	# Left-click sets destination
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target := get_global_mouse_position()
		agent.set_target_position(target)
		Bus.send_output("moving to (%.1f, %.1f)" % [target.x, target.y])
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if agent.is_navigation_finished():
		# soft stop
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
		move_and_slide()
		return

	var next := agent.get_next_path_position()
	var dir := (next - global_position)
	if dir.length() > 0.001:
		var desired := dir.normalized() * move_speed
		velocity = velocity.lerp(desired, clamp(accel * delta, 0.0, 1.0))
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)

	move_and_slide()

# ---------------- helpers ----------------

func _ensure_nav_region_for_testing() -> void:
	# If there is no NavigationRegion2D in the current scene, create a big one.
	var root := get_tree().current_scene
	if root == null: return
	if root.find_child("AutoNav", true, false) != null:
		return

	# Build a simple rectangle polygon covering the viewport
	var vp := get_viewport_rect().size
	var poly := NavigationPolygon.new()
	var outline := PackedVector2Array([
		Vector2(0, 0),
		Vector2(vp.x, 0),
		Vector2(vp.x, vp.y),
		Vector2(0, vp.y),
	])
	poly.add_outline(outline)
	poly.make_polygons_from_outlines()

	var region := NavigationRegion2D.new()
	region.name = "AutoNav"
	region.navigation_polygon = poly
	root.add_child(region)
	region.owner = root  # so it appears in the tree when running in editor

func _register_console_cmds() -> void:
	# where  -> prints player coords
	ConsoleRouter.register_cmd("where", func(_a):
		Bus.send_output("pos = (%.1f, %.1f)" % [global_position.x, global_position.y])
	, "Show player position")

	# speed N -> set move speed
	ConsoleRouter.register_cmd("speed", func(a):
		if a.size() < 1:
			Bus.send_output("usage: speed <value>"); return
		var v := float(a[0])
		move_speed = max(10.0, v)
		Bus.send_output("move_speed = %.1f" % move_speed)
	, "Set move speed")

	# goto X Y -> move to world coords
	ConsoleRouter.register_cmd("goto", func(a):
		if a.size() < 2:
			Bus.send_output("usage: goto <x> <y>"); return
		var tgt := Vector2(float(a[0]), float(a[1]))
		agent.set_target_position(tgt)
		Bus.send_output("goto (%.1f, %.1f)" % [tgt.x, tgt.y])
	, "Move to position")
