extends HBoxContainer

## Top navigation bar component with Exit and Pause buttons
## Emits signals that the parent scene can connect to

signal burger_pressed
signal pause_pressed

@onready var burger_button = %BurgerMenuButton
@onready var pause_button = %PauseButton
@onready var word_score_label = %WordScoreLabel
@onready var left_container: Control = %"LeftContainer"
@onready var game_info: HBoxContainer = $GameInfo

var is_showing_word_score: bool = false
var word_score_timer: Timer
var active_word_score_tween: Tween = null
var lang_config: LanguageConfig

func _ready() -> void:
	lang_config = LanguageConfig.get_config(GameSettings.current_language)

	# Hide burger menu on web — React shell owns navigation
	if OS.has_feature("web"):
		burger_button.visible = false
		left_container.custom_minimum_size = Vector2(80, 0)
	else:
		left_container.custom_minimum_size = Vector2(220, 0)

	burger_button.pressed.connect(_on_burger_pressed)
	pause_button.pressed.connect(_on_pause_pressed)

	# Hide GameInfo on non-web platforms (score/timer shown below board)
	if game_info:
		game_info.visible = OS.has_feature("web")

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

func update_score_label_text(text: String) -> void:
	# Delegate to GameInfo if available (web)
	if game_info and game_info.has_method("update_score"):
		game_info.update_score(text)

func show_word_score(text: String) -> void:
	word_score_label.text = text
	word_score_label.visible = true
	await get_tree().create_timer(1.2).timeout
	word_score_label.visible = false

func _on_word_score_timeout() -> void:
	is_showing_word_score = false
	word_score_label.visible = false

func set_game_paused(paused: bool) -> void:
	if is_showing_word_score:
		word_score_timer.paused = paused
