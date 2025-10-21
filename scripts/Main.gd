extends Node2D

const PlayerScript   = preload("res://scripts/player/Player.gd")
const ConsoleScript  = preload("res://scripts/ui/Console.gd")
const GridScript     = preload("res://scripts/debug/Grid.gd")
const WorldGenScript = preload("res://scripts/world/WorldGen.gd")
const WorldViewScript= preload("res://scripts/world/WorldDebugPainter.gd")

func _ready() -> void:
	_configure_window()

	# Grid
	var grid := Node2D.new()
	grid.name = "Grid"
	grid.set_script(GridScript)
	add_child(grid)

	# World generator + debug painter
	var world := Node.new()
	world.name = "WorldGen"
	world.set_script(WorldGenScript)
	add_child(world)

	var view := Node2D.new()
	view.name = "WorldView"
	view.set_script(WorldViewScript)
	add_child(view)

	# Player
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	add_child(player)
	player.global_position = get_viewport_rect().size * 0.5

	# UI Console
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	var console := Control.new()
	console.name = "Console"
	console.set_script(ConsoleScript)
	ui.add_child(console)

func _configure_window() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
