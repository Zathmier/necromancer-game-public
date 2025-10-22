extends Node2D
# Streamed TileMap renderer for biomes.
# Godot 4.5 / GDScript. No inspector setup required.

const TILE := 32
const CHUNK_TILES := 48
const CHUNK_MARGIN := 1  # stream 1 chunk beyond view

# Colors per biome
const BIOME_COLORS := {
	"water":  Color(0.18, 0.42, 0.95),
	"sand":   Color(0.84, 0.76, 0.52),
	"grass":  Color(0.36, 0.74, 0.38),
	"forest": Color(0.18, 0.56, 0.20),
	"rock":   Color(0.24, 0.28, 0.22),
}

const DEBUG_STREAM_LOG := false

var _tilemap: TileMap
var _tileset: TileSet
var _atlas_id: int = -1
var _biome_atlas_coord: Dictionary[String, Vector2i] = {}  # biome -> atlas coord

var _loaded_chunks: Dictionary[Vector2i, bool] = {}
var _last_cam_pos: Vector2 = Vector2.INF
var _last_cam_zoom: Vector2 = Vector2.INF
var _last_vp_size: Vector2 = Vector2.ZERO

@onready var _worldgen: Node = get_tree().current_scene.find_child("WorldGen", true, false)

func _ready() -> void:
	_build_tileset()
	_tilemap = TileMap.new()
	_tilemap.name = "WorldMap"
	_tilemap.tile_set = _tileset
	_tilemap.cell_quadrant_size = 16
	_tilemap.rendering_quadrant_size = 16
	add_child(_tilemap)
	set_process(true)

func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	if cam.global_position.distance_to(_last_cam_pos) < 8.0 and cam.zoom == _last_cam_zoom and vp_size == _last_vp_size:
		return # nothing significant changed

	_last_cam_pos = cam.global_position
	_last_cam_zoom = cam.zoom
	_last_vp_size = vp_size

	var world_rect: Rect2 = _world_rect_visible(cam, vp_size)
	_update_stream(world_rect)

# ---------- tileset build ----------

func _build_tileset() -> void:
	# Convert Variant[] -> String[] explicitly (strict typing)
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

	for i in range(count):
		var coord: Vector2i = Vector2i(i, 0)
		atlas.create_tile(coord)
		_biome_atlas_coord[names[i]] = coord

	_tileset = TileSet.new()
	_atlas_id = _tileset.add_source(atlas)

# ---------- streaming ----------

static func _chunk_of_tile(t: int) -> int:
	# floor division that behaves for negatives
	return floori(float(t) / CHUNK_TILES)

func _world_rect_visible(cam: Camera2D, vp_size: Vector2) -> Rect2:
	var size_ws: Vector2 = vp_size * cam.zoom
	var tl_ws: Vector2 = cam.get_screen_center_position() - size_ws * 0.5
	return Rect2(tl_ws, size_ws)

func _update_stream(world_rect: Rect2) -> void:
	# Convert world rect -> tile rect with RIGHT/BOTTOM *inclusive*
	var tl: Vector2 = world_rect.position
	var br: Vector2 = world_rect.position + world_rect.size
	var tl_tile := Vector2i(floori(tl.x / TILE), floori(tl.y / TILE))
	var br_tile := Vector2i(                       # inclusive: subtract a tiny epsilon
		floori((br.x - 0.0001) / TILE),
		floori((br.y - 0.0001) / TILE)
	)

	var min_cx: int = _chunk_of_tile(tl_tile.x) - CHUNK_MARGIN
	var min_cy: int = _chunk_of_tile(tl_tile.y) - CHUNK_MARGIN
	var max_cx: int = _chunk_of_tile(br_tile.x) + CHUNK_MARGIN
	var max_cy: int = _chunk_of_tile(br_tile.y) + CHUNK_MARGIN

	var wanted: Dictionary[Vector2i, bool] = {}

	for cy in range(min_cy, max_cy + 1):
		for cx in range(min_cx, max_cx + 1):
			var c: Vector2i = Vector2i(cx, cy)
			wanted[c] = true
			if not _loaded_chunks.has(c):
				if DEBUG_STREAM_LOG: print("LOAD ", c)
				_load_chunk(c)

	# unload what we no longer need
	var to_remove: Array[Vector2i] = []
	for k in _loaded_chunks.keys():
		var ck := k as Vector2i
		if not wanted.has(ck):
			to_remove.append(ck)
	for c in to_remove:
		if DEBUG_STREAM_LOG: print("UNLOAD ", c)
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
