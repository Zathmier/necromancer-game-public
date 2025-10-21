extends Node
class_name ConsoleRouter
var commands := {}
func _ready()->void:
	_register_default()
	Eventbus.console_command.connect(_on_console_command)
func register(name:String, fn:Callable, desc:String="")->void:
	commands[name] = {"fn": fn, "desc": desc}
func _on_console_command(text:String)->void:
	var p := text.strip_edges().split(" ", false)
	if p.is_empty(): return
	var cmd := p[0].to_lower()
	var args := p.slice(1, p.size())
	if not commands.has(cmd):
		Logger.w("Console", "Unknown command: %s" % cmd); return
	commands[cmd].fn.call(args)
func _register_default()->void:
	register("help", func(_a):
		for k in commands.keys().sorted():
			Logger.i("Console", "%s — %s" % [k, commands[k].desc])
	, "List commands")
	register("echo", func(a): Logger.i("Console", " ".join(a)), "Echo text")
