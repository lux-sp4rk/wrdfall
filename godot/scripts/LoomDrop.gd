extends Control

@onready var grid_container: GridContainer = %"GridContainer"
@onready var word_label: Label = %"WordLabel"
@onready var score_label: Label = %"ScoreLabel"
@onready var shake_button: Button = %"ShakeButton"

const ROWS: int = 7
const COLS: int = 6
const MIN_WORD_LENGTH: int = 3
const INITIAL_FILL_ROWS: int = 5
const SHAKE_COST: int = 3

var grid: Array = []       # 2D [row][col] of String
var buttons: Array = []    # 2D [row][col] of Button
var selected_path: Array = []  # Array of Vector2i (x=col, y=row)
var is_selecting: bool = false
var score: int = 0

var dictionary: DictionaryService

# Scrabble-like distribution (Total: 98 tiles)
const LETTER_WEIGHTS: Dictionary = {
	"E": 12, "A": 9, "I": 9, "O": 8, "N": 6, "R": 6, "T": 6, "L": 4, "S": 4, "U": 4,
	"D": 4, "G": 3, "B": 2, "C": 2, "M": 2, "P": 2, "F": 2, "H": 2, "V": 2, "W": 2,
	"Y": 2, "K": 1, "J": 1, "X": 1, "Q": 1, "Z": 1
}
var _bag_distribution: Array = []

const DROP_INTERVAL: float = 5.0  # seconds between letter drops
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

# Rescue word drip-feed: when no valid word exists, bias drops to build one
var _rescue_word: String = ""
var _rescue_col: int = -1
var _rescue_letters_remaining: Array = []


func _ready() -> void:
	dictionary = DictionaryService.new()
	_build_weighted_bag()
	_initialize_grid()
	_update_score_display()
	_update_shake_button()
	_start_drop_timer()

	# Connect buttons
	shake_button.pressed.connect(_on_shake_pressed)


func _build_weighted_bag() -> void:
	_bag_distribution.clear()
	for letter in LETTER_WEIGHTS:
		var count: int = LETTER_WEIGHTS[letter]
		for i in range(count):
			_bag_distribution.append(letter)


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
			btn.custom_minimum_size = Vector2(80, 80)
			btn.add_theme_font_size_override("font_size", 44)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid_container.add_child(btn)
			btn_row.append(btn)
		buttons.append(btn_row)


func _seed_words() -> void:
	var empty_rows: int = ROWS - INITIAL_FILL_ROWS
	var words: Array = SEED_WORDS.duplicate()
	words.shuffle()

	# Guarantee at least 3 words are placed, try for up to 5
	var target_count: int = 3 + randi() % 3
	var placed_count: int = 0
	var max_attempts: int = 50  # Safety limit to prevent infinite loops

	for attempt in range(max_attempts):
		if placed_count >= target_count or words.is_empty():
			break

		var word: String = words.pop_front()

		# Try all 4 directions for this word
		var directions: Array = [0, 1, 2, 3]
		directions.shuffle()
		var placed: bool = false

		for direction in directions:
			if placed:
				break

			for _retry in range(10):
				var row: int
				var col: int
				var dr: int  # row delta per letter
				var dc: int  # col delta per letter

				match direction:
					0:  # horizontal
						dr = 0; dc = 1
						if word.length() > COLS:
							break
						row = empty_rows + randi() % INITIAL_FILL_ROWS
						col = randi() % (COLS - word.length() + 1)
					1:  # vertical
						dr = 1; dc = 0
						if word.length() > INITIAL_FILL_ROWS:
							break
						col = randi() % COLS
						row = empty_rows + randi() % (INITIAL_FILL_ROWS - word.length() + 1)
					2:  # diagonal down-right
						dr = 1; dc = 1
						var max_len: int = mini(COLS, INITIAL_FILL_ROWS)
						if word.length() > max_len:
							break
						row = empty_rows + randi() % (INITIAL_FILL_ROWS - word.length() + 1)
						col = randi() % (COLS - word.length() + 1)
					3:  # diagonal down-left
						dr = 1; dc = -1
						var max_len2: int = mini(COLS, INITIAL_FILL_ROWS)
						if word.length() > max_len2:
							break
						row = empty_rows + randi() % (INITIAL_FILL_ROWS - word.length() + 1)
						col = word.length() - 1 + randi() % (COLS - word.length() + 1)

				# Place the word
				for i in range(word.length()):
					grid[row + dr * i][col + dc * i] = word[i]
				placed = true
				placed_count += 1
				break

		# If we didn't place this word and we haven't met minimum, add it back
		if not placed and placed_count < 3:
			words.append(word)


func _random_letter() -> String:
	return _bag_distribution[randi() % _bag_distribution.size()]


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


# --- Rescue word system ---

