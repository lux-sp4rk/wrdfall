extends RefCounted
class_name LanguageConfig

# Per-language configuration for Word Loom.
# Holds letter weights, bigrams, seed words, and UI strings.

var code: String
var display_name: String
var wordlist_path: String
var letter_weights: Dictionary
var vowels: String
var target_vowel_ratio: float
var bigrams: Dictionary
var seed_words: Array
var extra_alpha: Array  # extra Unicode codepoints allowed (e.g. Ñ = 209)
var ui_strings: Dictionary


static func get_config(lang_code: String) -> LanguageConfig:
	match lang_code:
		"es":
			return spanish()
		_:
			return english()


static func available_languages() -> Array:
	return [
		{"code": "en", "display_name": "EN"},
		{"code": "es", "display_name": "ES"},
	]


static func english() -> LanguageConfig:
	var cfg := LanguageConfig.new()
	cfg.code = "en"
	cfg.display_name = "EN"
	cfg.wordlist_path = "res://data/words_en.txt"
	cfg.vowels = "AEIOU"
	cfg.target_vowel_ratio = 0.38
	cfg.extra_alpha = []
	cfg.letter_weights = {
		"E": 12, "A": 9, "I": 9, "O": 8, "N": 6, "R": 6, "T": 6, "L": 4, "S": 4, "U": 4,
		"D": 4, "G": 3, "B": 2, "C": 2, "M": 2, "P": 2, "F": 2, "H": 2, "V": 2, "W": 2,
		"Y": 2, "K": 1, "J": 1, "X": 1, "Q": 1, "Z": 1,
	}
	cfg.bigrams = {
		"T": "HEIOA", "H": "EAIOU", "S": "THECO", "R": "EAIOU", "N": "GDEOT",
		"E": "RSDNA", "A": "NTRLS", "I": "NTSCO", "O": "NRFUT", "L": "EIAOY",
		"D": "EIAOS", "C": "OAHEK", "U": "RSTLN", "P": "RLAEO", "M": "AEION",
		"G": "EOAHR", "B": "ELAOU", "F": "OIRAE", "W": "AIHOE", "Y": "SOEIA",
		"V": "EIAOU", "K": "EISAN", "J": "UOAEI", "X": "PTIAE", "Q": "UUUUU",
		"Z": "EAIOU",
	}
	cfg.seed_words = [
		"STAR", "LOOM", "DROP", "RAIN", "FIRE", "GLOW", "WIND", "TREE",
		"LAKE", "WAVE", "RISE", "GOLD", "IRON", "BONE", "GUST", "MIST",
		"TORN", "HAZE", "DUNE", "FERN", "SAGE", "LIME", "PINE", "ARCH",
		"ROPE", "NEST", "CAVE", "PALE", "WREN", "GATE", "VINE", "HELM",
	]
	cfg.ui_strings = {
		"score": "Score: %d",
		"you_win": "You Win! Score: %d",
		"game_over": "Game Over! Score: %d",
		"not_valid": "Not a valid word.",
		"need_shake": "Need %d points to shake!",
		"grid_shaken": "Grid shaken! (-%d)",
		"need_hammer": "Need %d points for hammer!",
		"hammer_target": "Click a tile to destroy it (ESC to cancel)",
		"hammer_cancel": "Hammer canceled",
		"hammer_empty": "Empty tile! Click a letter",
		"tile_destroyed": "Tile destroyed! (-%d)",
		"shake": "Shake",
		"hammer": "Hammer",
		"swap": "Swap",
		"need_swap": "Need %d points to swap!",
		"swap_first": "Select first tile to swap",
		"swap_second": "Now select an adjacent tile",
		"swap_not_adjacent": "Tiles must be adjacent!",
		"swap_empty": "Both tiles must have letters!",
		"swap_done": "Swapped! (-%d)",
		"swap_cancel": "Swap canceled",
		"cancel": "Cancel",
	}
	return cfg


static func spanish() -> LanguageConfig:
	var cfg := LanguageConfig.new()
	cfg.code = "es"
	cfg.display_name = "ES"
	cfg.wordlist_path = "res://data/words_es.txt"
	cfg.vowels = "AEIOU"
	cfg.target_vowel_ratio = 0.42
	cfg.extra_alpha = [209]  # Ñ (U+00D1)
	# Spanish Scrabble (FISE) letter distribution
	cfg.letter_weights = {
		"A": 12, "E": 12, "O": 9, "S": 6, "I": 6, "R": 5, "N": 5, "L": 4,
		"U": 5, "T": 4, "D": 5, "C": 4, "G": 2, "B": 2, "M": 2, "P": 2,
		"H": 2, "F": 1, "V": 1, "Y": 1, "Q": 1, "J": 1, "X": 1, "Z": 1,
		"\u00d1": 1,  # Ñ
	}
	# TODO: Spanish bigrams — see contribution request below
	cfg.bigrams = {
		"A": "NRLSD", "B": "AEOIR", "C": "OAEIU", "D": "EAOIR",
		"E": "NRSLA", "F": "IAEOU", "G": "URAEO", "H": "AEOIR",
		"I": "ENSOA", "J": "AOEUI", "L": "AOEUI", "M": "AOEIP",
		"N": "TOEAI", "O": "NRSLD", "\u00d1": "AOEUI",
		"P": "RAEOL", "Q": "UUUUU", "R": "EAOIU", "S": "ETAOI",
		"T": "RAEOI", "U": "NRESA", "V": "IAEOU", "X": "PTIAE",
		"Y": "AOEUI", "Z": "AOEUI",
	}
	cfg.seed_words = [
		"CASA", "LUNA", "SOLA", "RISA", "MESA", "GATO", "LOMA", "PALA",
		"NUBE", "DURO", "FARO", "GRIS", "HORA", "ISLA", "JOTA", "LIBRE",
		"MANO", "NIDO", "OCHO", "PINO", "ROSA", "SENO", "TELA", "VINO",
		"CENA", "DADO", "FILO", "GOTA", "LOBO", "MONO", "REMO", "BESO",
	]
	cfg.ui_strings = {
		"score": "Puntos: %d",
		"you_win": "\u00a1Ganaste! Puntos: %d",
		"game_over": "\u00a1Fin del juego! Puntos: %d",
		"not_valid": "Palabra no v\u00e1lida.",
		"need_shake": "\u00a1Necesitas %d puntos para mezclar!",
		"grid_shaken": "\u00a1Mezclado! (-%d)",
		"need_hammer": "\u00a1Necesitas %d puntos para el martillo!",
		"hammer_target": "Toca una letra para destruirla (ESC para cancelar)",
		"hammer_cancel": "Martillo cancelado",
		"hammer_empty": "\u00a1Casilla vac\u00eda! Toca una letra",
		"tile_destroyed": "\u00a1Letra destruida! (-%d)",
		"shake": "Mezclar",
		"hammer": "Martillo",
		"swap": "Cambiar",
		"need_swap": "\u00a1Necesitas %d puntos para cambiar!",
		"swap_first": "Selecciona la primera letra",
		"swap_second": "Ahora selecciona una letra adyacente",
		"swap_not_adjacent": "\u00a1Las letras deben ser adyacentes!",
		"swap_empty": "\u00a1Ambas casillas deben tener letras!",
		"swap_done": "\u00a1Cambiado! (-%d)",
		"swap_cancel": "Cambio cancelado",
		"cancel": "Cancelar",
	}
	return cfg
