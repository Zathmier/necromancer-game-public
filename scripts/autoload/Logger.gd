extends Node
class_name Logger

enum Level { TRACE, DEBUG, INFO, WARN, ERROR }
var level: Level = Level.DEBUG

func _log(tag: String, msg: String, lvl: Level) -> void:
	if lvl >= level:
		print("[%s] [%s] %s" % [Time.get_datetime_string_from_system(), Level.keys()[lvl], "%s: %s" % [tag, msg]])

func d(tag: String, msg: String) -> void: _log(tag, msg, Level.DEBUG)
func i(tag: String, msg: String) -> void: _log(tag, msg, Level.INFO)
func w(tag: String, msg: String) -> void: _log(tag, msg, Level.WARN)
func e(tag: String, msg: String) -> void: _log(tag, msg, Level.ERROR)
