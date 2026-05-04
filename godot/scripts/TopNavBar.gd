extends HBoxContainer

## Top navigation bar component with Exit and Pause buttons
## Emits signals that the parent scene can connect to

signal burger_pressed
signal pause_pressed

@onready var burger_button = %BurgerMenuButton
@onready var pause_button = %PauseButton
@onready var score_label = %ScoreLabel
@onready var high_score_label = %HighScoreLabel
@onready var timer_label = %TimerLabel
@onready var word_score_label = %WordScoreLabel
@onready var high_score_notification_label = %HighScoreNotificationLabel

var drop_timer_ref: Timer = null
var is_showing_word_score: bool = false
var word_score_timer: Timer
var active_word_score_tween: Tween = null
var active_notification_tween: Tween = null
var has_shown_high_score_notification: bool = false
var lang_config: LanguageConfig
func _ready() -> void:
	lang_config = LanguageConfig.get_config(GameSettings.current_language)

	# Hide burger menu on web — React shell owns navigation
	if OS.has_feature("web"):
		burger_button.visible = false

	burger_button.pressed.connect(_on_burger_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	_update_high_score_display()
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)
	set_process(false)  # Disable processing until timer is set

	# Create word score display timer (2 seconds)
	word_score_timer = Timer.new()
	word_score_timer.wait_time = 2.0
	word_score_timer.one_shot = true
	word_score_timer.timeout.connect(_on_word_score_timeout)
	add_child(word_score_timer)

func _on_burger_pressed() -> void:
	burger_pressed.emit()

func _on_pause_pressed() -> void:
	pause_pressed.emit()

func set_pause_label(paused: bool) -> void:
	pause_button.text = "Resume" if paused else "Pause"

func update_score(score: int) -> void:
	score_label.text = "Score: %d" % score
	# Update high score display if current score beats it
	if score > StatsManager.high_score:
		_update_high_score_display(score)
		if not has_shown_high_score_notification:
			_show_high_score_notification()

func set_drop_timer(timer: Timer) -> void:
	drop_timer_ref = timer
	set_process(true)  # Enable processing when timer is set

func set_timer_paused(paused: bool) -> void:
	if paused:
		set_process(false)
	else:
		set_process(true)

func _process(_delta: float) -> void:
	if not is_showing_word_score and drop_timer_ref and not drop_timer_ref.is_stopped():
		var time_left := ceili(drop_timer_ref.time_left)
		timer_label.text = "%ds" % time_left

func _update_high_score_display(current_score: int = 0) -> void:
	var high_score := maxi(StatsManager.high_score, current_score)
	if high_score > 0:
		high_score_label.text = "Best: %d" % high_score
	else:
		high_score_label.text = ""

func _apply_theme() -> void:
	# Update Burger button
	for btn in [burger_button]:
		if btn:
			var normal_style = btn.get_theme_stylebox("normal")
			if normal_style:
				normal_style.bg_color = ThemeManager.get_color("secondary_button")

			var hover_style = btn.get_theme_stylebox("hover")
			if hover_style:
				hover_style.bg_color = ThemeManager.get_color("secondary_button_hover")

			var pressed_style = btn.get_theme_stylebox("pressed")
			if pressed_style:
				pressed_style.bg_color = ThemeManager.get_color("secondary_button_pressed")

	# Update score labels
	if score_label:
		score_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	if high_score_label:
		high_score_label.add_theme_color_override("font_color", ThemeManager.get_color("text_secondary"))

	if high_score_notification_label:
		high_score_notification_label.add_theme_color_override("font_color", ThemeManager.get_color("accent"))

	# Update timer and word score labels
	if timer_label:
		timer_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	if word_score_label:
		word_score_label.add_theme_color_override("font_color", ThemeManager.get_color("accent"))

func _calculate_phrase(word_length: int) -> String:
	match word_length:
		3: return "NICE!"
		4: return "GREAT!"
		5: return "AMAZING!"
		6: return "FANTASTIC!"
		_: return "SPECTACULAR!"  # 7+ letters

func _animate_word_score(word_length: int) -> void:
	# Kill previous tween if still running
	if active_word_score_tween:
		active_word_score_tween.kill()

	active_word_score_tween = create_tween()

	# Set font size based on word length
	var font_size := 32
	match word_length:
		3: font_size = 32
		4: font_size = 36
		_: font_size = 42
	word_score_label.add_theme_font_size_override("font_size", font_size)

	# Reset transform
	word_score_label.scale = Vector2.ONE
	word_score_label.rotation_degrees = 0

	# Animate based on word length
	match word_length:
		3:  # NICE! - gentle bounce
			active_word_score_tween.tween_property(word_score_label, "scale", Vector2(1.2, 1.2), 0.2)
			active_word_score_tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.2)

		4:  # GREAT! - bigger bounce with rotation
			active_word_score_tween.tween_property(word_score_label, "scale", Vector2(1.4, 1.4), 0.2)
			active_word_score_tween.tween_property(word_score_label, "rotation_degrees", 5, 0.1)
			active_word_score_tween.tween_property(word_score_label, "rotation_degrees", -5, 0.1)
			active_word_score_tween.tween_property(word_score_label, "rotation_degrees", 0, 0.1)
			active_word_score_tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.2)

		_:  # AMAZING!/FANTASTIC!/SPECTACULAR! - big celebration
			active_word_score_tween.tween_property(word_score_label, "scale", Vector2(1.6, 1.6), 0.3)
			active_word_score_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			active_word_score_tween.tween_property(word_score_label, "scale", Vector2(1.0, 1.0), 0.5)

func show_word_score(points: int, word_length: int) -> void:
	# No-op: TopNavBar word score animation removed per PR #267 review.
	# Word score feedback now uses FloatingScoreLabel at the board only.
	pass

func _on_word_score_timeout() -> void:
	is_showing_word_score = false
	word_score_label.visible = false
	timer_label.visible = true

	# Clean up theme overrides and transform state
	word_score_label.remove_theme_font_size_override("font_size")
	word_score_label.scale = Vector2.ONE
	word_score_label.rotation_degrees = 0

func _show_high_score_notification() -> void:
	if active_notification_tween:
		active_notification_tween.kill()

	has_shown_high_score_notification = true
	high_score_notification_label.text = "🎉 " + lang_config.ui_strings.get("new_best", "New Best!")
	high_score_notification_label.visible = true
	high_score_notification_label.modulate.a = 1.0
	high_score_notification_label.scale = Vector2(0.8, 0.8)

	active_notification_tween = create_tween()
	active_notification_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	active_notification_tween.tween_property(high_score_notification_label, "scale", Vector2(1.15, 1.15), 0.3)
	active_notification_tween.tween_property(high_score_notification_label, "scale", Vector2(1.0, 1.0), 0.2)

	await get_tree().create_timer(2.0).timeout

	if not high_score_notification_label:
		return

	var fade_tween := create_tween()
	fade_tween.tween_property(high_score_notification_label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await fade_tween.finished

	if high_score_notification_label:
		high_score_notification_label.visible = false

func set_game_paused(paused: bool) -> void:
	if is_showing_word_score:
		word_score_timer.paused = paused
