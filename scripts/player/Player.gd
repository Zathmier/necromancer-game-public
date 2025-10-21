# Player.gd — click-to-move prototype
extends CharacterBody2D

@export var speed: float = 220.0
var _has_target: bool = false
var _target_pos: Vector2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_target_pos = get_global_mouse_position()
		_has_target = true

func _physics_process(delta: float) -> void:
	if _has_target:
		var to_target: Vector2 = _target_pos - global_position
		if to_target.length() <= 4.0:
			velocity = Vector2.ZERO
			_has_target = false
		else:
			velocity = to_target.normalized() * speed
		move_and_slide()
