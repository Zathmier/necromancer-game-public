extends CharacterBody2D
# Obstacle-aware grid-following click-to-move (8-direction), exact tile-center landings,
# with a target marker that disappears on arrival.

const TILE := 32
const HALF_TILE := TILE * 0.5
const SEARCH_RADIUS_TILES := 96  # half-size of the temporary A* window

@export var move_speed: float = 240.0  # px/sec

var _path: PackedVector2Array = PackedVector2Array()  # world-space tile centers
var _current: Vector2 = Vector2.ZERO                  # current waypoint
var _has_path: bool = false

var _marker: Node2D = null  # click marker

func _enter_tree() -> void:
	# Snap after parent/scene positions are finalized.
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
		_show_marker(target_ws)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Pixel-snap the camera so tiles & grid stay aligned to pixels.
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
		# Arrived exactly at this waypoint; advance to the next.
		global_position = _current
		if _path.size() > 0:
			_path.remove_at(0)
		if _path.size() > 0:
			_current = _path[0]
		else:
			_has_path = false
			_hide_marker()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = to.normalized() * move_speed
	move_and_slide()

# ---------------- Pathing ----------------

func _set_destination(target_ws: Vector2) -> void:
	var start_t: Vector2i = _world_to_tile(global_position)
	var goal_t:  Vector2i = _world_to_tile(target_ws)
	_path = _build_astar_path(start_t, goal_t)
	_has_path = _path.size() > 0
	if _has_path:
		_current = _path[0]

func _build_astar_path(start_t: Vector2i, goal_t: Vector2i) -> PackedVector2Array:
	var world := get_tree().current_scene
	var gen := world.find_child("WorldGen", true, false)
	if gen == null:
		return _build_chebyshev_path(start_t, goal_t)  # fallback

	# Window bounds (tile coords)
	var minx: int = min(start_t.x, goal_t.x) - SEARCH_RADIUS_TILES
	var miny: int = min(start_t.y, goal_t.y) - SEARCH_RADIUS_TILES
	var maxx: int = max(start_t.x, goal_t.x) + SEARCH_RADIUS_TILES
	var maxy: int = max(start_t.y, goal_t.y) + SEARCH_RADIUS_TILES
	var origin_t := Vector2i(minx, miny)
	var size := Vector2i(maxx - minx + 1, maxy - miny + 1)

	# Create grid (local coords [0..w-1, 0..h-1])
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.cell_size = Vector2(TILE, TILE)
	grid.offset = Vector2(origin_t.x * TILE + HALF_TILE, origin_t.y * TILE + HALF_TILE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS

	# IMPORTANT: initialize before using set_point_solid()
	grid.update()

	# Mark solids, then update again to apply changes
	for y in range(size.y):
		for x in range(size.x):
			var tx := origin_t.x + x
			var ty := origin_t.y + y
			if not _is_walkable(gen, tx, ty):
				grid.set_point_solid(Vector2i(x, y), true)

	grid.update()  # apply solid map

	var from := Vector2i(start_t.x - origin_t.x, start_t.y - origin_t.y)
	var to   := Vector2i(goal_t.x  - origin_t.x, goal_t.y  - origin_t.y)
	if not grid.is_in_boundsv(from) or not grid.is_in_boundsv(to):
		return PackedVector2Array()

	var pts: PackedVector2Array = grid.get_point_path(from, to)
	return pts  # already world coordinates (thanks to cell_size + offset)

# Fallback path (diagonals first, then straight) if A* can’t be built
func _build_chebyshev_path(start_t: Vector2i, goal_t: Vector2i) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var t := start_t
	var dx: int = goal_t.x - t.x
	var dy: int = goal_t.y - t.y
	var sx: int = 0 if dx == 0 else (1 if dx > 0 else -1)
	var sy: int = 0 if dy == 0 else (1 if dy > 0 else -1)
	var n_diag: int = min(abs(dx), abs(dy))
	var n_ax:   int = max(abs(dx), abs(dy)) - n_diag
	for i in range(n_diag):
		t.x += sx; t.y += sy; pts.append(_tile_to_world(t))
	if abs(dx) > abs(dy):
		for i in range(n_ax):
			t.x += sx; pts.append(_tile_to_world(t))
	elif abs(dy) > abs(dx):
		for i in range(n_ax):
			t.y += sy; pts.append(_tile_to_world(t))
	return pts

func _is_walkable(gen: Node, tx: int, ty: int) -> bool:
	# Uses your WorldGen.get_biome(); blocks 'water' and 'rock' by default
	if gen.has_method("get_biome"):
		var biome: String = gen.call("get_biome", tx, ty)
		return biome != "water" and biome != "rock"
	return true

# ---------------- Conversions & snap ----------------

func _world_to_tile(p: Vector2) -> Vector2i:
	return Vector2i(
		roundi((p.x - HALF_TILE) / TILE),
		roundi((p.y - HALF_TILE) / TILE)
	)

func _tile_to_world(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + HALF_TILE, t.y * TILE + HALF_TILE)

func _snap_to_tile_center(p: Vector2) -> Vector2:
	return _tile_to_world(_world_to_tile(p))

# ---------------- Click marker ----------------

func _show_marker(pos: Vector2) -> void:
	_hide_marker()
	var m := Node2D.new()
	m.name = "ClickMarker"
	m.z_index = 1000
	m.position = pos
	m.set_script(preload("res://scripts/debug/TargetMarker.gd"))
	add_child(m)
	_marker = m

func _hide_marker() -> void:
	if _marker and is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null

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
