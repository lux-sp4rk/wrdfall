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

const DROP_INTERVAL_NORMAL: float = 10.0
const DROP_INTERVAL_HARD: float = 6.0

# === Power-Up Costs ===

# Normal difficulty
const SHAKE_COST_NORMAL: int = 3
const SWAP_COST_NORMAL: int = 2
const DRAW_MORE_COST_NORMAL: int = 5 # we want to encourage draws
const FREEZE_COST_NORMAL: int = 10

# Hard difficulty
const SHAKE_COST_HARD: int = 8
const SWAP_COST_HARD: int = 5
const DRAW_MORE_COST_HARD: int = 10 # we want to encourage draws
const FREEZE_COST_HARD: int = 15

# === Vowel Ratios ===

# Adjustments to base vowel percentage (multiply by base language ratio)
const VOWEL_BOOST_NORMAL: float = 1.15  # +15% vowels in normal mode
const VOWEL_REDUCTION_HARD: float = 0.75  # -25% vowels in hard mode

# === Scoring Multipliers (by word length) ===
const WORD_MULTIPLIERS: Dictionary = {
	3: 1,    # 3-letter: base score
	4: 2,    # 4-letter: 2x
	5: 4,    # 5-letter: 4x
	6: 8,    # 6-letter: 8x
}
const WORD_MULTIPLIER_DEFAULT: int = 8  # 6+ all get 8x

# === Combo Streak ===
const COMBO_THRESHOLD: int = 4          # Minimum word length to build/maintain streak
const COMBO_MULTIPLIER_PER_STREAK: float = 0.5  # Each streak step adds 0.5x
const COMBO_MULTIPLIER_MAX: float = 3.0         # Cap at 3x combo multiplier

# === Drop Speed Ratchet ===
const RATCHET_DROPS_PER_STEP: int = 5           # Speed up every N drops
const RATCHET_SPEEDUP: float = 0.5              # Reduce interval by 0.5s per step
const RATCHET_MIN_INTERVAL: float = 2.0         # Floor — never faster than 2s
const RATCHET_RESET_WORD_LENGTH: int = 5        # 5+ letter word resets speed

# === Progressive Cost Increments ===
const SHAKE_COST_INCREMENT: int = 2
const SWAP_COST_INCREMENT: int = 2
const DRAW_MORE_COST_INCREMENT: int = 3
const FREEZE_COST_INCREMENT: int = 5

# === UI Text ===

const TAGLINE: String = "Word-building meets Tetris"  # Main tagline displayed on home screen

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
