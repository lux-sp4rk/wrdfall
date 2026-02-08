extends Control

@onready var grid_container: GridContainer = %"GridContainer"
@onready var back_button: Button = %"BackButton"
@onready var word_label: Label = %"WordLabel"
@onready var score_label: Label = %"ScoreLabel"

const ROWS: int = 12
const COLS: int = 8
const MIN_WORD_LENGTH: int = 3
const INITIAL_FILL_ROWS: int = 8

var grid: Array = []       # 2D [row][col] of String
var buttons: Array = []    # 2D [row][col] of Button
var selected_path: Array = []  # Array of Vector2i (x=col, y=row)
var is_selecting: bool = false
var score: int = 0

var dictionary: DictionaryService

var letter_bag: String = "EEEEEEEEEEEEAAAAAAAAAIIIIIIIIIOOOOOOOOONNNNNNRRRRRRTTTTTTTTLLLLSSSSUUUUUDDDDGGGBBCCMMPPFFHHVVWWYYKJXQZ"

const DROP_INTERVAL: float = 3.0  # seconds between letter drops
const VOWELS: String = "AEIOU"
const TARGET_VOWEL_RATIO: float = 0.38
# Common English bigrams — used to bias dropped letters toward playable neighbors
const BIGRAMS: Dictionary = {
	"T": "HEIOA", "H": "EAIOU", "S": "THECO", "R": "EAIOU", "N": "GDEOT",
	"E": "RSDNA", "A": "NTRLS", "I": "NTSCO", "O": "NRFUT", "L": "EIAOY",
	"D": "EIAOS", "C": "OAHEK", "U": "RSTLN", "P": "RLAEO", "M": "AEION",
	"G": "EOAHR", "B": "ELAOU", "F": "OIRAE", "W": "AIHOE", "Y": "SOEIA",
	"V": "EIAOU", "K": "EISAN", "J": "UOAEI", "X": "PTIAE", "Q": "UUUUU",
	"Z": "EAIOU",
}

const SEED_WORDS: Array = [
	"STAR", "LOOM", "DROP", "RAIN", "FIRE", "GLOW", "WIND", "TREE",
	"LAKE", "WAVE", "RISE", "GOLD", "IRON", "BONE", "GUST", "MIST",
	"TORN", "HAZE", "DUNE", "FERN", "SAGE", "LIME", "PINE", "ARCH",
	"ROPE", "NEST", "CAVE", "PALE", "WREN", "GATE", "VINE", "HELM",
]

const COLOR_SELECTED: Color = Color(0.35, 0.65, 1.0)
const COLOR_TOO_SHORT: Color = Color(0.7, 0.7, 0.7)

var drop_timer: Timer
var game_over: bool = false


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	dictionary = DictionaryService.new()
	_initialize_grid()
	_update_score_display()
	_start_drop_timer()


func _initialize_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	grid_container.columns = COLS
	grid.clear()
	buttons.clear()

	# Build data grid: empty top rows, filled bottom rows
	var empty_rows: int = ROWS - INITIAL_FILL_ROWS
	for row in range(ROWS):
		var grid_row: Array = []
		for col in range(COLS):
			grid_row.append("" if row < empty_rows else _random_letter())
		grid.append(grid_row)

	# Plant a few words into the filled area for a playable start
	_seed_words()

	# Create button grid from data
	for row in range(ROWS):
		var btn_row: Array = []
		for col in range(COLS):
			var btn := Button.new()
			btn.text = grid[row][col]
			btn.custom_minimum_size = Vector2(48, 48)
			btn.add_theme_font_size_override("font_size", 24)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid_container.add_child(btn)
			btn_row.append(btn)
		buttons.append(btn_row)


func _seed_words() -> void:
	var empty_rows: int = ROWS - INITIAL_FILL_ROWS
	var words: Array = SEED_WORDS.duplicate()

	# Plant 3-5 words in random positions (horizontal or vertical)
	var count: int = 3 + randi() % 3
	for _i in range(count):
		if words.is_empty():
			break
		var idx: int = randi() % words.size()
		var word: String = words[idx]
		words.remove_at(idx)

		var horizontal: bool = randf() < 0.5
		var placed: bool = false

		# Try a few random positions
		for _attempt in range(20):
			if horizontal:
				if word.length() > COLS:
					break
				var row: int = empty_rows + randi() % INITIAL_FILL_ROWS
				var col: int = randi() % (COLS - word.length() + 1)
				# Write the word into the row
				for c in range(word.length()):
					grid[row][col + c] = word[c]
				placed = true
				break
			else:
				if word.length() > INITIAL_FILL_ROWS:
					break
				var col: int = randi() % COLS
				var row: int = empty_rows + randi() % (INITIAL_FILL_ROWS - word.length() + 1)
				for r in range(word.length()):
					grid[row + r][col] = word[r]
				placed = true
				break

		if not placed:
			words.append(word)


func _random_letter() -> String:
	return letter_bag[randi() % letter_bag.length()]


func _smart_letter(col: int) -> String:
	# 1) Vowel/consonant balance — count what's on the board
	var vowel_count: int = 0
	var total_count: int = 0
	for r in range(ROWS):
		for c in range(COLS):
			if grid[r][c] != "":
				total_count += 1
				if VOWELS.find(grid[r][c]) != -1:
					vowel_count += 1

	var need_vowel: bool = false
	if total_count > 0:
		var ratio: float = float(vowel_count) / float(total_count)
		need_vowel = ratio < TARGET_VOWEL_RATIO

	# 2) Find the neighbor letter where this drop will land
	var land_row: int = -1
	for r in range(ROWS - 1, -1, -1):
		if grid[r][col] == "":
			land_row = r
			break
	if land_row == -1:
		return _random_letter()

	var neighbor: String = ""
	if land_row < ROWS - 1:
		neighbor = grid[land_row + 1][col]  # letter below landing spot

	# 3) Pick letter: 50% bigram-aware, 50% bag-weighted (with vowel bias)
	if neighbor != "" and BIGRAMS.has(neighbor) and randf() < 0.5:
		var candidates: String = BIGRAMS[neighbor]
		return candidates[randi() % candidates.length()]

	if need_vowel:
		return VOWELS[randi() % VOWELS.length()]

	return _random_letter()


