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
