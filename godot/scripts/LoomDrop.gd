extends Control

signal word_scored(points: int, word_length: int)

@onready var grid_container: GridContainer = %"GridContainer"
@onready var grid_center: CenterContainer = $MarginContainer/VBox/GridCenter
@onready var board_panel: PanelContainer = $MarginContainer/VBox/GridCenter/BoardPanel
@onready var word_label: Label = %"WordLabel"
@onready var top_nav_bar = %"TopNavBar"
@onready var shake_button: Button = %"ShakeButton"
@onready var swap_button: Button = %"SwapButton"
@onready var draw_more_button: Button = %"DrawMoreButton"
@onready var pause_button: Button = %"PauseButton"
@onready var background: ColorRect = $ColorRect
@onready var margin_container: MarginContainer = $MarginContainer
@onready var game_over_modal: ColorRect = %"GameOverModal"
@onready var modal_panel: Panel = game_over_modal.get_node("CenterContainer/Panel")
@onready var modal_message_label: Label = %"MessageLabel"
@onready var modal_score_label: Label = %"ScoreLabel"
@onready var retry_button: Button = %"RetryButton"
@onready var quit_button: Button = %"QuitButton"
@onready var drop_sound: AudioStreamPlayer = %"DropSoundPlayer"
@onready var word_score_sound: AudioStreamPlayer = %"WordScoreSoundPlayer"
@onready var shake_sound: AudioStreamPlayer = %"ShakeSoundPlayer"
@onready var game_complete_sound: AudioStreamPlayer = %"GameCompleteSoundPlayer"
@onready var game_won_sound: AudioStreamPlayer = %"GameWonSoundPlayer"
@onready var game_sidebar = %GameSidebar

# Grid and game rules now defined in GameConstants
const ROWS: int = GameConstants.ROWS
const COLS: int = GameConstants.COLS
const MIN_WORD_LENGTH: int = GameConstants.MIN_WORD_LENGTH
const INITIAL_FILL_ROWS: int = GameConstants.INITIAL_FILL_ROWS

# Power-up costs loaded from GameConstants based on difficulty
var SHAKE_COST: int = 0
var SWAP_COST: int = 0
var DRAW_MORE_COST: int = 0

var grid: Array = []       # 2D [row][col] of String
var buttons: Array = []    # 2D [row][col] of Button
var point_labels: Array = []  # 2D [row][col] of Label (subscript point values)
var selected_path: Array = []  # Array of Vector2i (x=col, y=row)
var is_selecting: bool = false
var is_swap_targeting: bool = false
var swap_first_cell: Vector2i = Vector2i(-1, -1)
var score: int = 0

var dictionary: DictionaryService
var lang_config: LanguageConfig
var _bag_distribution: Array = []

# Selection colors and icons now defined in ThemeConstants
const COLOR_SELECTED: Color = ThemeConstants.COLOR_SELECTED
const COLOR_TOO_SHORT: Color = ThemeConstants.COLOR_TOO_SHORT

const ICON_SHAKE: String = ThemeConstants.ICON_SHAKE
const ICON_SWAP: String = ThemeConstants.ICON_SWAP
const ICON_DRAW_MORE: String = ThemeConstants.ICON_DRAW_MORE
const ICON_CANCEL: String = ThemeConstants.ICON_CANCEL

var drop_timer: Timer
var game_over: bool = false
var game_started: bool = false  # True after first word scored or first tile dropped
var is_paused: bool = false

# Combo streak state
var combo_streak: int = 0

# Drop ratchet state
var drops_since_start: int = 0
var base_drop_interval: float = 0.0
var current_drop_interval: float = 0.0

# Rescue word drip-feed: when no valid word exists, bias drops to build one
var _rescue_word: String = ""
var _rescue_col: int = -1
var _rescue_letters_remaining: Array = []


