extends Node2D
# World-anchored grid for 32x32 tiles.
# Draws lines at x=n*TILE, y=n*TILE in world space.
# Godot 4.5, pure GDScript (no ternary).

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

	# Visible world rect (world-space) centered on camera
	var vp_size: Vector2 = get_viewport_rect().size
	var zoom: Vector2 = cam.zoom
	var half_ws: Vector2 = vp_size * zoom * 0.5
	var center_ws: Vector2 = cam.global_position

	var tl_ws: Vector2 = center_ws - half_ws
	var br_ws: Vector2 = center_ws + half_ws

	# Convert to inclusive tile index range
	var tl_tx: int = floori(tl_ws.x / TILE)
	var tl_ty: int = floori(tl_ws.y / TILE)
	var br_tx: int = ceili(br_ws.x / TILE) - 1
	var br_ty: int = ceili(br_ws.y / TILE) - 1

	# Safety early-out
	if br_tx < tl_tx or br_ty < tl_ty:
		return

	# Keep ~1px line width on screen regardless of zoom
	var base_lw: float = min(1.0 / zoom.x, 1.0 / zoom.y)

	# Vertical lines: x = tx*TILE
	for tx in range(tl_tx, br_tx + 1):
		var x := float(tx * TILE)
		var is_major: bool = posmod(tx, MAJOR_EVERY) == 0
		var col: Color = major_col if is_major else minor_col
		var w: float = (2.0 / zoom.x) if is_major else base_lw

		draw_line(
			Vector2(x, float(tl_ty * TILE)),
			Vector2(x, float((br_ty + 1) * TILE)),
			col,
			w,
			false
		)

	# Horizontal lines: y = ty*TILE
	for ty in range(tl_ty, br_ty + 1):
		var y := float(ty * TILE)
		var is_major2: bool = posmod(ty, MAJOR_EVERY) == 0
		var col2: Color = major_col if is_major2 else minor_col
		var w2: float = (2.0 / zoom.y) if is_major2 else base_lw

		draw_line(
			Vector2(float(tl_tx * TILE), y),
			Vector2(float((br_tx + 1) * TILE), y),
			col2,
			w2,
			false
		)
