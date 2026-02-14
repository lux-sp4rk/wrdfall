extends Node

var current_language: String = "en"
var difficulty: String = "normal"
var theme: String = "light"

# All game constants now defined in GameConstants autoload
# These dictionaries reference those constants for backward compatibility

# Drop interval per difficulty (in seconds)
const DROP_INTERVALS = {
	"normal": GameConstants.DROP_INTERVAL_NORMAL,
	"hard": GameConstants.DROP_INTERVAL_HARD
}

# Power-up costs per difficulty
const POWER_UP_COSTS = {
	"normal": {
		"shake": GameConstants.SHAKE_COST_NORMAL,
		"swap": GameConstants.SWAP_COST_NORMAL,
		"draw_more": GameConstants.DRAW_MORE_COST_NORMAL
	},
	"hard": {
		"shake": GameConstants.SHAKE_COST_HARD,
		"swap": GameConstants.SWAP_COST_HARD,
		"draw_more": GameConstants.DRAW_MORE_COST_HARD
	}
}

# Vowel ratio adjustment per difficulty (multiplier on base ratio)
const VOWEL_RATIO_MULTIPLIERS = {
	"normal": GameConstants.VOWEL_BOOST_NORMAL,
	"hard": GameConstants.VOWEL_REDUCTION_HARD
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
