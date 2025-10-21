extends Control

@onready var input_line: LineEdit = %InputLine

func _ready() -> void:
	visible = false
	Bus.toggle_console.connect(_on_toggle)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console"):
		Bus.request_toggle_console()
		get_viewport().set_input_as_handled()

func _on_toggle() -> void:
	visible = not visible
	if visible:
		input_line.grab_focus()

func _on_InputLine_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	Bus.send_console(text)
	input_line.clear()
