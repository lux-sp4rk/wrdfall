extends Node

var current_language: String = "en"
var difficulty: String = "easy"

const DIFFICULTIES = {
	"easy": 10.0,
	"hard": 8.0
}

func get_drop_interval() -> float:
	return DIFFICULTIES.get(difficulty, 10.0)

func _ready() -> void:
	# Load saved settings if any
	pass
