extends Node
class_name TutorialController

## Tutorial Controller
## Manages the guided interactive tutorial system for Wordfall
## Handles state machine, input gating, phase progression, and coordination

# Tutorial phases
enum TutorialPhase {
	INTRO,        # Welcome and basic word selection
	SELECTION,    # Practice word selection
	SCORING,      # Scoring explanation
	GRAVITY,      # Gravity mechanics
	POWERUPS,     # Power-up introduction
	COMPLETE      # Tutorial complete
}

# Phase data configuration
class PhaseConfig:
	var phase: TutorialPhase
	var title: String
	var instruction: String
	var board_preset: Array  # 5x5 array of letters or empty strings
	var target_word: String
	var demo_path: Array     # Array of Vector2i positions for demo
	var gated: bool          # If true, only allow specific cells
	var allowed_cells: Array # Array of Vector2i for gated phases
	var show_hand_cursor: bool
	var wait_for_action: bool  # Wait for user input vs auto-advance
	var duration: float      # Auto-advance duration if not waiting
	var show_score_breakdown: bool
	var highlight_powerup: String  # "shake", "swap", or ""
	
	func _init(p_phase: TutorialPhase = TutorialPhase.INTRO) -> void:
		phase = p_phase
		title = ""
		instruction = ""
		board_preset = []
		target_word = ""
		demo_path = []
		gated = false
		allowed_cells = []
		show_hand_cursor = false
		wait_for_action = true
		duration = 0.0
		show_score_breakdown = false
		highlight_powerup = ""

# Signals
signal phase_changed(new_phase: TutorialPhase, phase_data: PhaseConfig)
signal tutorial_completed(skipped: bool)
signal request_demo_path(path: Array)
signal request_highlight_cells(cells: Array)
signal request_clear_highlights
signal request_show_hand_cursor(position: Vector2, gesture_type: String)
signal request_hide_hand_cursor

# State
var current_phase: TutorialPhase = TutorialPhase.INTRO
var phase_configs: Dictionary = {}  # TutorialPhase -> PhaseConfig
var is_tutorial_active: bool = false
var has_been_skipped: bool = false
var phase_completion_callbacks: Dictionary = {}

# Demo mode
var demo_mode_enabled: bool = false
var demo_speed: float = 1.0

# Language
var lang_config: LanguageConfig

func _ready() -> void:
	_load_phase_configs()

# === Configuration Loading ===

