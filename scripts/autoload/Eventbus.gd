
extends Node
class_name Eventbus
signal console_command(text: String)
signal toggle_console()
func send_console(text: String) -> void: emit_signal("console_command", text)
func request_toggle_console() -> void: emit_signal("toggle_console")