func _ready() -> void:
	# Load difficulty-based settings
	SHAKE_COST = GameSettings.get_power_up_cost("shake")
	SWAP_COST = GameSettings.get_power_up_cost("swap")
	DRAW_MORE_COST = GameSettings.get_power_up_cost("draw_more")

	base_drop_interval = GameSettings.get_drop_interval()
	current_drop_interval = base_drop_interval

	lang_config = LanguageConfig.get_config(GameSettings.current_language)
	dictionary = DictionaryService.new(lang_config.wordlist_path, lang_config.extra_alpha)
	_build_weighted_bag()
	_initialize_grid()

	# Start tracking session stats
	StatsManager.start_session()

	# Set up icon buttons (must happen before update calls)
	_setup_icon_button(shake_button, ICON_SHAKE, lang_config.ui_strings["shake"])
	_setup_icon_button(swap_button, ICON_SWAP, lang_config.ui_strings["swap"])
	_setup_icon_button(draw_more_button, ICON_DRAW_MORE, lang_config.ui_strings["draw_more"])

	_update_score_display()
	_update_shake_button()
	_update_swap_button()
	_update_draw_more_button()
	_start_drop_timer()

	# Connect buttons
	shake_button.pressed.connect(_on_shake_pressed)
	swap_button.pressed.connect(_on_swap_pressed)
	draw_more_button.pressed.connect(_on_draw_more_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	top_nav_bar.exit_pressed.connect(_on_home_pressed)
	top_nav_bar.set_drop_timer(drop_timer)
	word_scored.connect(top_nav_bar.show_word_score)
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Connect burger menu to sidebar
	top_nav_bar.burger_pressed.connect(game_sidebar.toggle)

	# Pause game when sidebar opens/closes
	game_sidebar.sidebar_opened.connect(_on_sidebar_opened)
	game_sidebar.sidebar_closed.connect(_on_sidebar_closed)

	# Hide modal initially
	game_over_modal.hide()

	# Dynamic grid sizing
	grid_center.resized.connect(_resize_grid)
	call_deferred("_resize_grid")

	# Apply theme
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)

	# Dev toolbar (debug builds only)
	if OS.is_debug_build():
		_setup_dev_toolbar()

func _setup_dev_toolbar() -> void:
	var bar := HBoxContainer.new()
	bar.name = "DevToolbar"
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -36
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)

	var complete_btn := Button.new()
	complete_btn.text = "Complete"
	complete_btn.custom_minimum_size = Vector2(80, 32)
	complete_btn.pressed.connect(func(): _trigger_game_complete("dev_trigger"))
	bar.add_child(complete_btn)

	var fill_btn := Button.new()
	fill_btn.text = "Fill"
	fill_btn.custom_minimum_size = Vector2(70, 32)
	fill_btn.pressed.connect(_debug_fill_grid)
	bar.add_child(fill_btn)

func _debug_fill_grid() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] == "":
				grid[row][col] = _random_letter()
	_update_grid_display()

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")


func _on_pause_pressed() -> void:
	is_paused = !is_paused
	pause_button.text = "▶ Resume\n(Free)" if is_paused else "⏸ Pause\n(Free)"

	if is_paused:
		drop_timer.paused = true
		word_label.text = lang_config.ui_strings.get("paused", "Game Paused")
		top_nav_bar.set_timer_paused(true)
		top_nav_bar.set_game_paused(true)
	else:
		drop_timer.paused = false
		word_label.text = ""
		top_nav_bar.set_timer_paused(false)
		top_nav_bar.set_game_paused(false)

	# Update button states to disable/enable based on pause state
	_update_shake_button()
	_update_swap_button()
	_update_draw_more_button()


func _on_sidebar_opened() -> void:
	# Pause the game
	drop_timer.paused = true


func _on_sidebar_closed() -> void:
	# Resume if game wasn't already paused
	if not is_paused:
		drop_timer.paused = false


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")


func _restart_with_language(code: String) -> void:
	GameSettings.current_language = code
	get_tree().reload_current_scene()


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
	point_labels.clear()

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
		var pt_row: Array = []
		for col in range(COLS):
			var btn := Button.new()
			btn.text = grid[row][col]
			btn.custom_minimum_size = Vector2(16, 16)
			btn.add_theme_font_size_override("font_size", ThemeConstants.TILE_FONT_SIZE)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.clip_contents = true
			grid_container.add_child(btn)

			# Spacey theme colors: white text on blue background
			# Apply AFTER adding to scene tree for proper initialization
			btn.add_theme_color_override("font_color", ThemeConstants.TILE_FONT_COLOR)
			btn.add_theme_color_override("font_hover_color", ThemeConstants.TILE_FONT_COLOR)
			btn.add_theme_color_override("font_pressed_color", ThemeConstants.TILE_FONT_COLOR)
			btn.add_theme_color_override("font_disabled_color", ThemeConstants.TILE_FONT_DISABLED_COLOR)

			var tile_style := ThemeConstants.create_tile_stylebox()
			btn.add_theme_stylebox_override("normal", tile_style)
			btn.add_theme_stylebox_override("hover", tile_style)
			btn.add_theme_stylebox_override("pressed", tile_style)
			btn.add_theme_stylebox_override("disabled", tile_style)
			btn.add_theme_stylebox_override("focus", tile_style)

			# Point value subscript (bottom-right, like Scrabble tiles)
			var pt_label := Label.new()
			pt_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			pt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			pt_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			pt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pt_label.add_theme_color_override("font_color", ThemeConstants.POINT_LABEL_COLOR)
			btn.add_child(pt_label)
			_update_point_label(pt_label, grid[row][col])

			btn_row.append(btn)
			pt_row.append(pt_label)
		buttons.append(btn_row)
		point_labels.append(pt_row)


