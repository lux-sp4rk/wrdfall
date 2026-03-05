extends RefCounted
class_name TutorialData

## Tutorial Data Resource
## Contains phase configurations as GDScript resource format
## This complements the JSON configuration with compiled defaults

# Tutorial phase identifiers
const PHASE_INTRO: String = "intro"
const PHASE_SELECTION: String = "selection"
const PHASE_SCORING: String = "scoring"
const PHASE_GRAVITY: String = "gravity"
const PHASE_POWERUPS: String = "powerups"
const PHASE_COMPLETE: String = "complete"

# Board presets for each phase
const BOARD_PRESETS: Dictionary = {
	PHASE_INTRO: [
		["", "", "", "", ""],
		["", "C", "A", "T", ""],
		["", "", "", "", ""],
		["", "B", "O", "X", ""],
		["", "", "", "", ""]
	],
	PHASE_SELECTION: [
		["", "", "", "", ""],
		["", "T", "H", "E", ""],
		["", "", "", "", ""],
		["", "S", "T", "A", "R"],
		["", "", "", "", ""]
	],
	PHASE_SCORING: [
		["", "", "", "", ""],
		["", "G", "O", "L", "D"],
		["", "", "", "", ""],
		["", "G", "A", "M", "E"],
		["", "", "", "", ""]
	],
	PHASE_GRAVITY: [
		["", "", "", "", ""],
		["", "", "", "", ""],
		["D", "O", "G", "", ""],
		["C", "A", "T", "", ""],
		["", "", "", "B", ""]
	],
	PHASE_POWERUPS: [
		["Z", "Q", "X", "Z", "Q"],
		["Z", "", "", "", "Z"],
		["", "", "", "", ""],
		["", "", "C", "A", "T"],
		["", "", "", "", ""]
	],
	PHASE_COMPLETE: [
		["", "", "", "", ""],
		["", "P", "L", "A", "Y"],
		["", "", "", "", ""],
		["", "N", "O", "W", ""],
		["", "", "", "", ""]
	]
}

# Demo paths (cell coordinates) for hand cursor animations
const DEMO_PATHS: Dictionary = {
	PHASE_INTRO: [
		Vector2i(1, 1),  # C
		Vector2i(2, 1),  # A
		Vector2i(3, 1)   # T
	],
	PHASE_SELECTION: [
		Vector2i(1, 3),  # S
		Vector2i(2, 3),  # T
		Vector2i(3, 3),  # A
		Vector2i(4, 3)   # R
	],
	PHASE_GRAVITY: [
		Vector2i(0, 3),  # C
		Vector2i(1, 3),  # A
		Vector2i(2, 3)   # T
	]
}

# Allowed cells for gated phases
const ALLOWED_CELLS: Dictionary = {
	PHASE_INTRO: [
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)
	],
	PHASE_GRAVITY: [
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)
	]
}

# Target words for each phase
const TARGET_WORDS: Dictionary = {
	PHASE_INTRO: "CAT",
	PHASE_SELECTION: "STAR",
	PHASE_SCORING: "GAME",
	PHASE_GRAVITY: "CAT",
	PHASE_POWERUPS: "CAT"
}

# Phase settings
const PHASE_SETTINGS: Dictionary = {
	PHASE_INTRO: {
		"gated": true,
		"show_hand_cursor": true,
		"wait_for_action": true,
		"show_score_breakdown": false,
		"highlight_powerup": ""
	},
	PHASE_SELECTION: {
		"gated": false,
		"show_hand_cursor": false,
		"wait_for_action": true,
		"show_score_breakdown": false,
		"highlight_powerup": ""
	},
	PHASE_SCORING: {
		"gated": false,
		"show_hand_cursor": false,
		"wait_for_action": true,
		"show_score_breakdown": true,
		"highlight_powerup": ""
	},
	PHASE_GRAVITY: {
		"gated": true,
		"show_hand_cursor": true,
		"wait_for_action": true,
		"show_score_breakdown": false,
		"highlight_powerup": ""
	},
	PHASE_POWERUPS: {
		"gated": false,
		"show_hand_cursor": false,
		"wait_for_action": true,
		"show_score_breakdown": false,
		"highlight_powerup": "shake"
	},
	PHASE_COMPLETE: {
		"gated": false,
		"show_hand_cursor": false,
		"wait_for_action": false,
		"duration": 3.0,
		"show_score_breakdown": false,
		"highlight_powerup": ""
	}
}

