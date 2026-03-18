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
var letter_points: Dictionary  # per-letter scoring values (Scrabble-style)
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
	cfg.letter_points = {
		"A": 1, "B": 3, "C": 3, "D": 2, "E": 1, "F": 4, "G": 2, "H": 4,
		"I": 1, "J": 8, "K": 5, "L": 1, "M": 3, "N": 1, "O": 1, "P": 3,
		"Q": 10, "R": 1, "S": 1, "T": 1, "U": 1, "V": 4, "W": 4, "X": 8,
		"Y": 4, "Z": 10,
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
		# Nature
		"STAR", "RAIN", "FIRE", "GLOW", "WIND", "TREE", "LAKE", "WAVE",
		"MIST", "HAZE", "DUNE", "FERN", "SAGE", "LIME", "PINE", "VINE",
		"DAWN", "DUSK", "MOON", "TIDE", "REEF", "COVE", "GLEN", "VALE",
		"HILL", "DALE", "MOSS", "PEAT", "CLAY", "SAND", "FOAM", "SURF",
		"GALE", "CALM", "SNOW", "THAW", "LEAF", "STEM", "ROOT", "SEED",
		"HAWK", "WREN", "DOVE", "LARK", "SWAN", "DEER", "HARE", "FAWN",
		# Warmth and light
		"GOLD", "GUST", "ROSE", "SILK", "WARM", "COZY", "SOFT", "GLOW",
		"BEAM", "RAYS", "NOON", "DUSK", "LAMP", "WICK", "BLAZE", "EMBER",
		# Structure and craft
		"LOOM", "DROP", "IRON", "BONE", "ARCH", "ROPE", "NEST", "CAVE",
		"GATE", "HELM", "KNOT", "LACE", "WELD", "KILN", "LOFT", "BARN",
		"DOME", "WALL", "PATH", "ROAD", "FORD", "PIER", "DOCK", "MAST",
		# Words and story
		"TALE", "POEM", "SONG", "LORE", "MYTH", "RUNE", "HYMN", "JEST",
		"WISH", "HOPE", "GIFT", "BOND", "OATH", "PACT", "BOON", "FEAT",
		# Sensory
		"PALE", "DEEP", "RICH", "BOLD", "KEEN", "PURE", "TRUE", "WISE",
		"HUSH", "RING", "CHIME", "DRUM", "TONE", "NOTE", "ALTO",
	]
	cfg.ui_strings = {
		"score": "Score: %d",
		"game_complete": "Game Complete!\nScore: %d",
		"new_high_score": "New High Score!\n",
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
		"draw_more": "Draw",
		"need_swap": "Need %d points to swap!",
		"swap_first": "Select first tile to swap",
		"swap_second": "Now select an adjacent tile",
		"swap_not_adjacent": "Tiles must be adjacent!",
		"swap_empty": "Both tiles must have letters!",
		"swap_done": "Swapped! (-%d)",
		"swap_cancel": "Swap canceled",
		"need_draw_more": "Draw more unavailable!",
		"draw_more_success": "Drew %d letters!",
		"draw_more_no_space": "Grid is full! Clear some letters first",
		"cancel": "Cancel",
		"play_again": "Play Again",
		"quit_to_menu": "Quit to Menu",
		"difficulty_label": "Difficulty",
		"difficulty_easy": "Easy",
		"difficulty_normal": "Normal",
		"difficulty_hard": "Hard",
		"paused": "Game Paused",
		"streak": "streak %d!",
		"experimental_features": "Experimental Features",
		"drop_ratchet": "Drop Ratchet",
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
	cfg.letter_points = {
		"A": 1, "B": 3, "C": 3, "D": 2, "E": 1, "F": 4, "G": 2, "H": 4,
		"I": 1, "J": 8, "L": 1, "M": 3, "N": 1, "\u00d1": 8, "O": 1, "P": 3,
		"Q": 5, "R": 1, "S": 1, "T": 1, "U": 1, "V": 4, "X": 8, "Y": 4,
		"Z": 10,
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
		# Naturaleza
		"CASA", "LUNA", "SOLA", "RISA", "MESA", "GATO", "LOMA", "PALA",
		"NUBE", "FARO", "ISLA", "PINO", "ROSA", "VINO", "GOTA", "LOBO",
		"NIDO", "MONO", "REMO", "BESO", "LAGO", "ONDA", "ROCA", "CIELO",
		"ARCO", "FLOR", "HOJA", "TORO", "PUMA", "RANA", "PATO", "BUHO",
		"ALBA", "OLAS", "FRIO", "LODO", "CUBO", "MURO", "VELA", "COLA",
		# Hogar y oficio
		"TELA", "CENA", "DADO", "FILO", "MANO", "HORA", "JOTA", "SEDA",
		"HILO", "LAZO", "COPA", "VASO", "SOPA", "MIEL", "NUEZ", "COCO",
		"UVAS", "PERA", "LIMA", "MAIZ", "CAFE", "DEDO", "MAPA", "RUTA",
		# Sentimientos y conceptos
		"AMOR", "VIDA", "ALMA", "BIEN", "CURA", "DAMA", "EDAD", "FAMA",
		"GOZO", "LEAL", "META", "NOTA", "OBRA", "PASO", "RITO", "SANO",
		"TIPO", "USOS", "VALS", "ZONA", "DOTE", "HALO", "MUSA", "OJOS",
		# Sonido y arte
		"CORO", "ARPA", "CAJA", "DANZA", "FUGA", "LIRA", "RIMA", "TONO",
	]
	cfg.ui_strings = {
		"score": "Puntos: %d",
		"game_complete": "\u00a1Juego Completado!\nPuntos: %d",
		"new_high_score": "\u00a1Nueva Puntuaci\u00f3n M\u00e1xima!\n",
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
		"draw_more": "Sacar",
		"need_swap": "\u00a1Necesitas %d puntos para cambiar!",
		"swap_first": "Selecciona la primera letra",
		"swap_second": "Ahora selecciona una letra adyacente",
		"swap_not_adjacent": "\u00a1Las letras deben ser adyacentes!",
		"swap_empty": "\u00a1Ambas casillas deben tener letras!",
		"swap_done": "\u00a1Cambiado! (-%d)",
		"swap_cancel": "Cambio cancelado",
		"need_draw_more": "\u00a1Sacar m\u00e1s no disponible!",
		"draw_more_success": "\u00a1%d letras sacadas!",
		"draw_more_no_space": "\u00a1Tablero lleno! Limpia algunas letras primero",
		"cancel": "Cancelar",
		"play_again": "Jugar de nuevo",
		"quit_to_menu": "Volver al men\u00fa",
		"difficulty_label": "Dificultad",
		"difficulty_easy": "F\u00e1cil",
		"difficulty_normal": "Normal",
		"difficulty_hard": "Dif\u00edcil",
		"paused": "Juego pausado",
		"streak": "racha %d!",
		"experimental_features": "Funciones Experimentales",
		"drop_ratchet": "Aceleraci\u00f3n de Ca\u00edda",
	}
	return cfg