func _resize_grid() -> void:
	if buttons.is_empty():
		return
	var h_sep: int = grid_container.get_theme_constant("h_separation")
	var v_sep: int = grid_container.get_theme_constant("v_separation")
	var avail: Vector2 = grid_center.size
	var cell_w: float = (avail.x - (COLS - 1) * h_sep) / COLS
	var cell_h: float = (avail.y - (ROWS - 1) * v_sep) / ROWS

	# Detect landscape mode (width > height)
	var is_landscape: bool = avail.x > avail.y

	# Allow rectangular cells to better utilize screen space
	var cell_width: float = floorf(cell_w)
	var cell_height: float = floorf(cell_h)

	# In landscape mode, cap cell width to prevent grid from spanning full screen
	# Use height as the constraint and make cells roughly square
	if is_landscape:
		var max_cell_width: float = cell_height * 1.1  # Allow slight width dominance
		if cell_width > max_cell_width:
			cell_width = max_cell_width

	# Ensure minimum size
	if cell_width < 16.0:
		cell_width = 16.0
	if cell_height < 16.0:
		cell_height = 16.0

	# In portrait mode, limit aspect ratio to prevent overly tall cells (max 1.6:1)
	if not is_landscape and cell_height > cell_width * 1.6:
		cell_height = cell_width * 1.6

	# Font size based on the smaller dimension for readability
	var base_size: float = minf(cell_width, cell_height)
	var font_size: int = int(base_size * 0.55)
	var pt_font_size: int = int(base_size * 0.22)

	for row in range(ROWS):
		for col in range(COLS):
			var btn: Button = buttons[row][col]
			btn.custom_minimum_size = Vector2(cell_width, cell_height)
			btn.add_theme_font_size_override("font_size", font_size)
			if not point_labels.is_empty():
				point_labels[row][col].add_theme_font_size_override("font_size", pt_font_size)


func _seed_words() -> void:
	var empty_rows: int = ROWS - INITIAL_FILL_ROWS
	var words: Array = lang_config.seed_words.duplicate()
	words.shuffle()

	# Guarantee at least 3 words are placed, try for up to 5
	var target_count: int = 3 + randi() % 3
	var placed_count: int = 0
	var max_attempts: int = 50

	for attempt in range(max_attempts):
		if placed_count >= target_count or words.is_empty():
			break

		var word: String = words.pop_front()
		var placed: bool = false

		for _retry in range(20):
			var path: Array = _find_seed_path(word.length(), empty_rows)
			if path.is_empty():
				continue

			# Check path doesn't overlap existing seed letters
			var conflicts: bool = false
			for pos in path:
				if grid[pos.y][pos.x] != "":
					conflicts = true
					break
			if conflicts:
				continue

			# Place the word along the path
			for i in range(word.length()):
				grid[path[i].y][path[i].x] = word[i]
			placed = true
			placed_count += 1
			break

		if not placed and placed_count < 3:
			words.append(word)


