extends GutTest

var _game = null

func before_each():
	var scene = load("res://scenes/LoomDrop.tscn")
	_game = scene.instantiate()
	add_child(_game)
	# Give it a moment to run _ready
	await get_tree().process_frame

func after_each():
	if is_instance_valid(_game):
		_game.free()
	_game = null

func test_ratchet_progression():
	FeatureFlags.drop_ratchet_enabled = true
	var initial_interval = _game.current_drop_interval
	
	# Trigger ratchet speedup
	_game._ratchet_drop_speed()
	
	var expected = maxf(initial_interval - GameConstants.RATCHET_SPEEDUP, GameConstants.RATCHET_MIN_INTERVAL)
	assert_almost_eq(_game.current_drop_interval, expected, 0.01, "Interval should decrease")

func test_ratchet_reset():
	FeatureFlags.drop_ratchet_enabled = true
	_game.current_drop_interval = GameConstants.RATCHET_MIN_INTERVAL
	
	_game._reset_drop_speed()
	assert_eq(_game.current_drop_interval, _game.base_drop_interval, "Reset should restore base interval")

func test_floor_enforcement():
	FeatureFlags.drop_ratchet_enabled = true
	# Force interval to exactly floor + small amount
	_game.current_drop_interval = GameConstants.RATCHET_MIN_INTERVAL + (GameConstants.RATCHET_SPEEDUP * 0.5)
	
	# This should push it to the floor
	_game._ratchet_drop_speed()
	assert_eq(_game.current_drop_interval, GameConstants.RATCHET_MIN_INTERVAL, "Interval should hit floor")
	
	# Another push should stay at floor
	_game._ratchet_drop_speed()
	assert_eq(_game.current_drop_interval, GameConstants.RATCHET_MIN_INTERVAL, "Interval should not go below floor")

func test_disabled_ratchet_does_nothing():
	FeatureFlags.drop_ratchet_enabled = false
	var initial_interval = _game.current_drop_interval
	
	_game._ratchet_drop_speed()
	assert_eq(_game.current_drop_interval, initial_interval, "Ratchet should do nothing when disabled")

func test_pause_does_not_affect_ratchet():
	FeatureFlags.drop_ratchet_enabled = true
	# Ratchet up first
	_game._ratchet_drop_speed()
	var ratcheted_interval = _game.current_drop_interval
	
	# Pause and resume
	_game._pause()
	assert_true(_game.is_paused, "Game should be paused")
	_game._unpause()
	assert_false(_game.is_paused, "Game should be unpaused")
	
	# Interval should be unchanged through pause cycle
	assert_eq(_game.current_drop_interval, ratcheted_interval, "Pausing should not affect ratchet interval")

func test_new_game_resets_ratchet():
	FeatureFlags.drop_ratchet_enabled = true
	# Ratchet up
	_game._ratchet_drop_speed()
	_game._ratchet_drop_speed()
	var ratcheted = _game.current_drop_interval
	assert_lt(ratcheted, _game.base_drop_interval, "Should be ratcheted down from base")
	assert_gt(_game.drops_since_start, 0, "Should have recorded drops")
	
	# Simulate new game by re-triggering _ready (same lifecycle as scene reload)
	_game._ready()
	
	assert_eq(_game.current_drop_interval, _game.base_drop_interval, "New game should reset interval to base")
	assert_eq(_game.drops_since_start, 0, "New game should reset drop counter")

func test_runtime_toggle_off_resets_speed():
	FeatureFlags.drop_ratchet_enabled = true
	_game.current_drop_interval = GameConstants.RATCHET_MIN_INTERVAL
	
	# Toggling off via singleton should trigger reset in LoomDrop
	FeatureFlags.drop_ratchet_enabled = false
	assert_eq(_game.current_drop_interval, _game.base_drop_interval, "Toggling flag off should reset current drop speed")

