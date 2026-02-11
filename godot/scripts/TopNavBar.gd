extends HBoxContainer

## Top navigation bar component with Exit and Pause buttons
## Emits signals that the parent scene can connect to

signal exit_pressed
signal pause_pressed

@onready var exit_button = %ExitButton
@onready var pause_button = %PauseButton
@onready var score_label = %ScoreLabel

var is_paused: bool = false

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	pause_button.pressed.connect(_on_pause_pressed)

func _on_exit_pressed() -> void:
	exit_pressed.emit()

func _on_pause_pressed() -> void:
	is_paused = !is_paused
	pause_button.text = "Resume" if is_paused else "Pause"
	pause_pressed.emit()

func update_score(score: int) -> void:
	score_label.text = "Score: %d" % score

func set_paused(paused: bool) -> void:
	is_paused = paused
	pause_button.text = "Resume" if is_paused else "Pause"