## Build a random adjacent-cell path of the given length within the filled rows.
## Returns an Array of Vector2i positions, or empty array on failure.
func _find_seed_path(length: int, empty_rows: int) -> Array:
	var start_row: int = empty_rows + randi() % INITIAL_FILL_ROWS
	var start_col: int = randi() % COLS

	var path: Array = [Vector2i(start_col, start_row)]
	var visited: Dictionary = {Vector2i(start_col, start_row): true}

	# All 8 adjacent directions
	var neighbor_offsets: Array = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1,  0),                  Vector2i(1,  0),
		Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
	]

	for _i in range(1, length):
		var shuffled: Array = neighbor_offsets.duplicate()
		shuffled.shuffle()

		var found: bool = false
		for offset in shuffled:
			var next: Vector2i = path[path.size() - 1] + offset
			if next.x >= 0 and next.x < COLS and next.y >= empty_rows and next.y < ROWS:
				if not visited.has(next):
					path.append(next)
					visited[next] = true
					found = true
					break

		if not found:
			return []

	return path


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
		var adjusted_target: float = lang_config.target_vowel_ratio * GameSettings.get_vowel_ratio_multiplier()
		need_vowel = ratio < adjusted_target

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
	# Rescue word system is disabled in hard mode
	if not GameSettings.is_rescue_enabled():
		_rescue_word = ""
		return

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
	# Always block input when game is over
	if game_over:
		return

	# Cancel targeting modes with ESC (only when not paused)
	if not is_paused and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_swap_targeting:
			_cancel_swap_targeting()
			return

	# Debug keys to test animations (development only, works even when paused)
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_W and Input.is_key_pressed(KEY_CTRL):
			_trigger_game_complete("dev_win")
			return
		if event.keycode == KEY_L and Input.is_key_pressed(KEY_CTRL):
			_trigger_game_complete("dev_lose")
			return

	# Block word selection when paused, but allow UI buttons to work
	if is_paused:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var cell := _cell_at(event.global_position)
			if cell != Vector2i(-1, -1):
				# Handle targeting modes
				if is_swap_targeting:
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

	# Mark game as started on first scored word
	game_started = true

	var points: int = _score_word(word)
	score += points
	word_scored.emit(points, word.length())
	_update_score_display()
	_update_shake_button()
	_update_swap_button()
	_update_draw_more_button()

	# Update combo streak
	if word.length() >= GameConstants.COMBO_THRESHOLD:
		combo_streak += 1
	else:
		combo_streak = 0

	# Check for drop speed reset
	if word.length() >= GameConstants.RATCHET_RESET_WORD_LENGTH:
		_reset_drop_speed()

	# Build feedback text
	var length_mult: int = GameConstants.WORD_MULTIPLIERS.get(
		word.length(), GameConstants.WORD_MULTIPLIER_DEFAULT)
	var feedback: String = "+%d" % points
	if length_mult > 1:
		feedback += " (%dx)" % length_mult
	if combo_streak > 1:
		feedback += " " + lang_config.ui_strings["streak"] % combo_streak
	word_label.text = feedback

	# Track word and tiles cleared
	StatsManager.record_word(word, selected_path.size())

	# Play word score sound
	if word_score_sound and word_score_sound.stream:
		word_score_sound.play()

	# Clear the selected cells
	for cell in selected_path:
		grid[cell.y][cell.x] = ""

	await _apply_gravity_with_animation()

	# Check for win conditions
	if _is_grid_empty():
		_trigger_game_complete("grid_cleared")
		return

	# Check for game over (board full)
	if _is_grid_full():
		_trigger_game_complete("board_full")
		return

	# After clearing, check if a rescue is needed for upcoming drops
	if not _find_any_word_on_grid():
		_plan_rescue_word()
	else:
		_clear_rescue()


func _score_word(word: String) -> int:
	var letter_sum: int = 0
	for ch in word:
		letter_sum += lang_config.letter_points.get(ch, 1)

	# Exponential length multiplier
	var length_mult: int = GameConstants.WORD_MULTIPLIERS.get(
		word.length(), GameConstants.WORD_MULTIPLIER_DEFAULT)

	# Combo streak multiplier
	var combo_mult: float = 1.0 + combo_streak * GameConstants.COMBO_MULTIPLIER_PER_STREAK
	combo_mult = minf(combo_mult, GameConstants.COMBO_MULTIPLIER_MAX)

	return int(letter_sum * length_mult * combo_mult)


# --- Shake Button ---

func _on_shake_pressed() -> void:
	if game_over or is_paused:
		return

	if score < SHAKE_COST:
		word_label.text = lang_config.ui_strings["need_shake"] % SHAKE_COST
		return

	score -= SHAKE_COST
	StatsManager.record_powerup("shake")
	_update_score_display()
	_update_shake_button()
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
	await _apply_gravity_with_animation()

	# Check for win conditions after shaking
	if _is_grid_empty():
		_trigger_game_complete("grid_cleared_shake")
		return

	# Check for game over (board full)
	if _is_grid_full():
		_trigger_game_complete("board_full_shake")
		return

	# After shaking, check if we need a rescue word
	if not _find_any_word_on_grid():
		_plan_rescue_word()
	else:
		_clear_rescue()


