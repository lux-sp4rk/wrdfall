extends Control

@onready var grid_container: GridContainer = %"GridContainer"
@onready var grid_center: CenterContainer = $MarginContainer/VBox/GridCenter
@onready var word_label: Label = %"WordLabel"
@onready var score_label: Label = %"ScoreLabel"
@onready var shake_button: Button = %"ShakeButton"
@onready var hammer_button: Button = %"HammerButton"
@onready var swap_button: Button = %"SwapButton"
@onready var draw_more_button: Button = %"DrawMoreButton"
@onready var home_button: Button = %"HomeButton"
@onready var background: ColorRect = $ColorRect
@onready var margin_container: MarginContainer = $MarginContainer
@onready var game_over_modal: ColorRect = %"GameOverModal"
@onready var modal_message_label: Label = %"MessageLabel"
@onready var modal_score_label: Label = %"ScoreLabel"
@onready var retry_button: Button = %"RetryButton"
@onready var quit_button: Button = %"QuitButton"
@onready var drop_sound: AudioStreamPlayer = %"DropSoundPlayer"
@onready var word_score_sound: AudioStreamPlayer = %"WordScoreSoundPlayer"
@onready var shake_sound: AudioStreamPlayer = %"ShakeSoundPlayer"

const ROWS: int = 7
const COLS: int = 6
const MIN_WORD_LENGTH: int = 3
const INITIAL_FILL_ROWS: int = 5
const SHAKE_COST: int = 5
const HAMMER_COST: int = 8
const SWAP_COST: int = 3
const DRAW_MORE_COST: int = 15

var grid: Array = []       # 2D [row][col] of String
var buttons: Array = []    # 2D [row][col] of Button
var selected_path: Array = []  # Array of Vector2i (x=col, y=row)
var is_selecting: bool = false
var is_hammer_targeting: bool = false
var is_swap_targeting: bool = false
var swap_first_cell: Vector2i = Vector2i(-1, -1)
var score: int = 0

var dictionary: DictionaryService
var lang_config: LanguageConfig
var _bag_distribution: Array = []

const DROP_INTERVAL: float = 10.0  # seconds between letter drops

const COLOR_SELECTED: Color = Color(0.35, 0.65, 1.0)
const COLOR_TOO_SHORT: Color = Color(0.7, 0.7, 0.7)

const ICON_SHAKE: String = "\u21bb"   # ↻
const ICON_HAMMER: String = "\u2692"  # ⚒
const ICON_SWAP: String = "\u21c4"    # ⇄
const ICON_DRAW_MORE: String = "\u2295"  # ⊕
const ICON_CANCEL: String = "\u2715"  # ✕

var drop_timer: Timer
var game_over: bool = false

# Rescue word drip-feed: when no valid word exists, bias drops to build one
var _rescue_word: String = ""
var _rescue_col: int = -1
var _rescue_letters_remaining: Array = []


