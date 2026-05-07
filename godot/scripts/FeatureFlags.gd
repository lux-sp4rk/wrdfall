extends Node

## FeatureFlags.gd
## Autoload singleton for managing feature toggles
## Data persists via ConfigFile (maps to IndexedDB on web builds)

const FLAGS_FILE: String = "user://feature_flags.cfg"

signal feature_flag_changed(flag_name: String, value: bool)

var drop_ratchet_enabled: bool = false:
	set(val):
		if drop_ratchet_enabled != val:
			drop_ratchet_enabled = val
			feature_flag_changed.emit("drop_ratchet_enabled", val)
			save_flags()

var draw_more_enabled: bool = true:
	set(val):
		if draw_more_enabled != val:
			draw_more_enabled = val
			feature_flag_changed.emit("draw_more_enabled", val)
			save_flags()

var dev_mode_cheats: bool = false:
	set(val):
		if dev_mode_cheats != val:
			dev_mode_cheats = val
			feature_flag_changed.emit("dev_mode_cheats", val)
			save_flags()

var test_flag_ping: bool = false:
	set(val):
		if test_flag_ping != val:
			test_flag_ping = val
			feature_flag_changed.emit("test_flag_ping", val)
			save_flags()

var word_definitions_enabled: bool = true:
	set(val):
		if word_definitions_enabled != val:
			word_definitions_enabled = val
			feature_flag_changed.emit("word_definitions_enabled", val)
			save_flags()

func _ready() -> void:
	load_flags()

func save_flags() -> void:
	var config := ConfigFile.new()
	config.set_value("flags", "drop_ratchet_enabled", drop_ratchet_enabled)
	config.set_value("flags", "draw_more_enabled", draw_more_enabled)
	config.set_value("flags", "dev_mode_cheats", dev_mode_cheats)
	config.set_value("flags", "test_flag_ping", test_flag_ping)
	config.set_value("flags", "word_definitions_enabled", word_definitions_enabled)
	var err := config.save(FLAGS_FILE)
	if err != OK:
		push_error("FeatureFlags: Failed to save flags: " + str(err))

	# Also sync to localStorage for React consistency if on web
	if OS.has_feature("web"):
		var js = JavaScriptBridge.get_interface("localStorage")
		if js:
			js.setItem("word-loom-drop-ratchet-enabled", "true" if drop_ratchet_enabled else "false")
			js.setItem("word-loom-draw-more-enabled", "true" if draw_more_enabled else "false")
			js.setItem("word-loom-dev-mode-cheats", "true" if dev_mode_cheats else "false")
			js.setItem("word-loom-test-flag-ping", "true" if test_flag_ping else "false")
			js.setItem("word-loom-word-definitions-enabled", "true" if word_definitions_enabled else "false")

func load_flags() -> void:
	var config := ConfigFile.new()
	var err := config.load(FLAGS_FILE)
	
	if err == OK:
		drop_ratchet_enabled = config.get_value("flags", "drop_ratchet_enabled", false)
		draw_more_enabled = config.get_value("flags", "draw_more_enabled", true)
		dev_mode_cheats = config.get_value("flags", "dev_mode_cheats", false)
		test_flag_ping = config.get_value("flags", "test_flag_ping", false)
		word_definitions_enabled = config.get_value("flags", "word_definitions_enabled", true)
	else:
		drop_ratchet_enabled = false
		draw_more_enabled = true
		dev_mode_cheats = false
		test_flag_ping = false
		word_definitions_enabled = true
	
	# Web localStorage override (React-driven changes)
	if OS.has_feature("web"):
		var js = JavaScriptBridge.get_interface("localStorage")
		if js:
			var val = js.getItem("word-loom-drop-ratchet-enabled")
			if val != null:
				drop_ratchet_enabled = (val == "true")
			var draw_val = js.getItem("word-loom-draw-more-enabled")
			if draw_val != null:
				draw_more_enabled = (draw_val == "true")
			var cheats_val = js.getItem("word-loom-dev-mode-cheats")
			if cheats_val != null:
				dev_mode_cheats = (cheats_val == "true")
			var ping_val = js.getItem("word-loom-test-flag-ping")
			if ping_val != null:
				test_flag_ping = (ping_val == "true")
			var def_val = js.getItem("word-loom-word-definitions-enabled")
			if def_val != null:
				word_definitions_enabled = (def_val == "true")
