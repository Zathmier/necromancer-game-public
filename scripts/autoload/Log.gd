extends Node
# No class_name to avoid collisions

enum Level { TRACE, DEBUG, INFO, WARN, ERROR }
var level: int = Level.DEBUG

func _log(tag: String, msg: String, lvl: int) -> void:
	if lvl >= level:
		print("[%s] [%s] %s: %s" % [
			Time.get_datetime_string_from_system(),
			["TRACE","DEBUG","INFO","WARN","ERROR"][lvl],
			tag, msg
		])

func t(tag: String, msg: String) -> void: _log(tag, msg, Level.TRACE)
func d(tag: String, msg: String) -> void: _log(tag, msg, Level.DEBUG)
func i(tag: String, msg: String) -> void: _log(tag, msg, Level.INFO)
func w(tag: String, msg: String) -> void: _log(tag, msg, Level.WARN)
func e(tag: String, msg: String) -> void: _log(tag, msg, Level.ERROR)