func _ready() -> void:
	lang_config = LanguageConfig.get_config(GameSettings.current_language)
	dictionary = DictionaryService.new(lang_config.wordlist_path, lang_config.extra_alpha)
	_build_weighted_bag()
	_initialize_grid()

	# Start tracking session stats
	StatsManager.start_session()

	# Set up icon buttons (must happen before update calls)
	_setup_icon_button(shake_button, ICON_SHAKE, lang_config.ui_strings["shake"])
	_setup_icon_button(hammer_button, ICON_HAMMER, lang_config.ui_strings["hammer"])
	_setup_icon_button(swap_button, ICON_SWAP, lang_config.ui_strings["swap"])
	_setup_icon_button(draw_more_button, ICON_DRAW_MORE, lang_config.ui_strings["draw_more"])

	_update_score_display()
	_update_shake_button()
	_update_hammer_button()
	_update_swap_button()
	_update_draw_more_button()
	_start_drop_timer()

	# Connect buttons
	shake_button.pressed.connect(_on_shake_pressed)
	hammer_button.pressed.connect(_on_hammer_pressed)
	swap_button.pressed.connect(_on_swap_pressed)
	draw_more_button.pressed.connect(_on_draw_more_pressed)
	home_button.pressed.connect(_on_home_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Hide modal initially
	game_over_modal.hide()

	# Dynamic grid sizing
	grid_center.resized.connect(_resize_grid)
	call_deferred("_resize_grid")

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")


func _on_retry_pressed() -> void:
	# Restart the game
	_restart_game()


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")


	# Dynamic grid sizing
	grid_center.resized.connect(_resize_grid)
	call_deferred("_resize_grid")


func _restart_with_language(code: String) -> void:
	lang_config = LanguageConfig.get_config(code)
	dictionary.reload(lang_config.wordlist_path, lang_config.extra_alpha)
	_build_weighted_bag()

	# Reset game state
	score = 0
	game_over = false
	is_selecting = false
	is_hammer_targeting = false
	is_swap_targeting = false
	swap_first_cell = Vector2i(-1, -1)
	selected_path.clear()
	_clear_rescue()

	# Update UI labels
	_set_button_content(shake_button, ICON_SHAKE, lang_config.ui_strings["shake"])
	_set_button_content(hammer_button, ICON_HAMMER, lang_config.ui_strings["hammer"])
	_set_button_content(swap_button, ICON_SWAP, lang_config.ui_strings["swap"])
	_set_button_content(draw_more_button, ICON_DRAW_MORE, lang_config.ui_strings["draw_more"])
	word_label.text = ""

	_initialize_grid()
	_update_score_display()
	_update_shake_button()
	_update_hammer_button()
	_update_swap_button()
	_update_draw_more_button()

	# Restart the drop timer
	if drop_timer:
		drop_timer.stop()
		drop_timer.start()


func _build_weighted_bag() -> void:
	_bag_distribution.clear()
	for letter in lang_config.letter_weights:
		var count: int = lang_config.letter_weights[letter]
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
			btn.custom_minimum_size = Vector2(16, 16)
			btn.add_theme_font_size_override("font_size", 44)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid_container.add_child(btn)
			btn_row.append(btn)
		buttons.append(btn_row)


func _resize_grid() -> void:
	if buttons.is_empty():
		return
	var h_sep: int = grid_container.get_theme_constant("h_separation")
	var v_sep: int = grid_container.get_theme_constant("v_separation")
	var avail: Vector2 = grid_center.size
	var cell_w: float = (avail.x - (COLS - 1) * h_sep) / COLS
	var cell_h: float = (avail.y - (ROWS - 1) * v_sep) / ROWS
	var cell_size: float = floorf(minf(cell_w, cell_h))
	if cell_size < 16.0:
		cell_size = 16.0
	var font_size: int = int(cell_size * 0.55)
	for row in range(ROWS):
		for col in range(COLS):
			var btn: Button = buttons[row][col]
			btn.custom_minimum_size = Vector2(cell_size, cell_size)
			btn.add_theme_font_size_override("font_size", font_size)


func _seed_words() -> void:
	var empty_rows: int = ROWS - INITIAL_FILL_ROWS
	var words: Array = lang_config.seed_words.duplicate()
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
				if lang_config.vowels.find(grid[r][c]) != -1:
					vowel_count += 1

	var need_vowel: bool = false
	if total_count > 0:
		var ratio: float = float(vowel_count) / float(total_count)
		need_vowel = ratio < lang_config.target_vowel_ratio

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
	if neighbor != "" and lang_config.bigrams.has(neighbor) and randf() < 0.5:
		var candidates: String = lang_config.bigrams[neighbor]
		return candidates[randi() % candidates.length()]

	if need_vowel:
		return lang_config.vowels[randi() % lang_config.vowels.length()]

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
	var candidates: Array = lang_config.seed_words.duplicate()
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

	# Cancel targeting modes with ESC
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_hammer_targeting:
			_cancel_hammer_targeting()
			return
		if is_swap_targeting:
			_cancel_swap_targeting()
			return

	# Debug keys to test animations (development only)
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_W and Input.is_key_pressed(KEY_CTRL):
			_trigger_win()
			return
		if event.keycode == KEY_L and Input.is_key_pressed(KEY_CTRL):
			_trigger_game_over()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var cell := _cell_at(event.global_position)
			if cell != Vector2i(-1, -1):
				# Handle targeting modes
				if is_hammer_targeting:
					_handle_hammer_targeting(cell)
				elif is_swap_targeting:
					_handle_swap_targeting(cell)
				else:
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
		word_label.text = lang_config.ui_strings["not_valid"]
		return

	var points: int = _score_word(word)
	score += points
	_update_score_display()
	_update_shake_button()
	_update_hammer_button()
	_update_swap_button()
	_update_draw_more_button()
	word_label.text = "+%d" % points

	# Track word and tiles cleared
	StatsManager.record_word(word, selected_path.size())

	# Play word score sound
	if word_score_sound and word_score_sound.stream:
		word_score_sound.play()

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
		word_label.text = lang_config.ui_strings["need_shake"] % SHAKE_COST
		return

	score -= SHAKE_COST
	_update_score_display()
	_update_shake_button()
	_update_hammer_button()
	_update_swap_button()
	_update_draw_more_button()

	# Play shake sound
	if shake_sound and shake_sound.stream:
		shake_sound.play()

	# Perform shake animation (async)
	await _shake_grid()
	word_label.text = lang_config.ui_strings["grid_shaken"] % SHAKE_COST


func _shake_grid() -> void:
	# Visual shake animation: rapid position changes
	var original_pos: Vector2 = grid_center.position
	var shake_intensity: float = 12.0
	var shake_duration: float = 0.4  # Match the sound duration
	var shake_count: int = 12

	# Perform rapid shakes
	for i in range(shake_count):
		var offset := Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		var tween := create_tween()
		tween.tween_property(grid_center, "position", original_pos + offset, shake_duration / shake_count)
		await tween.finished

	# Return to original position
	grid_center.position = original_pos

	# Now shuffle the letters
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


# --- Hammer Button ---

func _on_hammer_pressed() -> void:
	if game_over:
		return

	# If already in targeting mode, cancel it
	if is_hammer_targeting:
		_cancel_hammer_targeting()
		return

	if score < HAMMER_COST:
		word_label.text = lang_config.ui_strings["need_hammer"] % HAMMER_COST
		return

	# Cancel swap if active
	if is_swap_targeting:
		_cancel_swap_targeting()

	# Enter targeting mode
	is_hammer_targeting = true
	_update_hammer_button()
	word_label.text = lang_config.ui_strings["hammer_target"]


func _cancel_hammer_targeting() -> void:
	is_hammer_targeting = false
	_update_hammer_button()
	word_label.text = lang_config.ui_strings["hammer_cancel"]


func _handle_hammer_targeting(cell: Vector2i) -> void:
	# Check if the cell has a letter
	if grid[cell.y][cell.x] == "":
		word_label.text = lang_config.ui_strings["hammer_empty"]
		return

	# Deduct the cost
	score -= HAMMER_COST
	_update_score_display()
	_update_shake_button()
	_update_hammer_button()
	_update_swap_button()
	_update_draw_more_button()

	# Destroy the tile
	grid[cell.y][cell.x] = ""
	word_label.text = lang_config.ui_strings["tile_destroyed"] % HAMMER_COST

	# Exit targeting mode
	is_hammer_targeting = false

	# Apply gravity to settle letters
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

	# After destroying, check if we need a rescue word
	if not _find_any_word_on_grid():
		_plan_rescue_word()
	else:
		_clear_rescue()


# --- Swap Button ---

func _on_swap_pressed() -> void:
	if game_over:
		return

	# If already in targeting mode, cancel it
	if is_swap_targeting:
		_cancel_swap_targeting()
		return

	if score < SWAP_COST:
		word_label.text = lang_config.ui_strings["need_swap"] % SWAP_COST
		return

	# Cancel hammer if active
	if is_hammer_targeting:
		_cancel_hammer_targeting()

	# Enter swap targeting mode (step 1: pick first tile)
	is_swap_targeting = true
	swap_first_cell = Vector2i(-1, -1)
	_update_swap_button()
	word_label.text = lang_config.ui_strings["swap_first"]


func _cancel_swap_targeting() -> void:
	is_swap_targeting = false
	swap_first_cell = Vector2i(-1, -1)
	_clear_selection_visuals()
	_update_swap_button()
	word_label.text = lang_config.ui_strings["swap_cancel"]


func _handle_swap_targeting(cell: Vector2i) -> void:
	# Both tiles must have letters
	if grid[cell.y][cell.x] == "":
		word_label.text = lang_config.ui_strings["swap_empty"]
		return

	if swap_first_cell == Vector2i(-1, -1):
		# Step 1: select first tile
		swap_first_cell = cell
		_highlight_cell(cell, COLOR_SELECTED)
		word_label.text = lang_config.ui_strings["swap_second"]
	else:
		# Step 2: select second tile — must be adjacent
		var diff: Vector2i = cell - swap_first_cell
		if absi(diff.x) > 1 or absi(diff.y) > 1 or (diff.x == 0 and diff.y == 0):
			word_label.text = lang_config.ui_strings["swap_not_adjacent"]
			return

		var first := swap_first_cell

		# Deduct cost and exit targeting mode before animation
		score -= SWAP_COST
		_update_score_display()
		_update_shake_button()
		_update_hammer_button()
		_update_swap_button()
		_update_draw_more_button()
		word_label.text = lang_config.ui_strings["swap_done"] % SWAP_COST

		is_swap_targeting = false
		swap_first_cell = Vector2i(-1, -1)

		# Execute swap with animation (runs as coroutine)
		_execute_swap(first, cell)


func _highlight_cell(cell: Vector2i, color: Color) -> void:
	var btn: Button = buttons[cell.y][cell.x]
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _make_stylebox(color))
	btn.add_theme_stylebox_override("hover", _make_stylebox(color))


