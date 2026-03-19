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

func _ready() -> void:
	load_flags()

func save_flags() -> void:
	var config := ConfigFile.new()
	config.set_value("flags", "drop_ratchet_enabled", drop_ratchet_enabled)
	config.set_value("flags", "draw_more_enabled", draw_more_enabled)
	var err := config.save(FLAGS_FILE)
	if err != OK:
		push_error("FeatureFlags: Failed to save flags: " + str(err))
	
	# Also sync to localStorage for React consistency if on web
	if OS.has_feature("web"):
		var js = JavaScriptBridge.get_interface("localStorage")
		if js:
			js.setItem("word-loom-drop-ratchet-enabled", "true" if drop_ratchet_enabled else "false")
			js.setItem("word-loom-draw-more-enabled", "true" if draw_more_enabled else "false")

func load_flags() -> void:
	var config := ConfigFile.new()
	var err := config.load(FLAGS_FILE)
	
	if err == OK:
		drop_ratchet_enabled = config.get_value("flags", "drop_ratchet_enabled", false)
		draw_more_enabled = config.get_value("flags", "draw_more_enabled", true)
	else:
		drop_ratchet_enabled = false
		draw_more_enabled = true
	
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
