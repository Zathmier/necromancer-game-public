extends CharacterBody2D

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@export var speed := 220.0

func _ready() -> void:
	# Make path following a little forgiving
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0
	agent.avoidance_enabled = false # can enable later if we add crowds

func _unhandled_input(event: InputEvent) -> void:
	# Left click to set destination
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target := get_global_mouse_position()
		agent.set_target_position(target)
		get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next := agent.get_next_path_position()
	var dir := (next - global_position)
	if dir.length() > 0.001:
		velocity = dir.normalized() * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
