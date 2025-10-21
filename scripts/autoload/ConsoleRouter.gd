extends Node
class_name ConsoleRouter

var commands := {}

func _ready() -> void:
	_register_default()
	Eventbus.console_command.connect(_on_console_command)

func register(name: String, callable_fn: Callable, desc: String = "") -> void:
	commands[name] = {"fn": callable_fn, "desc": desc}

func _on_console_command(text: String) -> void:
	var parts := text.strip_edges().split(" ", false)
	if parts.is_empty(): return
	var cmd := parts[0].to_lower()
	var args := parts.slice(1, parts.size())
	if not commands.has(cmd):
		Logger.w("Console", "Unknown command: %s" % cmd)
		return
	commands[cmd].fn.call(args)

func _register_default() -> void:
	register("help", func(_a): 
		for k in commands.keys().sorted():
			Logger.i("Console", "%s — %s" % [k, commands[k].desc])
	, "List commands")
	register("echo", func(a): Logger.i("Console", " ".join(a)), "Echo text")
