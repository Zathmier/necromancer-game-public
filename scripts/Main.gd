extends Node2D

const PlayerScript   = preload("res://scripts/player/Player.gd")
const ConsoleScript  = preload("res://scripts/ui/Console.gd")
const GridScript     = preload("res://scripts/debug/Grid.gd")
const WorldGenScript = preload("res://scripts/world/WorldGen.gd")
const WorldViewScript= preload("res://scripts/world/WorldDebugPainter.gd")

const TILE := 32
const HALF_TILE := TILE / 2

func _ready() -> void:
	_configure_window()

	# Screen overlay grid
	var grid_layer := CanvasLayer.new()
	grid_layer.name = "GridLayer"
	add_child(grid_layer)

	var grid := Node2D.new()
	grid.name = "Grid"
	grid.set_script(GridScript)
	grid_layer.add_child(grid)

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

	# Spawn on the center tile of the current view
	var center := get_viewport_rect().size * 0.5
	var spawn := Vector2(
		round(center.x / TILE) * TILE + HALF_TILE,
		round(center.y / TILE) * TILE + HALF_TILE
	)
	player.global_position = spawn

	# UI Console
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	var console := Control.new()
	console.name = "Console"
	console.set_script(ConsoleScript)
	ui.add_child(console)

func _configure_window() -> void:
	DisplayServer.window_set_size(Vector2i(1920,1080))
