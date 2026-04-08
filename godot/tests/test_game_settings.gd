extends GutTest

func test_initial_settings():
	# Reset to defaults before checking (in case saved settings differ)
	GameSettings.current_language = "en"
	GameSettings.difficulty = "normal"
	GameSettings.theme = "light"
	assert_eq(GameSettings.current_language, "en", "Default language should be en")
	assert_eq(GameSettings.difficulty, "normal", "Default difficulty should be normal")
	assert_eq(GameSettings.theme, "light", "Default theme should be light")

func test_get_drop_interval_normal():
	GameSettings.difficulty = "normal"
	assert_eq(GameSettings.get_drop_interval(), 10.0, "Normal drop interval should be 10s")

func test_get_drop_interval_hard():
	GameSettings.difficulty = "hard"
	assert_eq(GameSettings.get_drop_interval(), 6.0, "Hard drop interval should be 6s")

func test_get_drop_interval_default():
	GameSettings.difficulty = "invalid"
	assert_eq(GameSettings.get_drop_interval(), 8.0, "Invalid difficulty should return default")

func test_get_power_up_cost_shake_normal():
	GameSettings.difficulty = "normal"
	assert_eq(GameSettings.get_power_up_cost("shake"), 3, "Normal shake cost should be 3")

func test_get_power_up_cost_shake_hard():
	GameSettings.difficulty = "hard"
	assert_eq(GameSettings.get_power_up_cost("shake"), 8, "Hard shake cost should be 8")

func test_get_power_up_cost_swap():
	GameSettings.difficulty = "normal"
	assert_eq(GameSettings.get_power_up_cost("swap"), 2, "Normal swap cost should be 2")

func test_get_power_up_cost_draw_more():
	GameSettings.difficulty = "normal"
	assert_eq(GameSettings.get_power_up_cost("draw_more"), 5, "Normal draw more cost should be 5")

func test_get_power_up_cost_invalid():
	GameSettings.difficulty = "normal"
	assert_eq(GameSettings.get_power_up_cost("invalid"), 0, "Invalid power-up should return 0")

func test_get_vowel_ratio_multiplier_normal():
	GameSettings.difficulty = "normal"
	assert_eq(GameSettings.get_vowel_ratio_multiplier(), 1.15, "Normal should boost vowels")

func test_get_vowel_ratio_multiplier_hard():
	GameSettings.difficulty = "hard"
	assert_eq(GameSettings.get_vowel_ratio_multiplier(), 0.75, "Hard should reduce vowels")

func test_is_rescue_enabled_normal():
	GameSettings.difficulty = "normal"
	assert_true(GameSettings.is_rescue_enabled(), "Rescue should be enabled in normal mode")

func test_is_rescue_enabled_hard():
	GameSettings.difficulty = "hard"
	assert_false(GameSettings.is_rescue_enabled(), "Rescue should be disabled in hard mode")

func test_settings_save_and_load():
	# Save current settings
	var original_theme = GameSettings.theme
	var original_lang = GameSettings.current_language
	var original_difficulty = GameSettings.difficulty
	
	# Change and save
	GameSettings.theme = "dark"
	GameSettings.current_language = "es"
	GameSettings.difficulty = "hard"
	GameSettings.save_settings()
	
	# Restore original
	GameSettings.theme = original_theme
	GameSettings.current_language = original_lang
	GameSettings.difficulty = original_difficulty
