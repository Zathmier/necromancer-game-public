extends Control

@onready var input_line: LineEdit = %InputLine
@onready var output_log: RichTextLabel = %OutputLog

func _ready() -> void:
	visible = false
	Bus.toggle_console.connect(_on_toggle)
	Bus.console_output.connect(_on_console_output)  # listen for router output

	# Keep the log scrolled to the bottom automatically
	if is_instance_valid(output_log):
		output_log.scroll_active = true
		output_log.scroll_following = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console"):
		Bus.request_toggle_console()
		get_viewport().set_input_as_handled()

func _on_toggle() -> void:
	visible = not visible
	if visible and is_instance_valid(input_line):
		input_line.grab_focus()

func _on_console_output(text: String) -> void:
	if not is_instance_valid(output_log):
		return
	output_log.append_text(text + "\n")

func _on_InputLine_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	# Echo the command itself in the UI
	Bus.send_output("> " + text)
	Bus.send_console(text)
	input_line.clear()
