extends Node2D
# Streamed TileMap renderer for biomes. Godot 4.5 / GDScript.

const TILE := 32
const CHUNK_TILES := 48
@export var chunk_margin: int = 1

const BIOME_COLORS := {
	"water":  Color(0.18, 0.42, 0.95),
	"sand":   Color(0.84, 0.76, 0.52),
	"grass":  Color(0.36, 0.74, 0.38),
	"forest": Color(0.18, 0.56, 0.20),
	"rock":   Color(0.24, 0.28, 0.22),
}

var _tilemap: TileMap
var _tileset: TileSet
var _atlas_id: int = -1
var _biome_atlas_coord: Dictionary[String, Vector2i] = {}

var _loaded_chunks: Dictionary[Vector2i, bool] = {}
var _last_chunk_rect: Rect2i = Rect2i(0, 0, 0, 0)
var _has_last: bool = false

@onready var _worldgen: Node = get_tree().current_scene.find_child("WorldGen", true, false)
@onready var _player: Node2D = get_tree().current_scene.find_child("Player", true, false)

func _ready() -> void:
	_build_tileset()

	_tilemap = TileMap.new()
	_tilemap.name = "WorldMap"
	_tilemap.tile_set = _tileset
	# keep transforms neutral (grid alignment depends on this)
	_tilemap.position = Vector2.ZERO
	_tilemap.scale = Vector2.ONE
	_tilemap.rotation = 0.0
	# modest quadrants
	_tilemap.cell_quadrant_size = 16
	_tilemap.rendering_quadrant_size = 16

	add_child(_tilemap)
	set_process(true)

func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	# Anchor streaming to the player (stable), fall back to camera center.
	var center_ws: Vector2 = _player.global_position if _player != null else cam.get_screen_center_position()
	var vp: Vector2 = get_viewport_rect().size
	var size_ws: Vector2 = vp * cam.zoom
	var tl_ws: Vector2 = center_ws - size_ws * 0.5
	var br_ws: Vector2 = tl_ws + size_ws

	# Visible tiles (inclusive right/bottom) using ceil()-1 (no epsilon)
	var tl_tx: int = floori(tl_ws.x / TILE)
	var tl_ty: int = floori(tl_ws.y / TILE)
	var br_tx: int = ceili (br_ws.x / TILE) - 1
	var br_ty: int = ceili (br_ws.y / TILE) - 1

	# Chunk window with margin (floor-div works for negatives)
	var min_cx: int = _floor_div(tl_tx, CHUNK_TILES) - chunk_margin
	var min_cy: int = _floor_div(tl_ty, CHUNK_TILES) - chunk_margin
	var max_cx: int = _floor_div(br_tx, CHUNK_TILES) + chunk_margin
	var max_cy: int = _floor_div(br_ty, CHUNK_TILES) + chunk_margin

	var chunk_rect := Rect2i(min_cx, min_cy, (max_cx - min_cx + 1), (max_cy - min_cy + 1))
	if _has_last and chunk_rect == _last_chunk_rect:
		return
	_has_last = true
	_last_chunk_rect = chunk_rect

	_update_stream(min_cx, min_cy, max_cx, max_cy)

# ---------- tileset build ----------
func _build_tileset() -> void:
	var raw_keys: Array = BIOME_COLORS.keys()
	var names: Array[String] = []
	for k in raw_keys:
		names.append(String(k))
	names.sort()

	var count: int = names.size()
	var atlas_img := Image.create(TILE * count, TILE, false, Image.FORMAT_RGBA8)
	for i in range(count):
		var tile_img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
		tile_img.fill(BIOME_COLORS[names[i]])
		atlas_img.blit_rect(tile_img, Rect2i(Vector2i.ZERO, Vector2i(TILE, TILE)), Vector2i(i * TILE, 0))

	var tex := ImageTexture.create_from_image(atlas_img)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE, TILE)

	_tileset = TileSet.new()
	# >>> THE IMPORTANT LINE: make the map use 32×32 tiles <<<
	_tileset.tile_size = Vector2i(TILE, TILE)

	_atlas_id = _tileset.add_source(atlas)
	for i in range(count):
		var coord: Vector2i = Vector2i(i, 0)
		atlas.create_tile(coord)
		_biome_atlas_coord[names[i]] = coord

	# Sanity: ensure we actually ended with 32×32
	assert(_tileset.tile_size == Vector2i(TILE, TILE), "TileSet.tile_size mismatch; grid & chunks will drift")

# ---------- streaming ----------
static func _floor_div(a: int, b: int) -> int:
	# floor division that handles negatives correctly
	return floori(float(a) / float(b))

func _update_stream(min_cx: int, min_cy: int, max_cx: int, max_cy: int) -> void:
	var wanted: Dictionary[Vector2i, bool] = {}
	for cy in range(min_cy, max_cy + 1):
		for cx in range(min_cx, max_cx + 1):
			var c := Vector2i(cx, cy)
			wanted[c] = true
			if not _loaded_chunks.has(c):
				_load_chunk(c)

	var to_remove: Array[Vector2i] = []
	for k in _loaded_chunks.keys():
		var ck := k as Vector2i
		if not wanted.has(ck):
			to_remove.append(ck)
	for c in to_remove:
		_unload_chunk(c)

func _load_chunk(c: Vector2i) -> void:
	if _worldgen == null or not _worldgen.has_method("get_biome"):
		push_warning("WorldGen.get_biome not found; skipping chunk render")
		return

	var start_wx: int = c.x * CHUNK_TILES
	var start_wy: int = c.y * CHUNK_TILES

	for ty in range(CHUNK_TILES):
		for tx in range(CHUNK_TILES):
			var wx: int = start_wx + tx
			var wy: int = start_wy + ty
			var biome: String = String(_worldgen.call("get_biome", wx, wy))
			var coord: Vector2i = (_biome_atlas_coord.get(biome, _biome_atlas_coord.get("rock")) as Vector2i)
			_tilemap.set_cell(0, Vector2i(wx, wy), _atlas_id, coord)

	_loaded_chunks[c] = true

func _unload_chunk(c: Vector2i) -> void:
	var start_wx: int = c.x * CHUNK_TILES
	var start_wy: int = c.y * CHUNK_TILES
	for ty in range(CHUNK_TILES):
		for tx in range(CHUNK_TILES):
			_tilemap.erase_cell(0, Vector2i(start_wx + tx, start_wy + ty))
	_loaded_chunks.erase(c)