# Scoring examples for tutorial
const SCORING_EXAMPLES: Array = [
	{
		"word": "CAT",
		"letters": ["C", "A", "T"],
		"letter_values": [3, 1, 1],
		"letter_sum": 5,
		"length": 3,
		"multiplier": 1,
		"score": 5
	},
	{
		"word": "STAR",
		"letters": ["S", "T", "A", "R"],
		"letter_values": [1, 1, 1, 1],
		"letter_sum": 4,
		"length": 4,
		"multiplier": 2,
		"score": 8
	},
	{
		"word": "GOLD",
		"letters": ["G", "O", "L", "D"],
		"letter_values": [2, 1, 1, 2],
		"letter_sum": 6,
		"length": 4,
		"multiplier": 2,
		"score": 12
	}
]

# Multiplier explanation
const MULTIPLIER_INFO: Dictionary = {
	3: {"label": "3 letters", "multiplier": "1x"},
	4: {"label": "4 letters", "multiplier": "2x"},
	5: {"label": "5 letters", "multiplier": "4x"},
	6: {"label": "6+ letters", "multiplier": "8x"}
}

## Get board preset for a phase
static func get_board_preset(phase_id: String) -> Array:
	return BOARD_PRESETS.get(phase_id, [])

## Get demo path for a phase
static func get_demo_path(phase_id: String) -> Array:
	return DEMO_PATHS.get(phase_id, [])

## Get allowed cells for a phase
static func get_allowed_cells(phase_id: String) -> Array:
	return ALLOWED_CELLS.get(phase_id, [])

## Get target word for a phase
static func get_target_word(phase_id: String) -> String:
	return TARGET_WORDS.get(phase_id, "")

## Get phase settings
static func get_phase_settings(phase_id: String) -> Dictionary:
	return PHASE_SETTINGS.get(phase_id, {
		"gated": false,
		"show_hand_cursor": false,
		"wait_for_action": true,
		"show_score_breakdown": false,
		"highlight_powerup": ""
	})

## Get localized title for a phase
static func get_phase_title(phase_id: String, lang_code: String = "en") -> String:
	var titles: Dictionary = {
		"en": {
			PHASE_INTRO: "Welcome to Word Loom",
			PHASE_SELECTION: "Find Words",
			PHASE_SCORING: "Scoring",
			PHASE_GRAVITY: "Gravity",
			PHASE_POWERUPS: "Power-ups",
			PHASE_COMPLETE: "You're Ready!"
		},
		"es": {
			PHASE_INTRO: "Bienvenido a Word Loom",
			PHASE_SELECTION: "Encuentra Palabras",
			PHASE_SCORING: "Puntuación",
			PHASE_GRAVITY: "Gravedad",
			PHASE_POWERUPS: "Power-ups",
			PHASE_COMPLETE: "¡Estás Listo!"
		}
	}
	var lang_titles: Dictionary = titles.get(lang_code, titles["en"])
	return lang_titles.get(phase_id, phase_id)

## Get localized instruction for a phase
static func get_phase_instruction(phase_id: String, lang_code: String = "en") -> String:
	var instructions: Dictionary = {
		"en": {
			PHASE_INTRO: "Drag across letters to spell words",
			PHASE_SELECTION: "Look for 3+ letter words. Longer = more points!",
			PHASE_SCORING: "Longer words = bigger multipliers!",
			PHASE_GRAVITY: "Letters fall down when you clear words above!",
			PHASE_POWERUPS: "Use Shake to shuffle or Swap to reposition tiles!",
			PHASE_COMPLETE: "Tap Play to start your game!"
		},
		"es": {
			PHASE_INTRO: "Arrastra sobre las letras para formar palabras",
			PHASE_SELECTION: "Busca palabras de 3+ letras. ¡Más largas = más puntos!",
			PHASE_SCORING: "¡Palabras más largas = multiplicadores más grandes!",
			PHASE_GRAVITY: "¡Las letras caen cuando borras palabras de arriba!",
			PHASE_POWERUPS: "¡Usa Mezclar para barajar o Cambiar para reposicionar!",
			PHASE_COMPLETE: "¡Toca Jugar para comenzar tu partida!"
		}
	}
	var lang_instructions: Dictionary = instructions.get(lang_code, instructions["en"])
	return lang_instructions.get(phase_id, "")

## Validate a word formed during a specific phase
static func validate_word_for_phase(word: String, phase_id: String) -> bool:
	var target: String = get_target_word(phase_id)
	if target == "":
		return word.length() >= GameConstants.MIN_WORD_LENGTH
	return word.to_upper() == target.to_upper()

## Get all phase IDs in order
static func get_phase_order() -> Array:
	return [PHASE_INTRO, PHASE_SELECTION, PHASE_SCORING, PHASE_GRAVITY, PHASE_POWERUPS, PHASE_COMPLETE]
