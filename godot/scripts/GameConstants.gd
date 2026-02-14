extends Node

## Game Constants
## Central configuration for all game mechanics and rules
## Access globally via: GameConstants.ROWS

# === Grid Configuration ===

const ROWS: int = 5
const COLS: int = 5
const INITIAL_FILL_ROWS: int = 3  # Number of rows to seed with initial letters

# === Word Rules ===

const MIN_WORD_LENGTH: int = 3  # Minimum letters to form a valid word

# === Drop Timing (seconds) ===

const DROP_INTERVAL_NORMAL: float = 8.0
const DROP_INTERVAL_HARD: float = 4.0

# === Power-Up Costs ===

# Normal difficulty
const SHAKE_COST_NORMAL: int = 3
const SWAP_COST_NORMAL: int = 2
const DRAW_MORE_COST_NORMAL: int = 5 # we want to encourage draws

# Hard difficulty
const SHAKE_COST_HARD: int = 8
const SWAP_COST_HARD: int = 5
const DRAW_MORE_COST_HARD: int = 10 # we want to encourage draws

# === Vowel Ratios ===

# Adjustments to base vowel percentage (multiply by base language ratio)
const VOWEL_BOOST_NORMAL: float = 1.15  # +15% vowels in normal mode
const VOWEL_REDUCTION_HARD: float = 0.75  # -25% vowels in hard mode

# === Helper Functions ===

## Get power-up costs based on current difficulty
static func get_shake_cost(is_hard_mode: bool) -> int:
	return SHAKE_COST_HARD if is_hard_mode else SHAKE_COST_NORMAL

static func get_swap_cost(is_hard_mode: bool) -> int:
	return SWAP_COST_HARD if is_hard_mode else SWAP_COST_NORMAL

static func get_draw_more_cost(is_hard_mode: bool) -> int:
	return DRAW_MORE_COST_HARD if is_hard_mode else DRAW_MORE_COST_NORMAL

static func get_drop_interval(is_hard_mode: bool) -> float:
	return DROP_INTERVAL_HARD if is_hard_mode else DROP_INTERVAL_NORMAL

static func get_vowel_adjustment(is_hard_mode: bool) -> float:
	return VOWEL_REDUCTION_HARD if is_hard_mode else VOWEL_BOOST_NORMAL