# --- Swap Button ---

func _on_swap_pressed() -> void:
	if game_over or is_paused:
		return

	if score < SWAP_COST:
		word_label.text = lang_config.ui_strings["need_swap"] % SWAP_COST
		return

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
		# Step 2: select second tile (any tile on the board)
		if cell == swap_first_cell:
			return

		var first := swap_first_cell

		# Deduct cost and exit targeting mode before animation
		score -= SWAP_COST
		StatsManager.record_powerup("swap")
		_update_score_display()
		_update_shake_button()
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
	await _apply_gravity_with_animation()

	# Check win conditions
	if _is_grid_empty():
		_trigger_game_complete("grid_cleared_swap")
		return

	# Check for game over (board full)
	if _is_grid_full():
		_trigger_game_complete("board_full_swap")
		return

	# Check if rescue needed
	if not _find_any_word_on_grid():
		_plan_rescue_word()
	else:
		_clear_rescue()


# --- Draw More Button ---

func _on_draw_more_pressed() -> void:
	if game_over or is_paused:
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
	StatsManager.record_powerup("draw")
	_update_score_display()
	_update_shake_button()
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
	await _apply_gravity_with_animation()

	# Show feedback
	word_label.text = lang_config.ui_strings["draw_more_success"] % [letters_to_draw, DRAW_MORE_COST]

	# Check for win conditions
	if _is_grid_empty():
		_trigger_game_complete("grid_cleared_draw")
		return

	# Check for game over (board full)
	if _is_grid_full():
		_trigger_game_complete("board_full_draw")
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


