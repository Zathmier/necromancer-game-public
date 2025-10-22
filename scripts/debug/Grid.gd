# res://scripts/debug/Grid.gd
# Godot 4.5 — Code-only, world-anchored grid aligned to TILE_SIZE=32 and CHUNK_TILES=48.
# No nodes or Inspector usage. Call Grid.draw(self) from Main._draw().
# Fully typed; uses viewport→world via canvas_transform.affine_inverse().

extends RefCounted

# ---- Project contract ----
const TILE_SIZE: int = 32
const CHUNK_TILES: int = 48

# ---- Styling ----
const TILE_COLOR: Color  = Color(1.0, 1.0, 1.0, 0.25)
const CHUNK_COLOR: Color = Color(1.0, 1.0, 1.0, 0.60)

# ---- State (code-only) ----
static var enabled: bool = true
static var world_origin: Vector2 = Vector2.ZERO   # world px where tile (0,0) starts

# ---- Public API ----
static func set_enabled(v: bool) -> void:
	enabled = v

static func set_world_origin(origin_world_px: Vector2) -> void:
	world_origin = origin_world_px

static func draw(host: Node2D) -> void:
	if not enabled:
		return

	var aabb: Rect2 = _viewport_world_aabb_px(host)
	var ts: int = TILE_SIZE

	# Visible tile range RELATIVE to world_origin (locks to true world tiles, not screen).
	var left: float = aabb.position.x - world_origin.x
	var top: float = aabb.position.y - world_origin.y
	var right: float = aabb.position.x + aabb.size.x - world_origin.x
	var bottom: float = aabb.position.y + aabb.size.y - world_origin.y

	var tx0: int = floori(left / float(ts))
	var ty0: int = floori(top / float(ts))
	var tx1: int = ceili(right / float(ts))
	var ty1: int = ceili(bottom / float(ts))

	# --- Tile lines (thin) ---
	var y_top_w: float = world_origin.y + float(ty0 * ts)
	var y_bot_w: float = world_origin.y + float(ty1 * ts)
	for tx in range(tx0, tx1 + 1):
		var xw: float = world_origin.x + float(tx * ts)
		_draw_line_world(host, Vector2(xw, y_top_w), Vector2(xw, y_bot_w), TILE_COLOR, 1.0)

	var x_left_w: float = world_origin.x + float(tx0 * ts)
	var x_right_w: float = world_origin.x + float(tx1 * ts)
	for ty in range(ty0, ty1 + 1):
		var yw: float = world_origin.y + float(ty * ts)
		_draw_line_world(host, Vector2(x_left_w, yw), Vector2(x_right_w, yw), TILE_COLOR, 1.0)

	# --- Chunk lines (bold) ---
	var chunk_px: int = ts * CHUNK_TILES
	var cx0: int = floori(tx0 / CHUNK_TILES)
	var cy0: int = floori(ty0 / CHUNK_TILES)
	var cx1: int = ceili(tx1 / CHUNK_TILES)
	var cy1: int = ceili(ty1 / CHUNK_TILES)

	for cx in range(cx0, cx1 + 1):
		var xcw: float = world_origin.x + float(cx * chunk_px)
		_draw_line_world(host, Vector2(xcw, y_top_w), Vector2(xcw, y_bot_w), CHUNK_COLOR, 1.0)

	for cy in range(cy0, cy1 + 1):
		var ycw: float = world_origin.y + float(cy * chunk_px)
		_draw_line_world(host, Vector2(x_left_w, ycw), Vector2(x_right_w, ycw), CHUNK_COLOR, 1.0)

# Optional debug getters (for console prints)
static func get_visible_tile_bounds(host: Node2D) -> Rect2i:
	var aabb: Rect2 = _viewport_world_aabb_px(host)
	var ts: int = TILE_SIZE

	var left: float = aabb.position.x - world_origin.x
	var top: float = aabb.position.y - world_origin.y
	var right: float = aabb.position.x + aabb.size.x - world_origin.x
	var bottom: float = aabb.position.y + aabb.size.y - world_origin.y

	var tx0: int = floori(left / float(ts))
	var ty0: int = floori(top / float(ts))
	var tx1: int = ceili(right / float(ts)) - 1
	var ty1: int = ceili(bottom / float(ts)) - 1
	return Rect2i(Vector2i(tx0, ty0), Vector2i(tx1 - tx0 + 1, ty1 - ty0 + 1))

static func get_visible_chunk_bounds(host: Node2D) -> Rect2i:
	var t: Rect2i = get_visible_tile_bounds(host)
	var cx0: int = floori(t.position.x / CHUNK_TILES)
	var cy0: int = floori(t.position.y / CHUNK_TILES)
	var cx1: int = floori((t.position.x + t.size.x - 1) / CHUNK_TILES)
	var cy1: int = floori((t.position.y + t.size.y - 1) / CHUNK_TILES)
	return Rect2i(Vector2i(cx0, cy0), Vector2i(cx1 - cx0 + 1, cy1 - cy0 + 1))

# ---- Internals ----
static func _draw_line_world(host: Node2D, a_world: Vector2, b_world: Vector2, color: Color, width: float) -> void:
	var a_local: Vector2 = host.to_local(a_world)
	var b_local: Vector2 = host.to_local(b_world)
	host.draw_line(a_local, b_local, color, width, false)

static func _viewport_world_aabb_px(host: Node2D) -> Rect2:
	var vp := host.get_viewport()
	var rect_px: Vector2 = vp.get_visible_rect().size
	var inv: Transform2D = vp.get_canvas_transform().affine_inverse()

	var tl: Vector2 = inv * Vector2.ZERO
	var br: Vector2 = inv * rect_px
	var top_left: Vector2 = Vector2(minf(tl.x, br.x), minf(tl.y, br.y))
	var bottom_right: Vector2 = Vector2(maxf(tl.x, br.x), maxf(tl.y, br.y))
	return Rect2(top_left, bottom_right - top_left)
