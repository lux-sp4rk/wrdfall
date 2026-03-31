extends GutTest

func test_default_values():
	assert_eq(GameConstants.ROWS, 5, "Grid should have 5 rows")
	assert_eq(GameConstants.COLS, 5, "Grid should have 5 columns")
	assert_eq(GameConstants.MIN_WORD_LENGTH, 3, "Min word length should be 3")

func test_drop_intervals():
	assert_eq(GameConstants.DROP_INTERVAL_NORMAL, 10.0, "Normal drop interval should be 10s")
	assert_eq(GameConstants.DROP_INTERVAL_HARD, 6.0, "Hard drop interval should be 6s")

func test_power_up_costs_normal():
	assert_eq(GameConstants.get_shake_cost(false), 3, "Normal shake cost should be 3")
	assert_eq(GameConstants.get_swap_cost(false), 2, "Normal swap cost should be 2")
	assert_eq(GameConstants.get_draw_more_cost(false), 5, "Normal draw more cost should be 5")

func test_power_up_costs_hard():
	assert_eq(GameConstants.get_shake_cost(true), 8, "Hard shake cost should be 8")
	assert_eq(GameConstants.get_swap_cost(true), 5, "Hard swap cost should be 5")
	assert_eq(GameConstants.get_draw_more_cost(true), 10, "Hard draw more cost should be 10")

func test_word_multipliers():
	assert_eq(GameConstants.WORD_MULTIPLIERS[3], 1, "3-letter word should have 1x multiplier")
	assert_eq(GameConstants.WORD_MULTIPLIERS[4], 2, "4-letter word should have 2x multiplier")
	assert_eq(GameConstants.WORD_MULTIPLIERS[5], 4, "5-letter word should have 4x multiplier")
	assert_eq(GameConstants.WORD_MULTIPLIERS[6], 8, "6-letter word should have 8x multiplier")

func test_word_multiplier_default():
	assert_eq(GameConstants.WORD_MULTIPLIER_DEFAULT, 8, "Default multiplier should be 8")

func test_ratchet_constants():
	assert_eq(GameConstants.RATCHET_DROPS_PER_STEP, 5, "Ratchet should trigger every 5 drops")
	assert_eq(GameConstants.RATCHET_SPEEDUP, 0.5, "Ratchet speedup should be 0.5s")
	assert_eq(GameConstants.RATCHET_MIN_INTERVAL, 2.0, "Min interval should be 2.0s")

func test_vowel_adjustments():
	assert_eq(GameConstants.get_vowel_adjustment(false), 1.15, "Normal mode should boost vowels")
	assert_eq(GameConstants.get_vowel_adjustment(true), 0.75, "Hard mode should reduce vowels")
