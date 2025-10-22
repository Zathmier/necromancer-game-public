extends Node2D
# Pixel-perfect world-space grid aligned to 32x32 TileMap cells.
# Godot 4.5 — pure GDScript (no ?:), helpers at top level.

const TILE := 32
const MAJOR_EVERY := 8

@export var show_grid: bool = true
@export var minor_col: Color = Color(1, 1, 1, 0.08)
@export var major_col: Color = Color(1, 1, 1, 0.20)

func _process(_dt: float) -> void:
	if show_grid:
		queue_redraw()

func _draw() -> void:
	if not show_grid:
		return

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	# Visible world rect from camera
	var vp_size: Vector2 = get_viewport_rect().size
	var zoom: Vector2 = cam.zoom
	var size_ws: Vector2 = vp_size * zoom
	var tl_ws: Vector2 = cam.get_screen_center_position() - size_ws * 0.5
	var br_ws: Vector2 = tl_ws + size_ws

	# Snap to whole-tile edges (works in negatives)
	var left_edge:  int = floori(tl_ws.x / TILE) * TILE
	var right_edge: int = ceili (br_ws.x / TILE) * TILE
	var top_edge:   int = floori(tl_ws.y / TILE) * TILE
	var bot_edge:   int = ceili (br_ws.y / TILE) * TILE

	# Base line width ≈ 1px on screen
	var base_lw: float = min(1.0 / zoom.x, 1.0 / zoom.y)

	# Vertical grid lines
	for x in range(left_edge, right_edge + 1, TILE):
		var is_major: bool = posmod(x / TILE, MAJOR_EVERY) == 0
		var col: Color = major_col if is_major else minor_col
		var w: float = (2.0 / zoom.x) if is_major else base_lw
		var wx: float = snap_world_x(x, tl_ws, zoom)

		var y1: float = snap_world_y(top_edge, tl_ws, zoom)
		var y2: float = snap_world_y(bot_edge, tl_ws, zoom)
		draw_line(Vector2(wx, y1), Vector2(wx, y2), col, w, false)

	# Horizontal grid lines
	for y in range(top_edge, bot_edge + 1, TILE):
		var is_major2: bool = posmod(y / TILE, MAJOR_EVERY) == 0
		var col2: Color = major_col if is_major2 else minor_col
		var w2: float = (2.0 / zoom.y) if is_major2 else base_lw
		var wy: float = snap_world_y(y, tl_ws, zoom)

		var x1: float = snap_world_x(left_edge, tl_ws, zoom)
		var x2: float = snap_world_x(right_edge, tl_ws, zoom)
		draw_line(Vector2(x1, wy), Vector2(x2, wy), col2, w2, false)

# ---- helpers (top-level, not nested) ----

func snap_world_x(wx: float, tl_ws: Vector2, zoom: Vector2) -> float:
	var sx: float = (wx - tl_ws.x) / zoom.x
	var sx_snap: float = floor(sx) + 0.5
	return tl_ws.x + sx_snap * zoom.x

func snap_world_y(wy: float, tl_ws: Vector2, zoom: Vector2) -> float:
	var sy: float = (wy - tl_ws.y) / zoom.y
	var sy_snap: float = floor(sy) + 0.5
	return tl_ws.y + sy_snap * zoom.y