# --- Input handling ---

func _input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var cell := _cell_at(event.global_position)
			if cell != Vector2i(-1, -1):
				_start_selection(cell)
		elif is_selecting:
			_end_selection()
	elif event is InputEventMouseMotion and is_selecting:
		var cell := _cell_at(event.global_position)
		if cell != Vector2i(-1, -1):
			_extend_selection(cell)


func _cell_at(global_pos: Vector2) -> Vector2i:
	for row in range(ROWS):
		for col in range(COLS):
			if buttons[row][col].get_global_rect().has_point(global_pos):
				return Vector2i(col, row)
	return Vector2i(-1, -1)


# --- Selection ---

func _start_selection(cell: Vector2i) -> void:
	is_selecting = true
	selected_path.clear()
	selected_path.append(cell)
	_update_selection_visuals()


func _extend_selection(cell: Vector2i) -> void:
	# Backtrack: if the cell is the second-to-last in path, pop the last
	if selected_path.size() >= 2:
		var prev: Vector2i = selected_path[selected_path.size() - 2]
		if cell == prev:
			selected_path.pop_back()
			_update_selection_visuals()
			return

	# Skip if already in path
	for c in selected_path:
		if c == cell:
			return

	# Must be 4-directionally adjacent to the last cell
	var last: Vector2i = selected_path[selected_path.size() - 1]
	var diff: Vector2i = cell - last
	if absi(diff.x) + absi(diff.y) == 1:
		selected_path.append(cell)
		_update_selection_visuals()


func _end_selection() -> void:
	is_selecting = false
	if selected_path.size() >= MIN_WORD_LENGTH:
		var word: String = _get_selected_word()
		_accept_word(word)
	_clear_selection_visuals()
	selected_path.clear()
	# Keep last feedback visible (score / error)


func _get_selected_word() -> String:
	var word: String = ""
	for cell in selected_path:
		word += grid[cell.y][cell.x]
	return word


# --- Word acceptance ---

func _accept_word(word: String) -> void:
	# Offline validation (Issue #5)
	if not dictionary.is_valid_word(word):
		# short, friendly, actionable
		word_label.text = "Not a valid word."
		return

	var points: int = _score_word(word)
	score += points
	_update_score_display()
	word_label.text = "+%d" % points

	# Clear the selected cells
	for cell in selected_path:
		grid[cell.y][cell.x] = ""

	_apply_gravity()
	_update_grid_display()


func _score_word(word: String) -> int:
	var length: int = word.length()
	# Base points scale with length; longer words are worth more
	match length:
		3: return 3
		4: return 5
		5: return 8
		6: return 12
		_: return 12 + (length - 6) * 5


# --- Gravity ---

func _apply_gravity() -> void:
	for col in range(COLS):
		# Collect non-empty letters from bottom to top
		var letters: Array = []
		for row in range(ROWS - 1, -1, -1):
			if grid[row][col] != "":
				letters.append(grid[row][col])

		# Rewrite the column: letters packed at bottom, empty at top
		for row in range(ROWS - 1, -1, -1):
			var idx: int = ROWS - 1 - row
			if idx < letters.size():
				grid[row][col] = letters[idx]
			else:
				grid[row][col] = ""


func _start_drop_timer() -> void:
	drop_timer = Timer.new()
	drop_timer.wait_time = DROP_INTERVAL
	drop_timer.timeout.connect(_drop_letter)
	add_child(drop_timer)
	drop_timer.start()


func _drop_letter() -> void:
	if game_over:
		return

	# Find columns that have space (top row is empty)
	var open_cols: Array = []
	for col in range(COLS):
		if grid[0][col] == "":
			open_cols.append(col)

	if open_cols.is_empty():
		_trigger_game_over()
		return

	var col: int = open_cols[randi() % open_cols.size()]
	grid[0][col] = _smart_letter(col)
	_apply_gravity()
	_update_grid_display()


func _trigger_game_over() -> void:
	game_over = true
	drop_timer.stop()
	word_label.text = "Game Over! Score: %d" % score


func _update_grid_display() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			buttons[row][col].text = grid[row][col]


# --- Visuals ---

func _update_selection_visuals() -> void:
	_clear_selection_visuals()

	var word: String = _get_selected_word()
	var long_enough: bool = selected_path.size() >= MIN_WORD_LENGTH
	word_label.text = word
	word_label.add_theme_color_override(
		"font_color",
		Color.WHITE if long_enough else COLOR_TOO_SHORT
	)

	var highlight: Color = COLOR_SELECTED if long_enough else COLOR_TOO_SHORT
	for cell in selected_path:
		var btn: Button = buttons[cell.y][cell.x]
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_stylebox_override("normal", _make_stylebox(highlight))
		btn.add_theme_stylebox_override("hover", _make_stylebox(highlight))


func _clear_selection_visuals() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			var btn: Button = buttons[row][col]
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")


func _make_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	return sb


func _update_score_display() -> void:
	score_label.text = "Score: %d" % score


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
