extends Control

signal resume_pressed
signal quit_pressed

@onready var title_label: Label = %TitleLabel
@onready var tip_label: Label = %TipLabel
@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton
@onready var tiles_container: Node2D = %TilesContainer
@onready var background: ColorRect = %Background

var _tips: Array = []
var _current_tip_index: int = 0
var _tip_timer: Timer
var _spawn_timer: Timer
var _max_tiles: int = 15
var _active_tiles: int = 0
var _is_visible: bool = false
var _letter_pool: Array = []
var _overlay_tween: Tween = null

const TILE_SIZE: int = 44
const FALL_DURATION_MIN: float = 5.0
const FALL_DURATION_MAX: float = 10.0
const SPAWN_INTERVAL: float = 0.35
const TIP_INTERVAL: float = 4.0
const TIP_FADE_DURATION: float = 0.3


func _ready() -> void:
	resume_button.pressed.connect(func(): resume_pressed.emit())
	quit_button.pressed.connect(func(): quit_pressed.emit())

	_tip_timer = Timer.new()
	_tip_timer.wait_time = TIP_INTERVAL
	_tip_timer.one_shot = false
	_tip_timer.timeout.connect(_on_tip_timer_timeout)
	add_child(_tip_timer)

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = SPAWN_INTERVAL
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	# Initialize hidden
	modulate.a = 0.0
	visible = false


func setup(tips: Array, letter_weights: Dictionary, paused_text: String, resume_text: String, quit_text: String) -> void:
	_tips = tips.duplicate()
	_tips.shuffle()
	_build_letter_pool(letter_weights)
	title_label.text = paused_text
	resume_button.text = resume_text
	quit_button.text = quit_text
	_current_tip_index = 0
	_update_tip_text(false)


func show_overlay() -> void:
	if _is_visible:
		return
	_is_visible = true
	visible = true
	_active_tiles = 0
	# Clear any existing tiles
	for child in tiles_container.get_children():
		if is_instance_valid(child):
			child.queue_free()

	# Fade in
	if _overlay_tween:
		_overlay_tween.kill()
		_overlay_tween = null
	_overlay_tween = create_tween()
	_overlay_tween.tween_property(self, "modulate:a", 1.0, 0.2)

	_tip_timer.start()
	if _tips.size() > 0:
		_current_tip_index = 0
		_update_tip_text(false)

	_spawn_timer.start()


func hide_overlay() -> void:
	if not _is_visible:
		return
	_is_visible = false
	_tip_timer.stop()
	_spawn_timer.stop()

	# Fade out
	if _overlay_tween:
		_overlay_tween.kill()
		_overlay_tween = null
	_overlay_tween = create_tween()
	_overlay_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await _overlay_tween.finished

	if not _is_visible:
		visible = false
	# Clean up tiles
	for child in tiles_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	_active_tiles = 0
	_overlay_tween = null


func _on_tip_timer_timeout() -> void:
	if _tips.is_empty():
		return
	_current_tip_index = (_current_tip_index + 1) % _tips.size()
	_update_tip_text(true)


func _update_tip_text(animate: bool) -> void:
	if _tips.is_empty():
		tip_label.text = ""
		return

	var tip_text: String = "💡 " + _tips[_current_tip_index]
	if not animate:
		tip_label.text = tip_text
		return

	# Fade out, change text, fade in
	var tween := create_tween()
	tween.tween_property(tip_label, "modulate:a", 0.0, TIP_FADE_DURATION)
	tween.tween_callback(func(): tip_label.text = tip_text)
	tween.tween_property(tip_label, "modulate:a", 1.0, TIP_FADE_DURATION)


func _on_spawn_timer_timeout() -> void:
	if not _is_visible or _active_tiles >= _max_tiles:
		return

	var tile := _create_falling_tile()
	tiles_container.add_child(tile)
	_active_tiles += 1

	var duration := randf_range(FALL_DURATION_MIN, FALL_DURATION_MAX)
	var target_y := size.y + TILE_SIZE * 2
	var drift := randf_range(-40, 40)

	var tween := create_tween()
	tween.tween_property(tile, "position:y", target_y, duration).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(tile, "position:x", tile.position.x + drift, duration).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(tile, "modulate:a", 0.0, duration * 0.3).set_delay(duration * 0.7)
	tween.parallel().tween_property(tile, "rotation_degrees", randf_range(-25, 25), duration).set_trans(Tween.TRANS_LINEAR)

	tween.finished.connect(func():
		if is_instance_valid(tile):
			tile.queue_free()
		_active_tiles = maxi(_active_tiles - 1, 0)
	)


func _create_falling_tile() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	panel.size = Vector2(TILE_SIZE, TILE_SIZE)

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeConstants.TILE_BG_COLOR
	style.bg_color.a = 0.15
	style.border_color = ThemeConstants.TILE_BORDER_COLOR
	style.border_color.a = 0.1
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = _get_random_letter()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
	label.add_theme_font_size_override("font_size", 22)
	label.anchors_preset = Control.PRESET_FULL_RECT
	panel.add_child(label)

	# Random x position within width (allow slight overflow)
	var x_pos := randf_range(-TILE_SIZE * 0.5, maxf(size.x - TILE_SIZE * 0.5, 1.0))
	panel.position = Vector2(x_pos, -TILE_SIZE)
	panel.modulate.a = randf_range(0.1, 0.3)
	panel.rotation_degrees = randf_range(-10, 10)

	return panel


func _build_letter_pool(letter_weights: Dictionary) -> void:
	_letter_pool.clear()
	for letter in letter_weights.keys():
		var weight: int = letter_weights[letter]
		for i in range(weight):
			_letter_pool.append(letter)


func _get_random_letter() -> String:
	if _letter_pool.is_empty():
		return "A"
	return _letter_pool[randi() % _letter_pool.size()]