func _execute_swap(cell_a: Vector2i, cell_b: Vector2i) -> void:
	var btn_a: Button = buttons[cell_a.y][cell_a.x]
	var btn_b: Button = buttons[cell_b.y][cell_b.x]

	# Highlight both cells
	_highlight_cell(cell_a, COLOR_SELECTED)
	_highlight_cell(cell_b, COLOR_SELECTED)

	# Fade out
	var tween := create_tween().set_parallel(true)
	tween.tween_property(btn_a, "modulate:a", 0.0, 0.12)
	tween.tween_property(btn_b, "modulate:a", 0.0, 0.12)
	await tween.finished

	# Swap grid data
	var tmp: String = grid[cell_a.y][cell_a.x]
	grid[cell_a.y][cell_a.x] = grid[cell_b.y][cell_b.x]
	grid[cell_b.y][cell_b.x] = tmp
	btn_a.text = grid[cell_a.y][cell_a.x]
	btn_b.text = grid[cell_b.y][cell_b.x]

	# Fade in
	var tween2 := create_tween().set_parallel(true)
	tween2.tween_property(btn_a, "modulate:a", 1.0, 0.12)
	tween2.tween_property(btn_b, "modulate:a", 1.0, 0.12)
	await tween2.finished

	_clear_selection_visuals()

	# Apply gravity and update display
	_apply_gravity()
	_update_grid_display()

	# Check win conditions
	if _is_grid_empty():
		_trigger_win()
		return
	if not _is_grid_empty() and not _find_any_word_on_grid():
		_trigger_win()
		return

	# Check if rescue needed
	if not _find_any_word_on_grid():
		_plan_rescue_word()
	else:
		_clear_rescue()


