extends HBoxContainer

## Top navigation bar component with Exit and Pause buttons
## Emits signals that the parent scene can connect to

signal exit_pressed
signal pause_pressed

@onready var exit_button = %ExitButton
@onready var pause_button = %PauseButton
@onready var score_label = %ScoreLabel
@onready var high_score_label = %HighScoreLabel

var is_paused: bool = false

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	_update_high_score_display()
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)

func _on_exit_pressed() -> void:
	exit_pressed.emit()

func _on_pause_pressed() -> void:
	is_paused = !is_paused
	pause_button.text = "Resume" if is_paused else "Pause"
	pause_pressed.emit()

func update_score(score: int) -> void:
	score_label.text = "Score: %d" % score
	# Update high score display if current score beats it
	if score > StatsManager.high_score:
		_update_high_score_display(score)

func set_paused(paused: bool) -> void:
	is_paused = paused
	pause_button.text = "Resume" if is_paused else "Pause"

func _update_high_score_display(current_score: int = 0) -> void:
	var high_score := maxi(StatsManager.high_score, current_score)
	if high_score > 0:
		high_score_label.text = "Best: %d" % high_score
	else:
		high_score_label.text = ""

func _apply_theme() -> void:
	# Update Exit and Pause buttons
	for btn in [exit_button, pause_button]:
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
