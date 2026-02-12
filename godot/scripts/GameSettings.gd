extends Node

var current_language: String = "en"
var difficulty: String = "normal"

# Drop interval per difficulty (in seconds)
const DROP_INTERVALS = {
	"normal": 8.0,
	"hard": 5.0
}

# Power-up costs per difficulty
const POWER_UP_COSTS = {
	"normal": {
		"shake": 5,
		"hammer": 8,
		"swap": 3,
		"draw_more": 15
	},
	"hard": {
		"shake": 8,
		"hammer": 12,
		"swap": 5,
		"draw_more": 20
	}
}

# Vowel ratio adjustment per difficulty (multiplier on base ratio)
const VOWEL_RATIO_MULTIPLIERS = {
	"normal": 1.0,      # No change (0.38 for EN, 0.42 for ES)
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