func _find_any_word_on_grid() -> bool:
	# 4 axes — each checked forward and reversed to cover all 8 directions
	var directions: Array = [
		Vector2i(0, 1),   # horizontal (right)
		Vector2i(1, 0),   # vertical (down)
		Vector2i(1, 1),   # diagonal down-right
		Vector2i(1, -1),  # diagonal down-left
	]
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] == "":
				continue
			for dir in directions:
				var letters: String = ""
				var r: int = row
				var c: int = col
				while r >= 0 and r < ROWS and c >= 0 and c < COLS and grid[r][c] != "":
					letters += grid[r][c]
					if letters.length() >= MIN_WORD_LENGTH:
						if dictionary.is_valid_word(letters):
							return true
						# Also check the reverse (covers the opposite direction)
						var rev: String = ""
						for i in range(letters.length() - 1, -1, -1):
							rev += letters[i]
						if dictionary.is_valid_word(rev):
							return true
					if letters.length() >= 6:
						break
					r += dir.x
					c += dir.y
	return false


func _plan_rescue_word() -> void:
	var candidates: Array = SEED_WORDS.duplicate()
	candidates.shuffle()
	for word in candidates:
		if word.length() > 4:
			continue
		# Find a column with space for all letters to stack vertically
		for _attempt in range(10):
			var col: int = randi() % COLS
			# Count empty cells in this column
			var empty_count: int = 0
			for r in range(ROWS):
				if grid[r][col] == "":
					empty_count += 1
			if empty_count >= word.length():
				_rescue_word = word
				_rescue_col = col
				_rescue_letters_remaining = []
				for i in range(word.length()):
					_rescue_letters_remaining.append(word[i])
				return
	# No suitable column found — will retry next drop cycle
	_rescue_word = ""


func _clear_rescue() -> void:
	_rescue_word = ""
	_rescue_col = -1
	_rescue_letters_remaining = []


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

	# Must be 8-directionally adjacent (including diagonals)
	var last: Vector2i = selected_path[selected_path.size() - 1]
	var diff: Vector2i = cell - last
	if absi(diff.x) <= 1 and absi(diff.y) <= 1:
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
	_update_shake_button()
	word_label.text = "+%d" % points

	# Clear the selected cells
	for cell in selected_path:
		grid[cell.y][cell.x] = ""

	_apply_gravity()
	_update_grid_display()

	# Check for win conditions
	if _is_grid_empty():
		_trigger_win()
		return

	# Win if there are letters but no valid words remain
	if not _is_grid_empty() and not _find_any_word_on_grid():
		_trigger_win()
		return

	# After clearing, check if a rescue is needed for upcoming drops
	if not _find_any_word_on_grid():
		_plan_rescue_word()
	else:
		_clear_rescue()


func _score_word(word: String) -> int:
	var length: int = word.length()
	# Base points scale with length; longer words are worth more
	match length:
		3: return 5
		4: return 7
		5: return 10
		6: return 14
		_: return 14 + (length - 6) * 5


# --- Shake Button ---

func _on_shake_pressed() -> void:
	if game_over:
		return

	if score < SHAKE_COST:
		word_label.text = "Need %d points to shake!" % SHAKE_COST
		return

	score -= SHAKE_COST
	_update_score_display()
	_update_shake_button()
	_shake_grid()
	word_label.text = "Grid shaken! (-%d)" % SHAKE_COST


func _shake_grid() -> void:
	# Collect all non-empty letters from the grid
	var letters: Array = []
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] != "":
				letters.append(grid[row][col])

	# Clear the grid
	for row in range(ROWS):
		for col in range(COLS):
			grid[row][col] = ""

	# Shuffle the letters
	letters.shuffle()

	# Redistribute letters randomly across the grid
	for letter in letters:
		# Find a random empty cell
		var placed: bool = false
		for _attempt in range(100):  # Max attempts to find an empty spot
			var row: int = randi() % ROWS
			var col: int = randi() % COLS
			if grid[row][col] == "":
				grid[row][col] = letter
				placed = true
				break

		# Fallback: if somehow no empty cell found (shouldn't happen), skip
		if not placed:
			break

	# Apply gravity to settle letters
	_apply_gravity()
	_update_grid_display()

	# Check for win conditions after shaking
	if _is_grid_empty():
		_trigger_win()
		return

	# Win if there are letters but no valid words remain
	if not _is_grid_empty() and not _find_any_word_on_grid():
		_trigger_win()
		return

	# After shaking, check if we need a rescue word
	if not _find_any_word_on_grid():
		_plan_rescue_word()
	else:
		_clear_rescue()


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

	var has_word: bool = _find_any_word_on_grid()

	# If a word exists, the rescue is no longer needed
	if has_word:
		_clear_rescue()

	# If no word and no rescue queued, plan one
	if not has_word and _rescue_letters_remaining.is_empty():
		_plan_rescue_word()

	# Drop a rescue letter if we have one queued and the column is open
	if not _rescue_letters_remaining.is_empty():
		var col: int = _rescue_col
		if grid[0][col] == "":
			grid[0][col] = _rescue_letters_remaining.pop_front()
		else:
			# Target column is full — fall back to a normal drop
			col = open_cols[randi() % open_cols.size()]
			grid[0][col] = _smart_letter(col)
			_clear_rescue()
	else:
		var col: int = open_cols[randi() % open_cols.size()]
		grid[0][col] = _smart_letter(col)

	_apply_gravity()
	_update_grid_display()


func _is_grid_empty() -> bool:
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] != "":
				return false
	return true


func _trigger_win() -> void:
	game_over = true
	drop_timer.stop()
	word_label.text = "You Win! Score: %d" % score


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


func _update_shake_button() -> void:
	shake_button.disabled = score < SHAKE_COST
