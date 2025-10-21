extends Node
class_name Logger
enum Level { TRACE, DEBUG, INFO, WARN, ERROR }
var level: Level = Level.DEBUG
func _log(tag: String, msg: String, lvl: Level) -> void:
	if lvl >= level:
		print("[%s] [%s] %s: %s" % [Time.get_datetime_string_from_system(), Level.keys()[lvl], tag, msg])
func i(t:String,m:String)->void:_log(t,m,Level.INFO)
func w(t:String,m:String)->void:_log(t,m,Level.WARN)
func e(t:String,m:String)->void:_log(t,m,Level.ERROR)
