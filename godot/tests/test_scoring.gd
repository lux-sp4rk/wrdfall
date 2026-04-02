extends GutTest

# Test scoring calculations
func test_calculate_word_score_basic():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	# Test basic 3-letter word
	var score_3 = game._calculate_word_score("CAT", 3)
	assert_eq(score_3, 3 * GameConstants.WORD_MULTIPLIERS[3], "3-letter word score should be base * 1x")
	
	# Test 4-letter word
	var score_4 = game._calculate_word_score("FISH", 4)
	assert_eq(score_4, 4 * GameConstants.WORD_MULTIPLIERS[4], "4-letter word score should be base * 2x")
	
	# Test 5-letter word
	var score_5 = game._calculate_word_score("WORLD", 5)
	assert_eq(score_5, 5 * GameConstants.WORD_MULTIPLIERS[5], "5-letter word score should be base * 4x")

func test_calculate_word_score_with_tiles():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	# Score calculation should use tile point values
	var word = "HELLO"
	var tiles = [
		{"letter": "H", "points": 4},
		{"letter": "E", "points": 1},
		{"letter": "L", "points": 1},
		{"letter": "L", "points": 1},
		{"letter": "O", "points": 1}
	]
	
	var base_score = 4 + 1 + 1 + 1 + 1  # 8
	var expected = base_score * GameConstants.WORD_MULTIPLIERS[5]  # 8 * 4 = 32
	
	var actual = game._calculate_word_score_with_tiles(tiles)
	assert_eq(actual, expected, "Score should be sum of tile points * length multiplier")

func test_combo_multiplier_calculation():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	# No combo
	game.combo_streak = 0
	var multiplier_0 = game._get_combo_multiplier()
	assert_eq(multiplier_0, 1.0, "No combo should have 1x multiplier")
	
	# First combo (4-letter word)
	game.combo_streak = 1
	var multiplier_1 = game._get_combo_multiplier()
	assert_eq(multiplier_1, 1.0 + GameConstants.COMBO_MULTIPLIER_PER_STREAK, "First combo adds 0.5x")
	
	# Max combo
	game.combo_streak = 10
	var multiplier_max = game._get_combo_multiplier()
	assert_eq(multiplier_max, GameConstants.COMBO_MULTIPLIER_MAX, "Combo multiplier should be capped at 3x")

func test_is_valid_selection_simple():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	# Test adjacent cells
	var cell1 = Vector2i(0, 0)
	var cell2 = Vector2i(1, 0)  # Adjacent horizontally
	assert_true(game._is_adjacent(cell1, cell2), "Horizontal neighbors should be adjacent")
	
	var cell3 = Vector2i(0, 1)  # Adjacent vertically
	assert_true(game._is_adjacent(cell1, cell3), "Vertical neighbors should be adjacent")
	
	var cell4 = Vector2i(1, 1)  # Adjacent diagonally
	assert_true(game._is_adjacent(cell1, cell4), "Diagonal neighbors should be adjacent")

func test_is_not_adjacent():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	var cell1 = Vector2i(0, 0)
	var cell2 = Vector2i(2, 0)  # Two cells apart
	assert_false(game._is_adjacent(cell1, cell2), "Cells two apart should not be adjacent")
	
	var cell3 = Vector2i(0, 2)  # Two cells apart vertically
	assert_false(game._is_adjacent(cell1, cell3), "Cells two apart vertically should not be adjacent")

func test_selection_too_short():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	# Selection with less than MIN_WORD_LENGTH tiles
	game.selected_path = [Vector2i(0, 0), Vector2i(1, 0)]  # Only 2 tiles
	assert_false(game._is_selection_valid_length(), "2-tile selection should be too short")

func test_selection_valid_length():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	# Selection with MIN_WORD_LENGTH tiles
	game.selected_path = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]  # 3 tiles
	assert_true(game._is_selection_valid_length(), "3-tile selection should be valid length")

func test_reset_selection():
	var game = load("res://scripts/LoomDrop.gd").new()
	
	game.selected_path = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	game.is_selecting = true
	
	game._reset_selection()
	
	assert_eq(game.selected_path.size(), 0, "Selected path should be empty after reset")
	assert_eq(game.is_selecting, false, "is_selecting should be false after reset")
