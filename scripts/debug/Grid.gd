extends Node2D
class_name Grid

@export var tile_size: float = 32.0
@export var major_every: int = 8
@export var color_minor: Color = Color(1, 1, 1, 0.08)
@export var color_major: Color = Color(1, 1, 1, 0.16)

# If your WorldTileMap isn't at (0,0), either set this or point to it below.
@export var tilemap_origin: Vector2 = Vector2.ZERO
@export var use_tilemap_origin_from: NodePath

func _ready() -> void:
	if use_tilemap_origin_from != NodePath():
		var n := get_node_or_null(use_tilemap_origin_from)
		if n is Node2D:
			tilemap_origin = (n as Node2D).global_position

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var z: Vector2 = cam.zoom

	# World coords of screen center, derive top-left in world space.
	var world_center: Vector2 = cam.get_screen_center_position()
	var top_left_world: Vector2 = world_center - (vp_size * 0.5) / z

	# Align to TileMap origin if it’s offset.
	var top_left_rel: Vector2 = top_left_world - tilemap_origin

	# Step size in pixels between lines (accounts for zoom).
	var step_px_x: float = tile_size * z.x
	var step_px_y: float = tile_size * z.y

	# Pixel offset to the first grid line on-screen.
	var start_px_x: float = -fposmod(top_left_rel.x, tile_size) * z.x
	var start_px_y: float = -fposmod(top_left_rel.y, tile_size) * z.y

	# -------- Vertical lines --------
	var x: float = start_px_x
	var ix: int = int(floor(top_left_rel.x / tile_size))
	while x <= vp_size.x + 1.0:
		var is_major: bool = (ix % major_every) == 0
		var c: Color = color_minor
		if is_major:
			c = color_major
		var px: float = floor(x) + 0.5  # center 1px stroke on pixel
		draw_line(Vector2(px, 0.0), Vector2(px, vp_size.y), c, 1.0, false)
		x += step_px_x
		ix += 1

	# -------- Horizontal lines --------
	var y: float = start_px_y
	var iy: int = int(floor(top_left_rel.y / tile_size))
	while y <= vp_size.y + 1.0:
		var is_major2: bool = (iy % major_every) == 0
		var c2: Color = color_minor
		if is_major2:
			c2 = color_major
		var py: float = floor(y) + 0.5
		draw_line(Vector2(0.0, py), Vector2(vp_size.x, py), c2, 1.0, false)
		y += step_px_y
		iy += 1
