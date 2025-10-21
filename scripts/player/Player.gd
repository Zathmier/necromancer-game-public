# res://scripts/player/Player.gd
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

	# Ensure Camera2D exists and follows
	_ensure_camera()

	# Dev convenience: ensure there is a walkable nav region
	_ensure_nav_region_for_testing()

	# Console commands (only in game)
	if not Engine.is_editor_hint():
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

func _ensure_camera() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		cam.enabled = true
		cam.zoom = Vector2.ONE  # keep 1:1 for now
		add_child(cam)
	cam.make_current()

func _ensure_nav_region_for_testing() -> void:
	var root := get_tree().current_scene
	if root == null: return
	if root.find_child("AutoNav", true, false) != null:
		return

	var vp := get_viewport_rect().size
	var poly := NavigationPolygon.new()
	poly.add_outline(PackedVector2Array([
		Vector2(0, 0),
		Vector2(vp.x, 0),
		Vector2(vp.x, vp.y),
		Vector2(0, vp.y),
	]))
	# Lightweight build (deprecated but fine for quick dev)
	poly.make_polygons_from_outlines()

	var region := NavigationRegion2D.new()
	region.name = "AutoNav"
	region.navigation_polygon = poly

	# Defer the add so we don't collide with scene setup
	call_deferred("_add_nav_region_deferred", root, region)

func _add_nav_region_deferred(root: Node, region: NavigationRegion2D) -> void:
	if is_instance_valid(root) and region.get_parent() == null:
		root.add_child(region)

func _register_console_cmds() -> void:
	ConsoleRouter.register_cmd("where", func(_a):
		Bus.send_output("pos = (%.1f, %.1f)" % [global_position.x, global_position.y])
	, "Show player position")

	ConsoleRouter.register_cmd("speed", func(a):
		if a.size() < 1:
			Bus.send_output("usage: speed <value>"); return
		move_speed = max(10.0, float(a[0]))
		Bus.send_output("move_speed = %.1f" % move_speed)
	, "Set move speed")

	ConsoleRouter.register_cmd("goto", func(a):
		if a.size() < 2:
			Bus.send_output("usage: goto <x> <y>"); return
		var tgt := Vector2(float(a[0]), float(a[1]))
		agent.set_target_position(tgt)
		Bus.send_output("goto (%.1f, %.1f)" % [tgt.x, tgt.y])
	, "Move to position")
