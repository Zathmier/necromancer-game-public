extends CharacterBody2D
# Godot 4.5 — code-only click-to-move, self-building visuals + physics

var agent: NavigationAgent2D
@export var move_speed: float = 240.0
@export var accel: float = 12.0

func _ready() -> void:
	_ensure_sprite()
	_ensure_collision()
	_ensure_agent()
	_ensure_camera()
	_ensure_nav_region_for_testing()
	if not Engine.is_editor_hint():
		_register_console_cmds()

const TILE := 32
const HALF_TILE := TILE * 0.5

func _snap_to_tile_center(p: Vector2) -> Vector2:
	return Vector2(round(p.x / TILE) * TILE + HALF_TILE,
				   round(p.y / TILE) * TILE + HALF_TILE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target := _snap_to_tile_center(get_global_mouse_position())
		agent.set_target_position(target)
		Bus.send_output("moving to (%.1f, %.1f)" % [target.x, target.y])
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if agent.is_navigation_finished():
		# Ease into exact center of the nearest tile to prevent tiny residual drift
		var snap := _snap_to_tile_center(global_position)
		global_position = global_position.lerp(snap, clamp(10.0 * delta, 0.0, 1.0))
		velocity = Vector2.ZERO
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

# ---- ensure helpers ----
func _ensure_sprite() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		spr = Sprite2D.new()
		spr.name = "Sprite2D"
		add_child(spr)
	if spr.texture == null:
		var tex: Texture2D = preload("res://icon.svg")
		spr.texture = tex
		spr.centered = true
		spr.scale = Vector2(0.25, 0.25)

func _ensure_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	if col.shape == null:
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape

func _ensure_agent() -> void:
	agent = get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if agent == null:
		agent = NavigationAgent2D.new()
		agent.name = "NavigationAgent2D"
		add_child(agent)
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0
	agent.avoidance_enabled = false

func _ensure_camera() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		add_child(cam)
	cam.enabled = true
	cam.make_current()

var _auto_nav: NavigationRegion2D = null  # add this near the top with your vars

func _ensure_nav_region_for_testing() -> void:
	var root := get_tree().current_scene
	if root == null:
		return

	# Reuse if it exists
	_auto_nav = root.find_child("AutoNav", true, false) as NavigationRegion2D
	if _auto_nav != null:
		return

	# Build a HUGE rectangle so you can move anywhere during dev.
	var R := 20000.0  # 20k px in each direction (~625 tiles @ 32px)
	var poly := NavigationPolygon.new()
	poly.add_outline(PackedVector2Array([
		Vector2(-R, -R),
		Vector2( R, -R),
		Vector2( R,  R),
		Vector2(-R,  R),
	]))
	poly.make_polygons_from_outlines()  # lightweight dev triangulation

	var region := NavigationRegion2D.new()
	region.name = "AutoNav"
	region.navigation_polygon = poly

	_auto_nav = region
	call_deferred("_add_nav_region_deferred", root, region)

func _add_nav_region_deferred(root: Node, region: NavigationRegion2D) -> void:
	if is_instance_valid(root) and region.get_parent() == null:
		root.add_child(region)
	_auto_nav = region

# ---- console cmds ----
func _register_console_cmds() -> void:
	ConsoleRouter.register_cmd("where", func(_a):
		Bus.send_output("pos = (%.1f, %.1f)" % [global_position.x, global_position.y])
	, "Show player position")

	ConsoleRouter.register_cmd("speed", func(a):
		if a.size() < 1: Bus.send_output("usage: speed <value>"); return
		move_speed = max(10.0, float(a[0]))
		Bus.send_output("move_speed = %.1f" % move_speed)
	, "Set move speed")

	ConsoleRouter.register_cmd("goto", func(a):
		if a.size() < 2: Bus.send_output("usage: goto <x> <y>"); return
		var tgt := _snap_to_tile_center(Vector2(float(a[0]), float(a[1])))
		agent.set_target_position(tgt)
		Bus.send_output("goto (%.1f, %.1f)" % [tgt.x, tgt.y])
		, "Move to position")
