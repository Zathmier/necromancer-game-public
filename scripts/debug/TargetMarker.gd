extends Node2D

@export var radius: float = 12.0
@export var width: float = 2.0
@export var color: Color = Color(1, 0.2, 0.2, 0.95)  # bright red

var _t: float = 0.0

func _ready() -> void:
	# Keep absolute z so it draws above terrain/UI layers without exceeding engine limits.
	z_as_relative = false
	z_index = 4095   # safe max in Godot 4
	set_as_top_level(true)  # stay in world space even if parent has transforms

func _process(delta: float) -> void:
	_t += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var r := radius + sin(_t) * 1.5
	# draw_arc(center, radius, start, end, points, color, width, antialiased)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, color, width, true)
