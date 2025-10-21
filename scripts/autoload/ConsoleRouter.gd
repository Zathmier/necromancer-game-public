extends Node
# No class_name — referenced via autoload name "ConsoleRouter"

var commands: Dictionary = {}

func _ready() -> void:
	_register_default()
	Bus.console_command.connect(_on_console_command)

func register(name: String, fn: Callable, desc: String = "") -> void:
	commands[name] = {"fn": fn, "desc": desc}

func _on_console_command(text: String) -> void:
	var parts := text.strip_edges().split(" ", false)
	if parts.is_empty():
		return
	var cmd := parts[0].to_lower()
	var args := parts.slice(1, parts.size())
	if not commands.has(cmd):
		Log.w("Console", "Unknown command: %s" % cmd)
		return
	commands[cmd]["fn"].call(args)

func _register_default() -> void:
	register("help", func(_a):
		var ks := commands.keys()
		ks.sort() # in-place sort, GDScript 4
		for k in ks:
			Log.i("Console", "%s — %s" % [k, commands[k]["desc"]])
	, "List commands")
	register("echo", func(a):
		Log.i("Console", " ".join(a))
	, "Echo text")