# --- Draw More Button ---

func _on_draw_more_pressed() -> void:
	if game_over:
		return

	if score < DRAW_MORE_COST:
		word_label.text = lang_config.ui_strings["need_draw_more"] % DRAW_MORE_COST
		return

	# Find columns that have space (top row is empty)
	var open_cols: Array = []
	for col in range(COLS):
		if grid[0][col] == "":
			open_cols.append(col)

	if open_cols.is_empty():
		word_label.text = lang_config.ui_strings["draw_more_no_space"]
		return

	# Deduct cost
	score -= DRAW_MORE_COST
	_update_score_display()
	_update_shake_button()
	_update_hammer_button()
	_update_swap_button()
	_update_draw_more_button()

	# Draw letters
	_draw_more_letters(open_cols)


func _draw_more_letters(open_cols: Array) -> void:
	# Draw up to 5 letters, or as many as we have open columns
	var letters_to_draw: int = mini(5, open_cols.size())

	# Shuffle the open columns so we place letters randomly
	open_cols.shuffle()

	# Place letters in the top row of random open columns
	for i in range(letters_to_draw):
		var col: int = open_cols[i]
		grid[0][col] = _smart_letter(col)

	# Apply gravity to settle letters
	_apply_gravity()
	_update_grid_display()

	# Show feedback
	word_label.text = lang_config.ui_strings["draw_more_success"] % [letters_to_draw, DRAW_MORE_COST]

	# Check for win conditions
	if _is_grid_empty():
		_trigger_win()
		return

	# Win if there are letters but no valid words remain
	if not _is_grid_empty() and not _find_any_word_on_grid():
		_trigger_win()
		return

	# After drawing, check if we need a rescue word
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
	drop_timer.wait_time = GameSettings.get_drop_interval()
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

	# Play drop sound
	if drop_sound and drop_sound.stream:
		drop_sound.play()