func _load_phase_configs() -> void:
	"""Initialize phase configurations with localized strings."""
	var current_lang: String = GameSettings.current_language if GameSettings else "en"
	lang_config = LanguageConfig.get_config(current_lang)
	
	var tutorial_strings: Dictionary = lang_config.ui_strings.get("tutorial", _get_default_tutorial_strings(current_lang))
	
	# Phase 1: INTRO
	var intro_config := PhaseConfig.new(TutorialPhase.INTRO)
	intro_config.title = tutorial_strings.get("intro_title", "Welcome to Wordfall")
	intro_config.instruction = tutorial_strings.get("intro_instruction", "Drag across letters to spell words")
	intro_config.board_preset = [
		["", "", "", "", ""],
		["", "C", "A", "T", ""],
		["", "", "", "", ""],
		["", "B", "O", "X", ""],
		["", "", "", "", ""]
	]
	intro_config.target_word = "CAT"
	intro_config.demo_path = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	intro_config.gated = true
	intro_config.allowed_cells = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	intro_config.show_hand_cursor = true
	intro_config.wait_for_action = true
	phase_configs[TutorialPhase.INTRO] = intro_config
	
	# Phase 2: SELECTION
	var selection_config := PhaseConfig.new(TutorialPhase.SELECTION)
	selection_config.title = tutorial_strings.get("selection_title", "Find Words")
	selection_config.instruction = tutorial_strings.get("selection_instruction", "Look for 3+ letter words. Longer = more points!")
	selection_config.board_preset = [
		["", "", "", "", ""],
		["", "T", "H", "E", ""],
		["", "", "", "", ""],
		["", "S", "T", "A", "R"],
		["", "", "", "", ""]
	]
	selection_config.target_word = "STAR"
	selection_config.demo_path = [Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)]
	selection_config.gated = false
	selection_config.show_hand_cursor = false
	selection_config.wait_for_action = true
	phase_configs[TutorialPhase.SELECTION] = selection_config
	
	# Phase 3: SCORING
	var scoring_config := PhaseConfig.new(TutorialPhase.SCORING)
	scoring_config.title = tutorial_strings.get("scoring_title", "Scoring")
	scoring_config.instruction = tutorial_strings.get("scoring_instruction", "Longer words = bigger multipliers!")
	scoring_config.board_preset = [
		["", "", "", "", ""],
		["", "G", "O", "L", "D"],
		["", "", "", "", ""],
		["", "G", "A", "M", "E"],
		["", "", "", "", ""]
	]
	scoring_config.target_word = "GAME"
	scoring_config.demo_path = []
	scoring_config.gated = false
	scoring_config.show_hand_cursor = false
	scoring_config.wait_for_action = true
	scoring_config.show_score_breakdown = true
	phase_configs[TutorialPhase.SCORING] = scoring_config
	
	# Phase 4: GRAVITY
	var gravity_config := PhaseConfig.new(TutorialPhase.GRAVITY)
	gravity_config.title = tutorial_strings.get("gravity_title", "Gravity")
	gravity_config.instruction = tutorial_strings.get("gravity_instruction", "Letters fall down when you clear words above!")
	gravity_config.board_preset = [
		["", "", "", "", ""],
		["", "", "", "", ""],
		["D", "O", "G", "", ""],
		["C", "A", "T", "", ""],
		["", "", "", "B", ""]
	]
	gravity_config.target_word = "CAT"
	gravity_config.demo_path = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]
	gravity_config.gated = true
	gravity_config.allowed_cells = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]
	gravity_config.show_hand_cursor = true
	gravity_config.wait_for_action = true
	phase_configs[TutorialPhase.GRAVITY] = gravity_config
	
	# Phase 5: POWERUPS
	var powerups_config := PhaseConfig.new(TutorialPhase.POWERUPS)
	powerups_config.title = tutorial_strings.get("powerups_title", "Power-ups")
	powerups_config.instruction = tutorial_strings.get("powerups_instruction", "Use Shake to shuffle or Swap to reposition tiles!")
	powerups_config.board_preset = [
		["Z", "Q", "X", "Z", "Q"],
		["Z", "", "", "", "Z"],
		["", "", "", "", ""],
		["", "", "C", "A", "T"],
		["", "", "", "", ""]
	]
	powerups_config.target_word = "CAT"
	powerups_config.demo_path = []
	powerups_config.gated = false
	powerups_config.show_hand_cursor = false
	powerups_config.wait_for_action = true
	powerups_config.highlight_powerup = "shake"
	phase_configs[TutorialPhase.POWERUPS] = powerups_config
	
	# Phase 6: COMPLETE
	var complete_config := PhaseConfig.new(TutorialPhase.COMPLETE)
	complete_config.title = tutorial_strings.get("complete_title", "You're Ready!")
	complete_config.instruction = tutorial_strings.get("complete_instruction", "Tap Play to start your game!")
	complete_config.board_preset = [
		["", "", "", "", ""],
		["", "P", "L", "A", "Y"],
		["", "", "", "", ""],
		["", "N", "O", "W", ""],
		["", "", "", "", ""]
	]
	complete_config.target_word = ""
	complete_config.demo_path = []
	complete_config.gated = false
	complete_config.show_hand_cursor = false
	complete_config.wait_for_action = false
	complete_config.duration = 3.0
	phase_configs[TutorialPhase.COMPLETE] = complete_config

