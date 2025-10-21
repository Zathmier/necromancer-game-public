extends Node2D

@export var radius: float = 12.0
@export var width: float = 2.0
@export var color: Color = Color(1, 1, 1, 0.95)

var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var r := radius + sin(_t) * 1.5
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, color, width, true)
