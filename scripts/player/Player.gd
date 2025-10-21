extends CharacterBody2D
# Grid-following click-to-move (8-directional, least steps), smooth, exact tile-center landings.
# Godot 4.5 / GDScript

const TILE := 32
const HALF_TILE := TILE * 0.5

@export var move_speed: float = 240.0  # pixels/sec

var _path: PackedVector2Array = PackedVector2Array()  # world-space tile centers
var _current: Vector2 = Vector2.ZERO                  # current waypoint (world-space)
var _has_path: bool = false

func _enter_tree() -> void:
	# If the scene sets an initial position, we still ensure we land exactly on a tile.
	# Do it deferred to run AFTER parent/scene positions are finalized.
	call_deferred("_deferred_spawn_snap")

func _ready() -> void:
	_ensure_sprite()
	_ensure_collision()
	_ensure_camera()

func _deferred_spawn_snap() -> void:
	global_position = _snap_to_tile_center(global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_ws: Vector2 = _snap_to_tile_center(get_global_mouse_position())
		_set_destination(target_ws)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Pixel-snap the camera so tiles & grid align 1:1 with screen pixels.
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.global_position = cam.global_position.round()

	if not _has_path:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Move toward current waypoint without overshoot.
	var to: Vector2 = _current - global_position
	var dist: float = to.length()
	var step: float = move_speed * delta

	if dist <= step:
		# Arrived at this waypoint. Snap exactly, then advance.
		global_position = _current
		if _path.size() > 0:
			_path.remove_at(0)
		if _path.size() > 0:
			_current = _path[0]
		else:
			_has_path = false
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = to.normalized() * move_speed
	move_and_slide()

# ---------------- Pathing helpers ----------------

func _set_destination(target_ws: Vector2) -> void:
	# Build an 8-direction, least-steps path (maximally diagonal, then straight).
	var start_t: Vector2i = _world_to_tile(global_position)
	var goal_t:  Vector2i = _world_to_tile(target_ws)
	_path = _build_chebyshev_path(start_t, goal_t)   # world-space waypoints at tile centers
	_has_path = _path.size() > 0
	if _has_path:
		_current = _path[0]

# Chebyshev shortest path on a grid with diagonals allowed:
# Do min(|dx|,|dy|) diagonal steps, then finish remaining straight steps.
func _build_chebyshev_path(start_t: Vector2i, goal_t: Vector2i) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var t := start_t

	var dx: int = goal_t.x - t.x
	var dy: int = goal_t.y - t.y
	var sx: int = 0 if dx == 0 else (1 if dx > 0 else -1)
	var sy: int = 0 if dy == 0 else (1 if dy > 0 else -1)

	var n_diag: int = mini(abs(dx), abs(dy))
	var n_ax:   int = maxi(abs(dx), abs(dy)) - n_diag

	# 1) Diagonals
	for i in n_diag:
		t.x += sx
		t.y += sy
		pts.append(_tile_to_world(t))

	# 2) Straights (whichever axis still has remaining delta)
	if abs(dx) > abs(dy):
		for i in n_ax:
			t.x += sx
			pts.append(_tile_to_world(t))
	elif abs(dy) > abs(dx):
		for i in n_ax:
			t.y += sy
			pts.append(_tile_to_world(t))
	# if equal, n_ax == 0 and we’re done

	return pts

# --- conversions & snap ---

func _world_to_tile(p: Vector2) -> Vector2i:
	# Map world to tile index where centers are n*TILE + HALF_TILE
	return Vector2i(
		roundi((p.x - HALF_TILE) / TILE),
		roundi((p.y - HALF_TILE) / TILE)
	)

func _tile_to_world(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + HALF_TILE, t.y * TILE + HALF_TILE)

func _snap_to_tile_center(p: Vector2) -> Vector2:
	return _tile_to_world(_world_to_tile(p))

# ---------------- Node ensure (visuals & camera only) ----------------

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

func _ensure_camera() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		add_child(cam)
	cam.enabled = true
	cam.make_current()