func _get_default_tutorial_strings(lang_code: String) -> Dictionary:
	"""Default English tutorial strings."""
	return {
		"intro_title": "Welcome to Wordfall",
		"intro_instruction": "Drag across letters to spell words",
		"selection_title": "Find Words",
		"selection_instruction": "Look for 3+ letter words. Longer = more points!",
		"scoring_title": "Scoring",
		"scoring_instruction": "Longer words = bigger multipliers!",
		"gravity_title": "Gravity",
		"gravity_instruction": "Letters fall down when you clear words above!",
		"powerups_title": "Power-ups",
		"powerups_instruction": "Use Shake to shuffle or Swap to reposition tiles!",
		"complete_title": "You're Ready!",
		"complete_instruction": "Tap Play to start your game!",
		"skip_button": "Skip",
		"phase_progress": "Step %d of %d",
		"demo_tap": "Tap",
		"demo_drag": "Drag",
		"good_job": "Good job!",
		"try_again": "Try again!",
		"score_breakdown": "Letters + Multiplier = Score"
	}

# === Public API ===

func start_tutorial() -> void:
	"""Start the tutorial from the beginning."""
	is_tutorial_active = true
	has_been_skipped = false
	_load_phase_configs()  # Reload for current language
	_set_phase(TutorialPhase.INTRO)

func skip_tutorial() -> void:
	"""Skip the tutorial and mark as complete."""
	if not is_tutorial_active:
		return
	has_been_skipped = true
	is_tutorial_active = false
	tutorial_completed.emit(true)
	_mark_tutorial_completed()

func complete_tutorial() -> void:
	"""Complete the tutorial normally."""
	if not is_tutorial_active:
		return
	is_tutorial_active = false
	tutorial_completed.emit(false)
	_mark_tutorial_completed()

func next_phase() -> void:
	"""Advance to the next tutorial phase."""
	if not is_tutorial_active:
		return
		
	var next := current_phase + 1
	if next > TutorialPhase.COMPLETE:
		complete_tutorial()
	else:
		_set_phase(next)

func previous_phase() -> void:
	"""Go back to the previous tutorial phase."""
	if not is_tutorial_active:
		return
		
	var prev := current_phase - 1
	if prev >= TutorialPhase.INTRO:
		_set_phase(prev)

func restart_phase() -> void:
	"""Restart the current phase."""
	if not is_tutorial_active:
		return
	_set_phase(current_phase)

func get_current_phase_config() -> PhaseConfig:
	"""Get the configuration for the current phase."""
	return phase_configs.get(current_phase, PhaseConfig.new())

func is_input_gated() -> bool:
	"""Check if input is currently gated/restricted."""
	if not is_tutorial_active:
		return false
	var config: PhaseConfig = phase_configs.get(current_phase)
	if not config:
		return false
	return config.gated

func is_input_allowed(event: InputEvent, cell: Vector2i) -> bool:
	"""Check if an input event at a specific cell is allowed."""
	if not is_tutorial_active:
		return true
	
	var config: PhaseConfig = phase_configs.get(current_phase)
	if not config:
		return true
	
	# If not gated, allow all input
	if not config.gated:
		return true
	
	# Check if cell is in allowed list
	for allowed in config.allowed_cells:
		if allowed == cell:
			return true
	
	return false

func is_cell_highlighted(cell: Vector2i) -> bool:
	"""Check if a cell should be highlighted as interactable."""
	if not is_tutorial_active:
		return false
		
	var config: PhaseConfig = phase_configs.get(current_phase)
	if not config:
		return false
	
	if not config.gated:
		return false
		
	for allowed in config.allowed_cells:
		if allowed == cell:
			return true
	return false

func register_phase_completion(phase: TutorialPhase, callback: Callable) -> void:
	"""Register a callback for when a specific phase completes."""
	phase_completion_callbacks[phase] = callback

