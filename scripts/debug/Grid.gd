extends Node2D
# Pixel-perfect world-space grid that aligns to TileMap cells at any zoom.
# Godot 4.5 / GDScript

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

	# Viewport & visible world rect
	var vp: Vector2 = get_viewport_rect().size
	var zoom: Vector2 = cam.zoom
	var size_ws: Vector2 = vp * zoom
	var tl_ws: Vector2 = cam.get_screen_center_position() - size_ws * 0.5
	var br_ws: Vector2 = tl_ws + size_ws

	# Snap extents to tile boundaries using floor/ceil (handles negatives)
	var left_edge:  int = floori(tl_ws.x / TILE) * TILE
	var right_edge: int = ceili (br_ws.x / TILE) * TILE
	var top_edge:   int = floori(tl_ws.y / TILE) * TILE
	var bot_edge:   int = ceili (br_ws.y / TILE) * TILE

	# Helper to snap a world X to the nearest screen pixel, then map back to world X.
	func snap_world_x(wx: float) -> float:
		# screen_x = (wx - tl_ws.x) / zoom.x
		var sx := (wx - tl_ws.x) / zoom.x
		var sx_snap := floor(sx) + 0.5
		# world_x_back = tl_ws.x + sx_snap * zoom.x
		return tl_ws.x + sx_snap * zoom.x

	func snap_world_y(wy: float) -> float:
		var sy := (wy - tl_ws.y) / zoom.y
		var sy_snap := floor(sy) + 0.5
		return tl_ws.y + sy_snap * zoom.y

	# Line widths so they render ~1px on screen
	var lw_x: float = 1.0 / zoom.x
	var lw_y: float = 1.0 / zoom.y
	var lw: float = min(lw_x, lw_y)

	# Vertical lines
	for x in range(left_edge, right_edge + 1, TILE):
		var is_major := posmod(x / TILE, MAJOR_EVERY) == 0
		var col := major_col if is_major else minor_col
		var w  := (2.0 / zoom.x) if is_major else lw
		var wx := snap_world_x(float(x))
		draw_line(Vector2(wx, snap_world_y(float(top_edge))),
				  Vector2(wx, snap_world_y(float(bot_edge))), col, w, false)

	# Horizontal lines
	for y in range(top_edge, bot_edge + 1, TILE):
		var is_major2 := posmod(y / TILE, MAJOR_EVERY) == 0
		var col2 := major_col if is_major2 else minor_col
		var w2  := (2.0 / zoom.y) if is_major2 else lw
		var wy := snap_world_y(float(y))
		draw_line(Vector2(snap_world_x(float(left_edge)), wy),
				  Vector2(snap_world_x(float(right_edge)), wy), col2, w2, false)