func _is_grid_empty() -> bool:
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] != "":
				return false
	return true


func _trigger_win() -> void:
	game_over = true
	drop_timer.stop()
	StatsManager.end_session(score)
	_play_win_animation()


func _trigger_game_over() -> void:
	game_over = true
	drop_timer.stop()
	StatsManager.end_session(score)
	_play_lose_animation()


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
	score_label.text = lang_config.ui_strings["score"] % score


func _update_shake_button() -> void:
	shake_button.disabled = score < SHAKE_COST


func _update_hammer_button() -> void:
	if is_hammer_targeting:
		_set_button_content(hammer_button, ICON_CANCEL, lang_config.ui_strings["cancel"])
		hammer_button.disabled = false
	else:
		_set_button_content(hammer_button, ICON_HAMMER, lang_config.ui_strings["hammer"])
		hammer_button.disabled = score < HAMMER_COST


func _update_swap_button() -> void:
	if is_swap_targeting:
		_set_button_content(swap_button, ICON_CANCEL, lang_config.ui_strings["cancel"])
		swap_button.disabled = false
	else:
		_set_button_content(swap_button, ICON_SWAP, lang_config.ui_strings["swap"])
		swap_button.disabled = score < SWAP_COST


func _update_draw_more_button() -> void:
	draw_more_button.disabled = score < DRAW_MORE_COST


func _setup_icon_button(btn: Button, icon_text: String, label_text: String) -> void:
	btn.text = ""
	if btn.has_theme_font_size_override("font_size"):
		btn.remove_theme_font_size_override("font_size")

	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var icon_label := Label.new()
	icon_label.name = "Icon"
	icon_label.text = icon_text
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	var text_label := Label.new()
	text_label.name = "Text"
	text_label.text = label_text
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(text_label)


func _set_button_content(btn: Button, icon_text: String, label_text: String) -> void:
	btn.get_node("Content/Icon").text = icon_text
	btn.get_node("Content/Text").text = label_text


# --- Win/Lose Animations ---

