extends Node

signal console_command(text: String)
signal toggle_console()
signal console_output(text: String)  # NEW

func send_console(text: String) -> void:
	emit_signal("console_command", text)

func request_toggle_console() -> void:
	emit_signal("toggle_console")

func send_output(text: String) -> void:  # NEW
	emit_signal("console_output", text)
