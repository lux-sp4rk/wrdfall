extends Node

var current_language: String = "en"
var difficulty: String = "normal"
var theme: String = "dark"
var has_completed_tutorial: bool = false

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
	_load_settings()  # Load settings including tutorial completion status

func _load_settings() -> void:
	"""Load settings from ConfigFile."""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		has_completed_tutorial = config.get_value("game", "has_completed_tutorial", false)

func save_settings() -> void:
	"""Save settings to ConfigFile."""
	var config = ConfigFile.new()
	config.set_value("game", "theme", theme)
	config.set_value("game", "language", current_language)
	config.set_value("game", "difficulty", difficulty)
	config.set_value("game", "has_completed_tutorial", has_completed_tutorial)
	var err = config.save("user://settings.cfg")
	if err != OK:
		push_warning("Failed to save settings: " + str(err))

func set_has_completed_tutorial(completed: bool) -> void:
	"""Set and save tutorial completion status."""
	has_completed_tutorial = completed
	save_settings()
	
	# Also save to localStorage on web
	if OS.has_feature("web"):
		var js = JavaScriptBridge.get_interface("localStorage")
		if js != null:
			js.setItem("word-loom-tutorial-completed", "true" if completed else "false")

func load_from_localstorage() -> void:
	"""Read language and difficulty from localStorage (set by React SettingsScreen).
	Theme is handled separately by ThemeManager."""
	if not OS.has_feature("web"):
		return
	var js = JavaScriptBridge.get_interface("localStorage")
	if js == null:
		return
	var lang = js.getItem("word-loom-language")
	if lang == "en" or lang == "es":
		current_language = lang
	var diff = js.getItem("word-loom-difficulty")
	if diff == "normal" or diff == "hard":
		difficulty = diff
	var tutorial_completed = js.getItem("word-loom-tutorial-completed")
	if tutorial_completed == "true":
		has_completed_tutorial = true