func on_word_formed(word: String, path: Array) -> void:
	"""Called when the player forms a word. Used to advance phases."""
	if not is_tutorial_active:
		return
		
	var config: PhaseConfig = phase_configs.get(current_phase)
	if not config:
		return
	
	# Check if word matches target or is valid for this phase
	var word_upper: String = word.to_upper()
	
	# For gated phases, verify the path matches allowed cells
	if config.gated:
		var path_valid: bool = true
		for cell in path:
			var cell_valid: bool = false
			for allowed in config.allowed_cells:
				if allowed == cell:
					cell_valid = true
					break
			if not cell_valid:
				path_valid = false
				break
		
		if not path_valid:
			return
	
	# If we have a target word, check it
	if config.target_word != "":
		if word_upper == config.target_word.to_upper():
			_trigger_phase_completion()
	else:
		# No specific target, any valid word advances
		if word.length() >= GameConstants.MIN_WORD_LENGTH:
			_trigger_phase_completion()

func on_powerup_used(powerup_name: String) -> void:
	"""Called when a power-up is used."""
	if not is_tutorial_active:
		return
		
	var config: PhaseConfig = phase_configs.get(current_phase)
	if not config:
		return
	
	if config.highlight_powerup != "" and powerup_name == config.highlight_powerup:
		_trigger_phase_completion()

func enable_demo_mode(enabled: bool, speed: float = 1.0) -> void:
	"""Enable/disable demo mode for auto-play."""
	demo_mode_enabled = enabled
	demo_speed = speed

func is_demo_mode() -> bool:
	"""Check if demo mode is active."""
	return demo_mode_enabled

func get_phase_progress() -> Dictionary:
	"""Get current phase progress for UI display."""
	var total_phases: int = TutorialPhase.size()
	var current_index: int = int(current_phase)
	return {
		"current": current_index + 1,
		"total": total_phases,
		"percentage": float(current_index + 1) / float(total_phases) * 100.0
	}

func get_phase_name(phase: TutorialPhase) -> String:
	"""Get human-readable name for a phase."""
	match phase:
		TutorialPhase.INTRO:
			return "Intro"
		TutorialPhase.SELECTION:
			return "Selection"
		TutorialPhase.SCORING:
			return "Scoring"
		TutorialPhase.GRAVITY:
			return "Gravity"
		TutorialPhase.POWERUPS:
			return "Power-ups"
		TutorialPhase.COMPLETE:
			return "Complete"
		_:
			return "Unknown"

# === Private Methods ===

func _set_phase(phase: TutorialPhase) -> void:
	"""Set the current tutorial phase and emit signals."""
	current_phase = phase
	var config: PhaseConfig = phase_configs.get(phase, PhaseConfig.new())
	
	phase_changed.emit(phase, config)
	
	# Emit signals for visual effects
	if config.show_hand_cursor and not config.demo_path.is_empty():
		_request_demo_animation(config)
	
	if config.gated and not config.allowed_cells.is_empty():
		request_highlight_cells.emit(config.allowed_cells)
	else:
		request_clear_highlights.emit()
	
	# Auto-advance if configured
	if not config.wait_for_action and config.duration > 0:
		await get_tree().create_timer(config.duration).timeout
		if is_tutorial_active and current_phase == phase:
			next_phase()

func _request_demo_animation(config: PhaseConfig) -> void:
	"""Request the hand cursor animation for a demo path."""
	if config.demo_path.is_empty():
		return
	
	# Emit signal for UI to show hand cursor animation
	request_show_hand_cursor.emit(config.demo_path, "drag")

func _trigger_phase_completion() -> void:
	"""Trigger completion of the current phase."""
	# Check for registered callback
	var callback: Callable = phase_completion_callbacks.get(current_phase)
	if callback:
		callback.call()
	
	# Auto-advance to next phase
	next_phase()

func _mark_tutorial_completed() -> void:
	"""Mark the tutorial as completed in settings."""
	GameSettings.set_has_completed_tutorial(true)
