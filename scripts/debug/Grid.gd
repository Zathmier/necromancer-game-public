extends Node2D

const TILE := 32
const CHUNK_TILES := 48
const CHUNK_PX := TILE * CHUNK_TILES

var minor_col := Color(1, 1, 1, 0.12)
var major_col := Color(1, 1, 1, 0.30)
var axis_col  := Color(1, 1, 1, 0.50)

var _last_cam := Vector2.INF
var _last_size := Vector2.ZERO

func _ready() -> void:
	# This lives under a CanvasLayer (see Main.gd), so it won’t inherit world transforms.
	z_index = 0
	if not Engine.is_editor_hint():
		_register_console_cmd()

func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var sz := get_viewport_rect().size
	# Redraw if camera moved enough or viewport changed.
	if _last_cam.distance_to(cam.global_position) > 1.0 or _last_size != sz:
		_last_cam = cam.global_position
		_last_size = sz
		queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var vs: Vector2 = get_viewport_rect().size
	var zoom: Vector2 = cam.zoom
	# IMPORTANT: camera is pixel-snapped each frame in Player.gd
	var center_ws: Vector2 = cam.get_screen_center_position()
	var tl_ws: Vector2 = center_ws - (vs * 0.5) * zoom
	var br_ws: Vector2 = tl_ws + vs * zoom

	# Snap world bounds to tile edges
	var sx: int = int(floor(tl_ws.x / TILE) * TILE)
	var ex: int = int(floor(br_ws.x / TILE) * TILE)
	var sy: int = int(floor(tl_ws.y / TILE) * TILE)
	var ey: int = int(floor(br_ws.y / TILE) * TILE)

	# Draw lines at pixel centers to avoid shimmer
	for x in range(sx, ex + TILE, TILE):
		var is_major := posmod(x, CHUNK_PX) == 0
		var col := axis_col if x == 0 else (major_col if is_major else minor_col)
		var xs := (float(x) - tl_ws.x) / zoom.x
		xs = floor(xs) + 0.5
		draw_line(Vector2(xs, 0.0), Vector2(xs, vs.y), col, 2.0 if is_major else 1.0)

	for y in range(sy, ey + TILE, TILE):
		var is_major2 := posmod(y, CHUNK_PX) == 0
		var col2 := axis_col if y == 0 else (major_col if is_major2 else minor_col)
		var ys := (float(y) - tl_ws.y) / zoom.y
		ys = floor(ys) + 0.5
		draw_line(Vector2(0.0, ys), Vector2(vs.x, ys), col2, 2.0 if is_major2 else 1.0)

func _register_console_cmd() -> void:
	ConsoleRouter.register_cmd("grid", func(a):
		if a.is_empty():
			Bus.send_output("grid: on | off | alpha <0..1>")
			return
		var cmd: String = String(a[0]).to_lower()
		match cmd:
			"on":
				visible = true;  Bus.send_output("grid on"); queue_redraw()
			"off":
				visible = false; Bus.send_output("grid off")
			"alpha":
				if a.size() >= 2:
					var v := clampf(float(a[1]), 0.0, 1.0)
					minor_col.a = v * 0.40
					major_col.a = v * 0.75
					axis_col.a  = v * 1.00
					queue_redraw()
					Bus.send_output("grid alpha = %.2f" % v)
				else:
					Bus.send_output("usage: grid alpha <0..1>")
	, "Control grid overlay")