func _apply_gravity_with_animation() -> void:
	# Calculate final positions for each tile after gravity
	var fall_data: Array = []  # Array of {from_row, to_row, col, letter}

	for col in range(COLS):
		# Collect non-empty letters and their current rows
		var tiles: Array = []  # Array of {row, letter}
		for row in range(ROWS - 1, -1, -1):
			if grid[row][col] != "":
				tiles.append({"row": row, "letter": grid[row][col]})

		# Calculate where each tile will land (bottom-up packing)
		for i in range(tiles.size()):
			var old_row: int = tiles[i].row
			var new_row: int = ROWS - 1 - i  # Pack from bottom
			if old_row != new_row:
				fall_data.append({
					"from_row": old_row,
					"to_row": new_row,
					"col": col,
					"letter": tiles[i].letter,
					"distance": new_row - old_row  # Positive = falling down
				})

	# If nothing moves, just apply gravity instantly
	if fall_data.is_empty():
		_apply_gravity()
		_update_grid_display()
		return

	# Create visual duplicates for falling tiles
	var falling_tiles: Array = []  # Array of Panel nodes

	for data in fall_data:
		var source_btn: Button = buttons[data.from_row][data.col]
		var dest_btn: Button = buttons[data.to_row][data.col]

		# Create a Panel to match button appearance
		var tile_visual := Panel.new()
		tile_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Create background style matching button
		var stylebox := ThemeConstants.create_tile_stylebox()
		stylebox.content_margin_left = 4.0
		stylebox.content_margin_right = 4.0
		stylebox.content_margin_top = 4.0
		stylebox.content_margin_bottom = 4.0
		tile_visual.add_theme_stylebox_override("panel", stylebox)

		# Add letter label
		var letter_label := Label.new()
		letter_label.text = data.letter
		letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		letter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letter_label.add_theme_color_override("font_color", ThemeConstants.TILE_FONT_COLOR)

		# Get font size from source button
		var font_size: int = source_btn.get_theme_font_size("font_size")
		letter_label.add_theme_font_size_override("font_size", font_size)
		tile_visual.add_child(letter_label)

		# Add point value subscript
		var pt_label := Label.new()
		pt_label.text = str(lang_config.letter_points.get(data.letter, 1))
		pt_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		pt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pt_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		pt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pt_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		pt_label.add_theme_font_size_override("font_size", int(font_size * 0.4))
		tile_visual.add_child(pt_label)

		# Position at source button's global position
		tile_visual.global_position = source_btn.global_position
		tile_visual.size = source_btn.size
		tile_visual.z_index = 10  # Draw on top

		# Add to scene
		add_child(tile_visual)
		falling_tiles.append({
			"visual": tile_visual,
			"target_pos": dest_btn.global_position,
			"duration": 0.15 + (data.distance * 0.05)
		})

	# Hide letters in source positions (they'll show in destination after gravity)
	for data in fall_data:
		buttons[data.from_row][data.col].modulate.a = 0.0

	# Apply gravity to data grid
	_apply_gravity()

	# Update grid display (but destination buttons are still invisible)
	_update_grid_display()

	# Hide destination buttons during animation
	for data in fall_data:
		buttons[data.to_row][data.col].modulate.a = 0.0

	# Animate the visual duplicates
	var tween := create_tween().set_parallel(true)

	for tile_data in falling_tiles:
		tween.tween_property(
			tile_data.visual,
			"global_position",
			tile_data.target_pos,
			tile_data.duration
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Wait for animations to complete
	await tween.finished

	# Clean up: remove visual duplicates and restore button visibility
	for tile_data in falling_tiles:
		tile_data.visual.queue_free()

	# Restore all button visibility
	for row in range(ROWS):
		for col in range(COLS):
			buttons[row][col].modulate.a = 1.0


func _start_drop_timer() -> void:
	drop_timer = Timer.new()
	drop_timer.wait_time = current_drop_interval
	drop_timer.timeout.connect(_drop_letter)
	add_child(drop_timer)
	drop_timer.start()


func _ratchet_drop_speed() -> void:
	# Temporarily disabled until tutorial explains the mechanic (Issue #148)
	return

	current_drop_interval = maxf(
		current_drop_interval - GameConstants.RATCHET_SPEEDUP,
		GameConstants.RATCHET_MIN_INTERVAL)
	drop_timer.wait_time = current_drop_interval


func _reset_drop_speed() -> void:
	current_drop_interval = base_drop_interval
	drops_since_start = 0
	if drop_timer:
		drop_timer.wait_time = current_drop_interval


func _drop_letter() -> void:
	if game_over:
		return

	# Find columns that have space (top row is empty)
	var open_cols: Array = []
	for col in range(COLS):
		if grid[0][col] == "":
			open_cols.append(col)

	if open_cols.is_empty():
		_trigger_game_complete("no_open_cols")
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

	# Mark game as started on first tile drop
	game_started = true

	await _apply_gravity_with_animation()

	# Drop speed ratchet
	drops_since_start += 1
	if drops_since_start % GameConstants.RATCHET_DROPS_PER_STEP == 0:
		_ratchet_drop_speed()

	# Play drop sound
	if drop_sound and drop_sound.stream:
		drop_sound.play()

	# Check for game over (board full)
	if _is_grid_full():
		_trigger_game_complete("board_full_drop")
		return


func _is_grid_empty() -> bool:
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] != "":
				return false
	return true


func _is_grid_full() -> bool:
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] == "":
				return false
	return true


func _trigger_game_complete(reason: String = "unknown") -> void:
	game_over = true
	drop_timer.stop()

	# Capture previous high score BEFORE ending session
	var previous_high_score: int = StatsManager.high_score

	# End session (this may update the high score)
	StatsManager.end_session(score, {"loss_reason": reason})

	# Determine if this is a new high score
	var is_new_high_score: bool = score > previous_high_score

	# Play appropriate animation based on high score achievement
	if is_new_high_score:
		_play_win_animation(is_new_high_score)
	else:
		_play_lose_animation(is_new_high_score)


func _update_grid_display() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			buttons[row][col].text = grid[row][col]
			if not point_labels.is_empty():
				_update_point_label(point_labels[row][col], grid[row][col])


# --- Visuals ---

func _update_selection_visuals() -> void:
	_clear_selection_visuals()

	var word: String = _get_selected_word()
	var long_enough: bool = selected_path.size() >= MIN_WORD_LENGTH
	word_label.text = word
	word_label.add_theme_color_override(
		"font_color",
		ThemeManager.get_color("text_primary") if long_enough else COLOR_TOO_SHORT
	)

	var highlight: Color = COLOR_SELECTED if long_enough else COLOR_TOO_SHORT
	for cell in selected_path:
		var btn: Button = buttons[cell.y][cell.x]
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_stylebox_override("normal", _make_stylebox(highlight))
		btn.add_theme_stylebox_override("hover", _make_stylebox(highlight))


