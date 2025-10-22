# scripts/Grid.gd
# Godot 4.5 — World-anchored grid aligned to your TileMap's origin.
# Paste-ready. Attach to a Node2D under your *world* root (NOT under CanvasLayer/Camera/Player).

extends Node2D

@export var tile_size: int = 32                  # project contract: 32 px tiles
@export var chunk_tiles: int = 48                # project contract: 48×48 tiles per chunk
@export var tile_color: Color = Color(1, 1, 1, 0.25)
@export var chunk_color: Color = Color(1, 1, 1, 0.60)
@export var show_chunks: bool = true
@export var tilemap_path: NodePath               # <-- set this to your TileMap node

@onready var tilemap: TileMap = get_node_or_null(tilemap_path) as TileMap
var world_origin: Vector2 = Vector2.ZERO         # world-space position of TileMap cell (0,0)

func _ready() -> void:
	# ensure the grid draws in world space (ignores parent transforms) but still respects the canvas/camera.
	top_level = true
	global_position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	z_index = 4096
	_refresh_world_origin()
	_warn_if_in_canvas_layer()
	set_process(true)

func _process(_delta: float) -> void:
	# if your TileMap never moves, this is optional; safe to keep.
	_refresh_world_origin()
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	var aabb: Rect2 = _get_visible_world_aabb_px()
	var ts: int = max(tile_size, 1)

	# compute tile index range relative to the TileMap origin (not (0,0) world)
	var left: float = aabb.position.x - world_origin.x
	var top: float = aabb.position.y - world_origin.y
	var right: float = aabb.position.x + aabb.size.x - world_origin.x
	var bottom: float = aabb.position.y + aabb.size.y - world_origin.y

	var tx0: int = floori(left / float(ts))
	var ty0: int = floori(top / float(ts))
	var tx1: int = ceili(right / float(ts))
	var ty1: int = ceili(bottom / float(ts))

	# --- Tile lines (thin) ---
	for tx in range(tx0, tx1 + 1):
		var xw: float = world_origin.x + float(tx * ts)
		draw_line(Vector2(xw, world_origin.y + float(ty0 * ts)), Vector2(xw, world_origin.y + float(ty1 * ts)), tile_color, 1.0, false)

	for ty in range(ty0, ty1 + 1):
		var yw: float = world_origin.y + float(ty * ts)
		draw_line(Vector2(world_origin.x + float(tx0 * ts), yw), Vector2(world_origin.x + float(tx1 * ts), yw), tile_color, 1.0, false)

	# --- Chunk lines (bold) ---
	if show_chunks:
		var chunk_px: int = ts * chunk_tiles
		var cx0: int = floori(tx0 / chunk_tiles)
		var cy0: int = floori(ty0 / chunk_tiles)
		var cx1: int = ceili(tx1 / chunk_tiles)
		var cy1: int = ceili(ty1 / chunk_tiles)

		for cx in range(cx0, cx1 + 1):
			var xcw: float = world_origin.x + float(cx * chunk_px)
			draw_line(Vector2(xcw, world_origin.y + float(ty0 * ts)), Vector2(xcw, world_origin.y + float(ty1 * ts)), chunk_color, 1.0, false)

		for cy in range(cy0, cy1 + 1):
			var ycw: float = world_origin.y + float(cy * chunk_px)
			draw_line(Vector2(world_origin.x + float(tx0 * ts), ycw), Vector2(world_origin.x + float(tx1 * ts), ycw), chunk_color, 1.0, false)

# --- Public helpers (useful for console debug later) ---

func get_visible_tile_bounds() -> Rect2i:
	var aabb: Rect2 = _get_visible_world_aabb_px()
	var ts: int = max(tile_size, 1)

	var left: float = aabb.position.x - world_origin.x
	var top: float = aabb.position.y - world_origin.y
	var right: float = aabb.position.x + aabb.size.x - world_origin.x
	var bottom: float = aabb.position.y + aabb.size.y - world_origin.y

	var tx0: int = floori(left / float(ts))
	var ty0: int = floori(top / float(ts))
	var tx1: int = ceili(right / float(ts)) - 1
	var ty1: int = ceili(bottom / float(ts)) - 1
	return Rect2i(Vector2i(tx0, ty0), Vector2i(tx1 - tx0 + 1, ty1 - ty0 + 1))

func get_visible_chunk_bounds() -> Rect2i:
	var t: Rect2i = get_visible_tile_bounds()
	var cx0: int = floori(t.position.x / chunk_tiles)
	var cy0: int = floori(t.position.y / chunk_tiles)
	var cx1: int = floori((t.position.x + t.size.x - 1) / chunk_tiles)
	var cy1: int = floori((t.position.y + t.size.y - 1) / chunk_tiles)
	return Rect2i(Vector2i(cx0, cy0), Vector2i(cx1 - cx0 + 1, cy1 - cy0 + 1))

# --- Internals ---

func _refresh_world_origin() -> void:
	# anchor the grid to the TileMap's true (0,0) cell in WORLD space
	if tilemap:
		var local_zero: Vector2 = tilemap.map_to_local(Vector2i.ZERO)
		world_origin = tilemap.to_global(local_zero)
	else:
		world_origin = Vector2.ZERO

func _get_visible_world_aabb_px() -> Rect2:
	# Convert viewport rect (px) → world-space rect using inverse canvas transform.
	var vp := get_viewport()
	var rect_px: Vector2 = vp.get_visible_rect().size
	var ct: Transform2D = vp.get_canvas_transform()
	var inv: Transform2D = ct.affine_inverse()

	var tl: Vector2 = inv * Vector2.ZERO
	var br: Vector2 = inv * rect_px

	var top_left: Vector2 = Vector2(minf(tl.x, br.x), minf(tl.y, br.y))
	var bottom_right: Vector2 = Vector2(maxf(tl.x, br.x), maxf(tl.y, br.y))
	return Rect2(top_left, bottom_right - top_left)

func _warn_if_in_canvas_layer() -> void:
	var n: Node = self
	while n:
		if n is CanvasLayer:
			push_warning("Grid is inside a CanvasLayer — it will be screen-space and appear to 'follow' the camera. Re-parent Grid under your world root (same level as TileMap/Player).")
			return
		n = n.get_parent()
