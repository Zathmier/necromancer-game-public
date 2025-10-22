# Grid.gd — Godot 4.5, pure world-anchored overlay (never follows player/camera)
# Paste-ready. Attach to a Node2D that lives under a static world root (NOT under Player/Camera).

extends Node2D

@export var tile_size: int = 32
@export var chunk_tiles: int = 48            # 48×48 tiles per chunk per project contract
@export var tile_color: Color = Color(1, 1, 1, 0.25)
@export var chunk_color: Color = Color(1, 1, 1, 0.6)
@export var show_chunks: bool = true

func _ready() -> void:
	# Belt-and-suspenders to guarantee world anchoring:
	top_level = true                          # ignore parent transforms entirely
	global_position = Vector2.ZERO            # draw-space origin = world origin
	rotation = 0.0
	scale = Vector2.ONE
	z_index = 4096                            # make sure lines render on top
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()                            # cheap enough; redraw every frame

func _draw() -> void:
	if not visible:
		return

	var aabb := _get_visible_world_aabb_px()
	var ts := max(tile_size, 1)

	var x0 := floori(aabb.position.x / ts)
	var y0 := floori(aabb.position.y / ts)
	var x1 := ceili((aabb.position.x + aabb.size.x) / ts)
	var y1 := ceili((aabb.position.y + aabb.size.y) / ts)

	# Tile grid (thin)
	for tx in range(x0, x1 + 1):
		var x := float(tx * ts)
		draw_line(Vector2(x, y0 * ts), Vector2(x, y1 * ts), tile_color, 1.0, false)
	for ty in range(y0, y1 + 1):
		var y := float(ty * ts)
		draw_line(Vector2(x0 * ts, y), Vector2(x1 * ts, y), tile_color, 1.0, false)

	# Chunk grid (bolder) — exact multiples of (tile_size * chunk_tiles), aligned to world (0,0)
	if show_chunks:
		var chunk_px := ts * chunk_tiles
		var cx0 := floori(x0 / chunk_tiles)
		var cy0 := floori(y0 / chunk_tiles)
		var cx1 := ceili(x1 / chunk_tiles)
		var cy1 := ceili(y1 / chunk_tiles)

		for cx in range(cx0, cx1 + 1):
			var x2 := float(cx * chunk_px)
			draw_line(Vector2(x2, y0 * ts), Vector2(x2, y1 * ts), chunk_color, 1.0, false)
		for cy in range(cy0, cy1 + 1):
			var y2 := float(cy * chunk_px)
			draw_line(Vector2(x0 * ts, y2), Vector2(x1 * ts, y2), chunk_color, 1.0, false)

# --- Public helpers (for console debugging we’ll wire next) ---

func get_visible_tile_bounds() -> Rect2i:
	var aabb := _get_visible_world_aabb_px()
	var ts := max(tile_size, 1)
	var tx0 := floori(aabb.position.x / ts)
	var ty0 := floori(aabb.position.y / ts)
	var tx1 := ceili((aabb.position.x + aabb.size.x) / ts) - 1
	var ty1 := ceili((aabb.position.y + aabb.size.y) / ts) - 1
	return Rect2i(Vector2i(tx0, ty0), Vector2i(tx1 - tx0 + 1, ty1 - ty0 + 1))

func get_visible_chunk_bounds() -> Rect2i:
	var t := get_visible_tile_bounds()
	var cx0 := floori(t.position.x / chunk_tiles)
	var cy0 := floori(t.position.y / chunk_tiles)
	var cx1 := floori((t.position.x + t.size.x - 1) / chunk_tiles)
	var cy1 := floori((t.position.y + t.size.y - 1) / chunk_tiles)
	return Rect2i(Vector2i(cx0, cy0), Vector2i(cx1 - cx0 + 1, cy1 - cy0 + 1))

# --- Internals ---

func _get_visible_world_aabb_px() -> Rect2:
	# Convert the on-screen rectangle into WORLD coordinates via the canvas transform.
	# Works for zoomed cameras and keeps the grid in true world-space.
	var vp := get_viewport()
	var rect_px := vp.get_visible_rect().size

	var ct := vp.get_canvas_transform()       # Transform2D
	var scale := Vector2(ct.x.length(), ct.y.length())
	var top_left_world := -ct.origin
	var size_world := rect_px / scale

	return Rect2(top_left_world, size_world)
