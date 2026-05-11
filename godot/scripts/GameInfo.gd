extends HBoxContainer

@onready var score_label: Label = $ScoreLabel
@onready var sand_timer: Control = $SandTimer

func update_score(text: String) -> void:
	score_label.text = text

func set_drop_timer(timer: Timer) -> void:
	sand_timer.set_drop_timer(timer)

func set_paused(paused: bool) -> void:
	sand_timer.set_paused(paused)
