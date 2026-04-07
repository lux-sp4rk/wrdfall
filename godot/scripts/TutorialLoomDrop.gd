extends "res://scripts/LoomDrop.gd"
class_name TutorialLoomDrop

## Tutorial Loom Drop
## Extends the main LoomDrop game with tutorial-specific hooks
## Handles input gating, board presets, and tutorial state integration

# Tutorial controller reference
var tutorial_controller: TutorialController = null

# Tutorial state
var is_tutorial_mode: bool = false
var original_drop_interval: float = 0.0

# Demo mode
var demo_mode: bool = false
var demo_timer: Timer = null

# Custom signals
signal word_formed_in_tutorial(word: String, path: Array)
signal powerup_used_in_tutorial(powerup_name: String)

func _ready() -> void:
	# Call parent _ready but don't start drop timer yet
	# We'll handle initialization differently for tutorial
	
	# Load difficulty-based settings
	SHAKE_COST = GameSettings.get_power_up_cost("shake")
	SWAP_COST = GameSettings.get_power_up_cost("swap")
	DRAW_MORE_COST = GameSettings.get_power_up_cost("draw_more")

	base_drop_interval = GameSettings.get_drop_interval()
	current_drop_interval = base_drop_interval
	original_drop_interval = base_drop_interval

	lang_config = LanguageConfig.get_config(GameSettings.current_language)
	dictionary = DictionaryService.new(lang_config.wordlist_path, lang_config.extra_alpha)
	_build_weighted_bag()
	
	# Note: We don't call _initialize_grid() here - tutorial will set preset
	
	# Start tracking session stats
	StatsManager.start_session()

	# Set up icon buttons (must happen before update calls)
	_setup_icon_button(shake_button, ICON_SHAKE, lang_config.ui_strings["shake"])
	_setup_icon_button(swap_button, ICON_SWAP, lang_config.ui_strings["swap"])
	_setup_icon_button(draw_more_button, ICON_DRAW_MORE, lang_config.ui_strings["draw_more"])
	
	# Hide Draw More button if feature flag is disabled
	if not FeatureFlags.draw_more_enabled:
		draw_more_button.visible = false

	_update_score_display()
	_update_shake_button()
	_update_swap_button()
	_update_draw_more_button()
	
	# Don't start drop timer in tutorial mode
	# We'll create it but keep it paused
	_start_drop_timer()
	drop_timer.paused = true

	# Connect buttons
	shake_button.pressed.connect(_on_shake_pressed)
	swap_button.pressed.connect(_on_swap_pressed)
	draw_more_button.pressed.connect(_on_draw_more_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
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
	FeatureFlags.feature_flag_changed.connect(_on_feature_flag_changed)

func setup_for_tutorial(controller: TutorialController) -> void:
	"""Configure the game for tutorial mode."""
	tutorial_controller = controller
	is_tutorial_mode = true
	
	# Disable drop timer
	disable_drop_timer()
	
	# Give starting score for power-up demos
	score = 20
	_update_score_display()
	_update_shake_button()
	_update_swap_button()
	_update_draw_more_button()

func set_tutorial_board_preset(preset: Array) -> void:
	"""Set a pre-configured board state for the tutorial."""
	# Clear existing grid
	for child in grid_container.get_children():
		child.queue_free()

	grid_container.columns = COLS
	grid.clear()
	buttons.clear()
	point_labels.clear()

	# Copy preset to grid
	for row in range(ROWS):
		var grid_row: Array = []
		for col in range(COLS):
			if row < preset.size() and col < preset[row].size():
				grid_row.append(preset[row][col])
			else:
				grid_row.append("")
		grid.append(grid_row)

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

			# Apply theme colors
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

			# Point value subscript
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
	
	# Resize grid after creation
	call_deferred("_resize_grid")

func disable_drop_timer() -> void:
	"""Disable the drop timer for tutorial phases."""
	if drop_timer:
		drop_timer.paused = true
		drop_timer.stop()

func enable_drop_timer() -> void:
	"""Re-enable the drop timer (for testing/demo)."""
	if drop_timer:
		drop_timer.paused = false
		drop_timer.start()

func enable_demo_mode(enabled: bool, speed: float = 1.0) -> void:
	"""Enable auto-play demo mode."""
	demo_mode = enabled
	
	if demo_mode:
		_setup_demo_timer(speed)
	else:
		_cleanup_demo_timer()

func _setup_demo_timer(speed: float) -> void:
	"""Set up the demo auto-play timer."""
	_cleanup_demo_timer()
	
	demo_timer = Timer.new()
	demo_timer.wait_time = 2.0 / speed
	demo_timer.timeout.connect(_on_demo_tick)
	add_child(demo_timer)
	demo_timer.start()

func _cleanup_demo_timer() -> void:
	"""Clean up demo timer."""
	if demo_timer:
		demo_timer.stop()
		demo_timer.queue_free()
		demo_timer = null

func _on_demo_tick() -> void:
	"""Perform a demo action."""
	if not tutorial_controller:
		return
	
	var config = tutorial_controller.get_current_phase_config()
	if config.demo_path.is_empty():
		return
	
	# In a real implementation, this would simulate user input
	# For now, we just emit the signal that a word was formed
	if config.target_word != "":
		word_formed_in_tutorial.emit(config.target_word, config.demo_path)

# === Input Gating Override ===

func _input(event: InputEvent) -> void:
	"""Override input handling to support tutorial gating."""
	# Always block input when game is over
	if game_over:
		return
	
	# Block input in demo mode
	if demo_mode:
		return

	# Cancel targeting modes with ESC
	if not is_paused and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_swap_targeting:
			_cancel_swap_targeting()
			return

	# Debug keys (development only)
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_W and Input.is_key_pressed(KEY_CTRL):
			_trigger_game_complete("dev_win")
			return
		if event.keycode == KEY_L and Input.is_key_pressed(KEY_CTRL):
			_trigger_game_complete("dev_lose")
			return

	# Block word selection when paused
	if is_paused:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var cell := _cell_at(event.global_position)
			if cell != Vector2i(-1, -1):
				# Check tutorial gating
				if tutorial_controller and not tutorial_controller.is_input_allowed(event, cell):
					_show_blocked_feedback()
					return
				
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
			# Check tutorial gating for extension
			if tutorial_controller and not tutorial_controller.is_input_allowed(event, cell):
				return
			_extend_selection(cell)

func _show_blocked_feedback() -> void:
	"""Show feedback when input is blocked by tutorial gating."""
	word_label.text = lang_config.ui_strings.get("tutorial_follow_path", "Follow the highlighted path!")

# === Word Acceptance Override ===

func _accept_word(word: String) -> void:
	"""Override to integrate with tutorial progression."""
	# Call parent implementation
	super._accept_word(word)
	
	# Notify tutorial controller
	if tutorial_controller and not demo_mode:
		word_formed_in_tutorial.emit(word, selected_path.duplicate())
		tutorial_controller.on_word_formed(word, selected_path.duplicate())

# === Power-up Overrides ===

func _on_shake_pressed() -> void:
	"""Override to track power-up usage in tutorial."""
	super._on_shake_pressed()
	if tutorial_controller and not demo_mode:
		powerup_used_in_tutorial.emit("shake")
		tutorial_controller.on_powerup_used("shake")

func _on_swap_pressed() -> void:
	"""Override to track power-up usage in tutorial."""
	super._on_swap_pressed()
	if tutorial_controller and not demo_mode:
		powerup_used_in_tutorial.emit("swap")
		tutorial_controller.on_powerup_used("swap")

func _on_draw_more_pressed() -> void:
	"""Override to track power-up usage in tutorial."""
	super._on_draw_more_pressed()
	if tutorial_controller and not demo_mode:
		powerup_used_in_tutorial.emit("draw_more")
		tutorial_controller.on_powerup_used("draw_more")

# === Utility Methods ===

func get_button_at_cell(cell: Vector2i) -> Button:
	"""Get the button at a specific grid cell."""
	if cell.y >= 0 and cell.y < buttons.size():
		var row: Array = buttons[cell.y]
		if cell.x >= 0 and cell.x < row.size():
			return row[cell.x]
	return null

func reset_for_new_phase(preset: Array) -> void:
	"""Reset the board for a new tutorial phase."""
	# Clear selection
	_clear_selection_visuals()
	selected_path.clear()
	is_selecting = false
	is_swap_targeting = false
	swap_first_cell = Vector2i(-1, -1)
	
	# Reset score display
	word_label.text = ""
	
	# Set new board preset
	set_tutorial_board_preset(preset)

func cleanup() -> void:
	"""Clean up tutorial-specific resources."""
	_cleanup_demo_timer()
