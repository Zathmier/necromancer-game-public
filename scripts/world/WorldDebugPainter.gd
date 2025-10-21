extends Node2D
const TILE := 32

var world: Node = null
var colors := {
	"water":  Color(0.2, 0.4, 0.9, 0.85),
	"sand":   Color(0.9, 0.85, 0.6, 0.85),
	"grass":  Color(0.4, 0.8, 0.4, 0.85),
	"forest": Color(0.25, 0.6, 0.25, 0.85),
	"rock":   Color(0.6, 0.6, 0.6, 0.85),
}

var _last_origin := Vector2.INF
var _last_size := Vector2.ZERO

func _ready() -> void:
	z_index = -90  # behind player, above grid

func _process(_dt: float) -> void:
	if world == null:
		world = get_tree().current_scene.find_child("WorldGen", true, false)
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var sz: Vector2 = get_viewport_rect().size
	var origin: Vector2 = cam.global_position
	if origin.distance_to(_last_origin) > 8.0 or _last_size != sz:
		_last_origin = origin
		_last_size = sz
		queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var cam: Camera2D = get_viewport().get_camera_2d()
	var vs: Vector2 = get_viewport_rect().size
	var half: Vector2 = vs * 0.5
	var tl: Vector2 = (cam.global_position - half) if cam != null else (-half)

	var sx: int = int(floor(tl.x / TILE))
	var sy: int = int(floor(tl.y / TILE))
	var ex: int = int(floor((tl.x + vs.x) / TILE))
	var ey: int = int(floor((tl.y + vs.y) / TILE))

	for ty in range(sy, ey + 1):
		for tx in range(sx, ex + 1):
			var biome: String = world.get_biome(tx, ty) # <-- typed
			var col: Color = colors.get(biome, Color(1, 0, 1, 0.8))
			var p: Vector2 = Vector2(tx * TILE, ty * TILE)
			draw_rect(Rect2(p, Vector2(TILE, TILE)), col, true)
