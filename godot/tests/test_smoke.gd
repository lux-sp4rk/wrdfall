extends GutTest

func test_dictionary_loading():
	var dict = load("res://scripts/Dictionary.gd").new()
	assert_not_null(dict, "Dictionary script should load")

	# Basic check for words_en.txt
	var file = FileAccess.open("res://data/words_en.txt", FileAccess.READ)
	assert_not_null(file, "English word list should exist")
	file.close()

func test_game_constants():
	var constants = load("res://scripts/GameConstants.gd").new()
	assert_not_null(constants, "GameConstants should load")

func test_topnavbar_scene_ready():
	"""Verify TopNavBar scene loads without null @onready errors.

	Catches broken builds where scene nodes were removed but the script
	still holds @onready references to them — which would crash _ready().
	"""
	var scene = preload("res://scenes/TopNavBar.tscn")
	var nav = scene.instantiate()
	add_child(nav)
	await nav.ready  # forces _ready() to execute fully
	# Verify critical nodes resolved
	assert_not_null(nav.%BurgerMenuButton, "BurgerMenuButton must exist in scene")
	assert_not_null(nav.%TimerLabel, "TimerLabel must exist in scene")
	assert_not_null(nav.%ScoreLabel, "ScoreLabel must exist in scene")
	nav.free()

func test_loomdrop_scene_ready():
	"""Verify LoomDrop game scene loads without null @onready errors."""
	var scene = preload("res://scenes/LoomDrop.tscn")
	var loom = scene.instantiate()
	add_child(loom)
	await loom.ready
	assert_not_null(loom.%TileGrid, "TileGrid must exist in scene")
	loom.free()
