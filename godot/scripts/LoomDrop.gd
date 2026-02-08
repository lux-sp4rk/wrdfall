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

const COLOR_SELECTED: Color = Color(0.35, 0.65, 1.0)
const COLOR_TOO_SHORT: Color = Color(0.7, 0.7, 0.7)


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	dictionary = DictionaryService.new()
	_initialize_grid()
	_update_score_display()


func _initialize_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	grid_container.columns = COLS
	grid.clear()
	buttons.clear()

	var empty_rows: int = ROWS - INITIAL_FILL_ROWS
	for row in range(ROWS):
		var grid_row: Array = []
		var btn_row: Array = []
		for col in range(COLS):
			var letter: String = "" if row < empty_rows else _random_letter()
			var btn := Button.new()
			btn.text = letter
			btn.custom_minimum_size = Vector2(48, 48)
			btn.add_theme_font_size_override("font_size", 24)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid_container.add_child(btn)
			grid_row.append(letter)
			btn_row.append(btn)
		grid.append(grid_row)
		buttons.append(btn_row)


func _random_letter() -> String:
	return letter_bag[randi() % letter_bag.length()]


# --- Input handling ---

func _input(event: InputEvent) -> void:
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
	_spawn_new_letters()
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


func _spawn_new_letters() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			if grid[row][col] == "":
				grid[row][col] = _random_letter()


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
