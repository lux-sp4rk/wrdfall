extends Node

var current_language: String = "en"
var difficulty: String = "normal"

const DIFFICULTIES = {
	"normal": 8.0,
	"hard": 5.0
}

func get_drop_interval() -> float:
	return DIFFICULTIES.get(difficulty, 10.0)

func _ready() -> void:
	# Load saved settings if any
	pass
