# res://scripts/Main.gd
extends Node2D

const PlayerScript  = preload("res://scripts/player/Player.gd")
const ConsoleScript = preload("res://scripts/ui/Console.gd")

func _ready() -> void:
	_configure_window()

	# Spawn Player (pure code)
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	add_child(player)

	# Center player on screen
	player.global_position = get_viewport_rect().size * 0.5

	# Ensure Player adds its own Camera + Nav, etc. (handled in Player.gd)

	# Spawn UI Console on a CanvasLayer (so it sits above world)
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	var console := Control.new()
	console.name = "Console"
	console.set_script(ConsoleScript)  # Console builds its own children in code
	ui.add_child(console)

func _configure_window() -> void:
	# Optional: enforce our base 1920x1080 window at runtime
	DisplayServer.window_set_size(Vector2i(1920,1080))
