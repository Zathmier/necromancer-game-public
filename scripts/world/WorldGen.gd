extends Node
# Deterministic height/biome sampling (debug-friendly)

const CHUNK_TILES := 48

var seed: int = 1337
var noise: FastNoiseLite

func _ready() -> void:
	_build_noise()

func set_seed(s: int) -> void:
	seed = s
	_build_noise()

func _build_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_OPEN_SIMPLEX2
	noise.frequency = 0.0025
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

func get_height(wx: int, wy: int) -> float:
	var v := noise.get_noise_2d(float(wx), float(wy)) # -1..1
	return 0.5 * (v + 1.0)                            # -> 0..1

func get_biome(wx: int, wy: int) -> String:
	var h := get_height(wx, wy)
	if h < 0.35: return "water"
	elif h < 0.45: return "sand"
	elif h < 0.70: return "grass"
	elif h < 0.85: return "forest"
	else: return "rock"

func generate_chunk(cx: int, cy: int) -> PackedFloat32Array:
	var arr := PackedFloat32Array()
	arr.resize(CHUNK_TILES * CHUNK_TILES)
	var base_wx := cx * CHUNK_TILES
	var base_wy := cy * CHUNK_TILES
	var idx := 0
	for ty in CHUNK_TILES:
		for tx in CHUNK_TILES:
			arr[idx] = get_height(base_wx + tx, base_wy + ty)
			idx += 1
	return arr