func _play_win_animation() -> void:
	# Celebratory, high-energy win animation with screen shake, color bursts, and grid bounce

	# Store original positions for restoration
	var orig_margin_pos: Vector2 = margin_container.position
	var orig_grid_scale: Vector2 = grid_center.scale
	var orig_bg_color: Color = background.color

	# Create main animation timeline
	var tween := create_tween().set_parallel(false)

	# Phase 1: Initial impact - quick scale pop (0.15s)
	var phase1 := create_tween().set_parallel(true)
	phase1.tween_property(grid_center, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	phase1.tween_property(background, "color", Color(0.3, 0.7, 0.4), 0.1)  # Bright green burst
	await phase1.finished

	# Phase 2: Screen shake (0.4s total)
	for i in range(8):
		var shake_offset: Vector2 = Vector2(
			randf_range(-12, 12),
			randf_range(-12, 12)
		)
		var shake_tween := create_tween()
		shake_tween.tween_property(margin_container, "position", orig_margin_pos + shake_offset, 0.05)
		await shake_tween.finished

	# Phase 3: Celebratory bounce and color pulse (0.6s)
	# Grid bounce sequence
	var bounce_tween := create_tween()
	bounce_tween.tween_property(grid_center, "scale", Vector2(0.95, 0.95), 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	bounce_tween.tween_property(grid_center, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	bounce_tween.tween_property(grid_center, "scale", orig_grid_scale, 0.3)

	# Color pulse sequence (runs in parallel with bounce)
	var color_tween := create_tween()
	color_tween.tween_property(background, "color", Color(0.4, 0.5, 0.9), 0.2)  # Blue
	color_tween.tween_property(background, "color", Color(0.9, 0.7, 0.2), 0.2)  # Gold
	color_tween.tween_property(background, "color", orig_bg_color, 0.2)

	await bounce_tween.finished

	# Phase 4: Restore and display message
	margin_container.position = orig_margin_pos
	word_label.text = lang_config.ui_strings["you_win"] % score

	# Animate word label appearance
	word_label.modulate.a = 0.0
	var label_tween := create_tween()
	label_tween.tween_property(word_label, "modulate:a", 1.0, 0.3)
	await label_tween.finished

	# Show game over modal after a brief pause
	await get_tree().create_timer(0.5).timeout
	_show_game_over_modal(true)


func _play_lose_animation() -> void:
	# Somber but encouraging lose animation with fade and downward drift

	# Store original values
	var orig_grid_pos: Vector2 = grid_center.position
	var orig_bg_color: Color = background.color
	var target_gray: Color = Color(0.12, 0.15, 0.18)  # Darker, desaturated

	# Create animation timeline
	var tween := create_tween().set_parallel(true)

	# Darken background gradually (0.8s)
	tween.tween_property(background, "color", target_gray, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

	# Grid drifts down slowly and fades slightly (0.8s)
	tween.tween_property(grid_center, "position:y", orig_grid_pos.y + 30, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(grid_center, "modulate:a", 0.6, 0.8).set_ease(Tween.EASE_IN)

	# Desaturate grid buttons (0.8s)
	for row in range(ROWS):
		for col in range(COLS):
			var btn: Button = buttons[row][col]
			tween.tween_property(btn, "modulate", Color(0.6, 0.6, 0.6), 0.8)

	await tween.finished

	# Display encouraging message with fade-in
	word_label.text = lang_config.ui_strings["game_over"] % score
	word_label.modulate.a = 0.0
	var label_tween := create_tween()
	label_tween.tween_property(word_label, "modulate:a", 1.0, 0.4)
	await label_tween.finished

	# Show game over modal after a brief pause
	await get_tree().create_timer(0.5).timeout
	_show_game_over_modal(false)


func _show_game_over_modal(is_win: bool) -> void:
	# Update modal text based on win/lose state (strings already include score)
	if is_win:
		modal_message_label.text = lang_config.ui_strings["you_win"] % score
	else:
		modal_message_label.text = lang_config.ui_strings["game_over"] % score

	# Hide the separate score label since the message includes it
	modal_score_label.hide()

	# Update button labels
	retry_button.text = lang_config.ui_strings["play_again"]
	quit_button.text = lang_config.ui_strings["quit_to_menu"]

	# Fade in modal
	game_over_modal.modulate.a = 0.0
	game_over_modal.show()
	var fade_tween := create_tween()
	fade_tween.tween_property(game_over_modal, "modulate:a", 1.0, 0.3)


func _restart_game() -> void:
	# Hide modal
	game_over_modal.hide()

	# Reset game state
	score = 0
	game_over = false
	is_selecting = false
	is_hammer_targeting = false
	is_swap_targeting = false
	swap_first_cell = Vector2i(-1, -1)
	selected_path.clear()
	_clear_rescue()

	# Reset visual state
	background.color = Color(0.17, 0.24, 0.31)  # Original slate color
	margin_container.position = Vector2.ZERO
	grid_center.position = Vector2.ZERO
	grid_center.scale = Vector2.ONE
	grid_center.modulate.a = 1.0
	word_label.text = ""
	word_label.modulate.a = 1.0

	# Reinitialize grid
	_initialize_grid()
	_update_score_display()
	_update_shake_button()
	_update_hammer_button()
	_update_swap_button()
	_update_draw_more_button()

	# Start tracking new session
	StatsManager.start_session()

	# Restart drop timer
	if drop_timer:
		drop_timer.stop()
		drop_timer.start()