func _clear_selection_visuals() -> void:
	# Restore default tile appearance (blue background, white text)
	var tile_style := ThemeConstants.create_tile_stylebox()

	for row in range(ROWS):
		for col in range(COLS):
			var btn: Button = buttons[row][col]
			btn.add_theme_color_override("font_color", ThemeConstants.TILE_FONT_COLOR)
			btn.add_theme_stylebox_override("normal", tile_style)
			btn.add_theme_stylebox_override("hover", tile_style)


func _make_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	return sb


func _update_point_label(pt_label: Label, letter: String) -> void:
	if letter == "":
		pt_label.text = ""
	else:
		pt_label.text = str(lang_config.letter_points.get(letter, 1))


func _update_score_display() -> void:
	top_nav_bar.update_score(score)


func _update_shake_button() -> void:
	shake_button.disabled = not game_started or score < SHAKE_COST or is_paused


func _update_swap_button() -> void:
	if is_swap_targeting:
		_set_button_content(swap_button, ICON_CANCEL, lang_config.ui_strings["cancel"])
		swap_button.disabled = is_paused
	else:
		_set_button_content(swap_button, ICON_SWAP, lang_config.ui_strings["swap"])
		swap_button.disabled = not game_started or score < SWAP_COST or is_paused


func _update_draw_more_button() -> void:
	draw_more_button.disabled = not game_started or score < DRAW_MORE_COST or is_paused


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


func _apply_theme() -> void:
	# Update background
	if background:
		background.color = ThemeManager.get_color("background")

	# Update game board panel
	if board_panel:
		var panel_style = board_panel.get_theme_stylebox("panel")
		if panel_style:
			panel_style.bg_color = ThemeManager.get_color("card_background")

	# Update word feedback label
	if word_label:
		word_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update game over modal
	if modal_panel:
		var style := StyleBoxFlat.new()
		style.bg_color = ThemeManager.get_color("card_background")
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		style.content_margin_left = 24
		style.content_margin_right = 24
		style.content_margin_top = 24
		style.content_margin_bottom = 24
		modal_panel.add_theme_stylebox_override("panel", style)
	if modal_message_label:
		modal_message_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
	for btn in [retry_button, quit_button]:
		if btn:
			btn.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
			for state_info in [
				["normal", "secondary_button"],
				["hover", "secondary_button_hover"],
				["pressed", "secondary_button_pressed"],
			]:
				var btn_style := StyleBoxFlat.new()
				btn_style.bg_color = ThemeManager.get_color(state_info[1])
				btn_style.corner_radius_top_left = 12
				btn_style.corner_radius_top_right = 12
				btn_style.corner_radius_bottom_left = 12
				btn_style.corner_radius_bottom_right = 12
				btn_style.content_margin_left = 16
				btn_style.content_margin_right = 16
				btn_style.content_margin_top = 12
				btn_style.content_margin_bottom = 12
				btn.add_theme_stylebox_override(state_info[0], btn_style)


# --- Win/Lose Animations ---

func _play_win_animation(is_new_high_score: bool) -> void:
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
	_show_game_over_modal(is_new_high_score)


func _play_lose_animation(is_new_high_score: bool) -> void:
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
	_show_game_over_modal(is_new_high_score)


func _show_game_over_modal(is_new_high_score: bool) -> void:
	# Play game complete sound when modal appears
	if game_complete_sound and game_complete_sound.stream:
		game_complete_sound.play()

	# Base message: "Game Complete" with score
	var base_message: String = lang_config.ui_strings.get("game_complete", "Game Complete!\nScore: %d") % score

	# If new high score, add congratulatory text and play win sound
	if is_new_high_score:
		modal_message_label.text = lang_config.ui_strings.get("new_high_score", "New High Score!\n") + base_message

		# Play game won sound after a brief delay
		await get_tree().create_timer(0.3).timeout
		if game_won_sound and game_won_sound.stream:
			game_won_sound.play()
	else:
		modal_message_label.text = base_message

	# Hide the separate score label since the message includes it
	modal_score_label.hide()

	# Update button labels
	retry_button.text = lang_config.ui_strings["play_again"]
	quit_button.text = lang_config.ui_strings["quit_to_menu"]

	# Ensure buttons don't auto-focus (prevents iOS zoom on focus)
	retry_button.release_focus()
	quit_button.release_focus()

	# Fade in modal
	game_over_modal.modulate.a = 0.0
	game_over_modal.show()
	var fade_tween := create_tween()
	fade_tween.tween_property(game_over_modal, "modulate:a", 1.0, 0.3)
