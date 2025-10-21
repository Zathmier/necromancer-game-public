# res://scripts/debug/Grid.gd
extends Node2D

const TILE := 32
const CHUNK_TILES := 48
const CHUNK_PX := TILE * CHUNK_TILES

var minor_col := Color(1, 1, 1, 0.07)
var major_col := Color(1, 1, 1, 0.18)
var axis_col  := Color(1, 1, 1, 0.35)

var _last_cam := Vector2.INF
var _last_size := Vector2.ZERO

func _ready() -> void:
	z_index = -100  # draw behind everything
	if not Engine.is_editor_hint():
		_register_console_cmd()

func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var sz := get_viewport_rect().size
	if _last_cam.distance_to(cam.global_position) > 8.0 or _last_size != sz:
		_last_cam = cam.global_position
		_last_size = sz
		queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	var vs := get_viewport_rect().size

	var half := vs * 0.5
	var tl := (cam != null) ? cam.global_position - half : -half
	var br := tl + vs

	var sx := int(floor(tl.x / TILE) * TILE)
	var ex := int(floor(br.x / TILE) * TILE)
	var sy := int(floor(tl.y / TILE) * TILE)
	var ey := int(floor(br.y / TILE) * TILE)

	# verticals
	for x in range(sx, ex + TILE, TILE):
		var is_major := posmod(x, CHUNK_PX) == 0
		var col := is_major ? major_col : minor_col
		if x == 0: col = axis_col
		draw_line(Vector2(x, sy), Vector2(x, ey), col, is_major ? 2.0 : 1.0)

	# horizontals
	for y in range(sy, ey + TILE, TILE):
		var is_major := posmod(y, CHUNK_PX) == 0
		var col := is_major ? major_col : minor_col
		if y == 0: col = axis_col
		draw_line(Vector2(sx, y), Vector2(ex, y), col, is_major ? 2.0 : 1.0)

func _register_console_cmd() -> void:
	ConsoleRouter.register_cmd("grid", func(a):
		if a.is_empty():
			Bus.send_output("grid: on | off | alpha <0..1> | tile <px> | chunk <tiles>")
			return
		var cmd := a[0].to_lower()
		match cmd:
			"on":  visible = true;  Bus.send_output("grid on")
			"off": visible = false; Bus.send_output("grid off")
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
			"tile":
				if a.size() >= 2:
					var px := max(2, int(a[1]))
					set_meta("old_tile", TILE) # harmless; just a breadcrumb if needed
					@warning_ignore("unused_variable")
					var _dummy := px # avoid reassigning const; just reload script if you want to change permanently
					Bus.send_output("tile size is const (%d). Change and reload script if desired." % TILE)
				else:
					Bus.send_output("tile size = %d" % TILE)
			"chunk":
				if a.size() >= 2:
					var tiles := max(1, int(a[1]))
					@warning_ignore("unused_variable")
					var _dummy2 := tiles
					Bus.send_output("chunk tiles is const (%d). Change and reload script if desired." % CHUNK_TILES)
				else:
					Bus.send_output("chunk tiles = %d" % CHUNK_TILES)
	, "Control grid overlay")
