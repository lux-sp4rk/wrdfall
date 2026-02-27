extends GutTest

func test_default_values():
	assert_false(FeatureFlags.drop_ratchet_enabled, "Drop ratchet should be disabled by default")

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

func test_persistence():
	# Set a value
	var original_value = FeatureFlags.drop_ratchet_enabled
	FeatureFlags.drop_ratchet_enabled = true
	FeatureFlags.save_flags()
	
	# Reset in-memory value
	FeatureFlags.drop_ratchet_enabled = false
	
	# Reload from file
	FeatureFlags.load_flags()
	assert_true(FeatureFlags.drop_ratchet_enabled, "Value should be persisted and reloaded")
	
	# Cleanup
	FeatureFlags.drop_ratchet_enabled = original_value
	FeatureFlags.save_flags()
