extends Node
const TILE := 32
const CHUNK_TILES := 48

static func world_px_to_tile(px: float, py: float) -> Vector2i:
	return Vector2i(floori(px / TILE), floori(py / TILE))

static func tile_to_px(wx: int, wy: int) -> Vector2i:
	return Vector2i(wx * TILE, wy * TILE)

static func world_tile_to_chunk(wx: int, wy: int, wz: int = 0) -> Dictionary:
	var cx := floori(wx / CHUNK_TILES)
	var cy := floori(wy / CHUNK_TILES)
	var tx := wx - cx * CHUNK_TILES
	var ty := wy - cy * CHUNK_TILES
	return {"cx": cx, "cy": cy, "cz": wz, "tx": tx, "ty": ty}
