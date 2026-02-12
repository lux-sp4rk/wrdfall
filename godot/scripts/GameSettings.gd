extends Node

var current_language: String = "en"
var difficulty: String = "normal"

# Drop interval per difficulty (in seconds)
const DROP_INTERVALS = {
	"normal": 10.0,
	"hard": 5.0
}

# Power-up costs per difficulty
const POWER_UP_COSTS = {
	"normal": {
		"shake": 3,
		"swap": 2,
		"draw_more": 9
	},
	"hard": {
		"shake": 8,
		"swap": 5,
		"draw_more": 20
	}
}

# Vowel ratio adjustment per difficulty (multiplier on base ratio)
const VOWEL_RATIO_MULTIPLIERS = {
	"normal": 1.15,     # 15% more vowels (0.437 for EN, 0.483 for ES)
	"hard": 0.75        # 25% fewer vowels (0.285 for EN, 0.315 for ES)
}

# Rescue word system enabled per difficulty
const RESCUE_ENABLED = {
	"normal": true,
	"hard": false
}

func get_drop_interval() -> float:
	return DROP_INTERVALS.get(difficulty, 8.0)

func get_power_up_cost(power_up_name: String) -> int:
	var costs = POWER_UP_COSTS.get(difficulty, POWER_UP_COSTS["normal"])
	return costs.get(power_up_name, 0)

func get_vowel_ratio_multiplier() -> float:
	return VOWEL_RATIO_MULTIPLIERS.get(difficulty, 1.0)

func is_rescue_enabled() -> bool:
	return RESCUE_ENABLED.get(difficulty, true)

func _ready() -> void:
	# Load saved settings if any
	pass
