extends Node2D
# World-space grid that aligns exactly to TileMap cell borders.

const TILE := 32
const MAJOR_EVERY := 8

@export var show_grid: bool = true
@export var minor_col: Color = Color(1, 1, 1, 0.08)
@export var major_col: Color = Color(1, 1, 1, 0.20)

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not show_grid:
		return

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	# Visible world rect in world units (pixels)
	var vp: Vector2 = get_viewport_rect().size
	var size_ws: Vector2 = vp * cam.zoom
	var tl_ws: Vector2 = cam.get_screen_center_position() - size_ws * 0.5
	var br_ws: Vector2 = tl_ws + size_ws

	# Snap to tile edges using floor/ceil (works with negatives)
	var left:  int = floori(tl_ws.x / TILE) * TILE
	var right: int = ceili (br_ws.x / TILE) * TILE
	var top:   int = floori(tl_ws.y / TILE) * TILE
	var bot:   int = ceili (br_ws.y / TILE) * TILE

	# Keep grid lines ~1px on screen
	var w_x: float = 1.0 / cam.zoom.x
	var w_y: float = 1.0 / cam.zoom.y

	# Vertical lines
	for x in range(left, right + 1, TILE):
		var is_major := posmod(x / TILE, MAJOR_EVERY) == 0
		var col := major_col if is_major else minor_col
		var lw  := (2.0 / cam.zoom.x) if is_major else w_x
		draw_line(Vector2(x, top), Vector2(x, bot), col, lw, true)

	# Horizontal lines
	for y in range(top, bot + 1, TILE):
		var is_major2 := posmod(y / TILE, MAJOR_EVERY) == 0
		var col2 := major_col if is_major2 else minor_col
		var lw2  := (2.0 / cam.zoom.y) if is_major2 else w_y
		draw_line(Vector2(left, y), Vector2(right, y), col2, lw2, true)
