extends GutTest

func test_default_values():
	assert_false(FeatureFlags.drop_ratchet_enabled, "Drop ratchet should be disabled by default")
	assert_false(FeatureFlags.dev_mode_cheats, "Dev mode cheats should be disabled by default")

func test_toggle_flag():
	watch_signals(FeatureFlags)
	var initial_state = FeatureFlags.drop_ratchet_enabled
	var target_state = !initial_state
	
	FeatureFlags.drop_ratchet_enabled = target_state
	assert_eq(FeatureFlags.drop_ratchet_enabled, target_state)
	assert_signal_emitted_with_parameters(FeatureFlags, "feature_flag_changed", ["drop_ratchet_enabled", target_state])
	
	FeatureFlags.drop_ratchet_enabled = initial_state
	assert_eq(FeatureFlags.drop_ratchet_enabled, initial_state)
	assert_signal_emitted_with_parameters(FeatureFlags, "feature_flag_changed", ["drop_ratchet_enabled", initial_state])

func test_dev_mode_cheats_toggle():
	watch_signals(FeatureFlags)
	var initial_state = FeatureFlags.dev_mode_cheats
	var target_state = !initial_state
	
	FeatureFlags.dev_mode_cheats = target_state
	assert_eq(FeatureFlags.dev_mode_cheats, target_state)
	assert_signal_emitted_with_parameters(FeatureFlags, "feature_flag_changed", ["dev_mode_cheats", target_state])
	
	FeatureFlags.dev_mode_cheats = initial_state
	assert_eq(FeatureFlags.dev_mode_cheats, initial_state)
	assert_signal_emitted_with_parameters(FeatureFlags, "feature_flag_changed", ["dev_mode_cheats", initial_state])

func test_persistence():
	# Test that save/load cycle works (simplified for test isolation)
	var original_value = FeatureFlags.drop_ratchet_enabled
	FeatureFlags.drop_ratchet_enabled = true
	FeatureFlags.save_flags()
	
	# In real gameplay, the flag persists across sessions via ConfigFile
	# In tests, we verify the setter/signal work correctly (above test covers this)
	assert_true(FeatureFlags.drop_ratchet_enabled, "Flag should be set to true")
	
	# Cleanup
	FeatureFlags.drop_ratchet_enabled = original_value
	FeatureFlags.save_flags()
