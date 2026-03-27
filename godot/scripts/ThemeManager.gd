extends Node

# Signal emitted when theme changes
signal theme_changed

# Current active theme ("light" or "dark")
var current_theme: String = "light"

# Theme color definitions
var themes: Dictionary = {
	"light": {
		"background": Color(0.96, 0.95, 0.91, 1),
		"card_background": Color(1, 1, 1, 1),
		"primary_button": Color(0.88, 0.47, 0.34, 1),
		"primary_button_hover": Color(0.92, 0.52, 0.39, 1),
		"primary_button_pressed": Color(0.82, 0.42, 0.29, 1),
		"secondary_button": Color(0.48, 0.61, 0.55, 1),
		"secondary_button_hover": Color(0.53, 0.66, 0.60, 1),
		"secondary_button_pressed": Color(0.43, 0.56, 0.50, 1),
		"tertiary_button": Color(1, 1, 1, 1),  # White button (for Google sign-in)
		"tertiary_button_hover": Color(0.97, 0.97, 0.97, 1),
		"tertiary_button_pressed": Color(0.94, 0.94, 0.94, 1),
		"text_primary": Color(0.12, 0.12, 0.12, 1),
		"text_secondary": Color(0.30, 0.40, 0.35, 1),
		"text_muted": Color(0.6, 0.6, 0.6, 1),
		"divider": Color(0.85, 0.85, 0.85, 0.5),
		"shadow": Color(0, 0, 0, 0.12),
		"tile_background": Color(0.98, 0.97, 0.94, 1),
		"tile_text": Color(0.17, 0.17, 0.17, 1),
		"grid_line": Color(0.8, 0.8, 0.8, 1),
		"selection_highlight": Color(0.88, 0.47, 0.34, 0.3),
		"accent": Color(0.88, 0.47, 0.34, 1),
	},
	"dark": {
		"background": Color(0.17, 0.24, 0.31, 1),
		"card_background": Color(0.21, 0.29, 0.37, 1),
		"primary_button": Color(0.95, 0.57, 0.44, 1),  # Lighter terracotta for dark mode
		"primary_button_hover": Color(0.98, 0.62, 0.49, 1),
		"primary_button_pressed": Color(0.88, 0.47, 0.34, 1),
		"secondary_button": Color(0.30, 0.42, 0.54, 1),  # Muted blue-gray
		"secondary_button_hover": Color(0.35, 0.47, 0.59, 1),
		"secondary_button_pressed": Color(0.25, 0.37, 0.49, 1),
		"tertiary_button": Color(0.25, 0.33, 0.41, 1),  # Dark subtle button (for Google sign-in)
		"tertiary_button_hover": Color(0.30, 0.38, 0.46, 1),
		"tertiary_button_pressed": Color(0.20, 0.28, 0.36, 1),
		"text_primary": Color(0.95, 0.95, 0.95, 1),
		"text_secondary": Color(0.60, 0.75, 0.70, 1),
		"text_muted": Color(0.6, 0.6, 0.6, 1),
		"divider": Color(0.4, 0.4, 0.4, 0.3),
		"shadow": Color(0, 0, 0, 0.3),
		"tile_background": Color(0.25, 0.33, 0.41, 1),
		"tile_text": Color(0.95, 0.95, 0.95, 1),
		"grid_line": Color(0.3, 0.4, 0.5, 1),
		"selection_highlight": Color(0.88, 0.47, 0.34, 0.4),
		"accent": Color(0.95, 0.57, 0.44, 1),  # Lighter accent for dark mode
	}
}

func _ready() -> void:
	# Web: Try localStorage first, then ConfigFile
	if OS.has_feature("web"):
		var web_theme = _load_from_localstorage()
		if web_theme != "":
			current_theme = web_theme
			GameSettings.theme = web_theme
			print("ThemeManager: Loaded theme from localStorage: ", web_theme)
			_apply_clear_color()
			return  # Skip ConfigFile load on web if localStorage has valid theme

	# Desktop or localStorage empty: Load from ConfigFile
	_load_settings()
	current_theme = GameSettings.theme
	_apply_clear_color()

func _load_from_localstorage() -> String:
	"""Load theme from localStorage (web only)
	Returns theme string ('light' or 'dark') or empty string if unavailable
	"""
	if not OS.has_feature("web"):
		return ""  # Desktop build, skip localStorage

	var js_interface = JavaScriptBridge.get_interface("localStorage")
	if js_interface == null:
		push_warning("localStorage interface not available")
		return ""

	var theme = js_interface.getItem("wordfall-theme")
	if theme == null or theme == "":
		return ""

	# Validate theme value
	if theme != "light" and theme != "dark":
		push_warning("Invalid theme in localStorage: " + str(theme))
		return ""

	return theme

func _sync_to_localstorage(theme_name: String) -> void:
	"""Write theme to localStorage (web only)"""
	if not OS.has_feature("web"):
		return  # Desktop build, skip localStorage

	var js_interface = JavaScriptBridge.get_interface("localStorage")
	if js_interface == null:
		push_warning("localStorage interface not available, cannot sync theme")
		return

	js_interface.setItem("wordfall-theme", theme_name)
	print("ThemeManager: Synced theme to localStorage: ", theme_name)

func get_color(key: String) -> Color:
	var theme_colors = themes.get(current_theme, themes["light"])
	return theme_colors.get(key, Color.WHITE)

func set_theme(theme_name: String) -> void:
	if theme_name not in ["light", "dark"]:
		push_warning("Invalid theme name: " + theme_name)
		return

	current_theme = theme_name
	GameSettings.theme = theme_name
	_save_settings()
	_sync_to_localstorage(theme_name)  # NEW: Sync to localStorage on web
	_apply_clear_color()
	theme_changed.emit()

func toggle_theme() -> void:
	var new_theme = "dark" if current_theme == "light" else "light"
	set_theme(new_theme)

func _apply_clear_color() -> void:
	RenderingServer.set_default_clear_color(get_color("background"))

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("game", "theme", GameSettings.theme)
	config.set_value("game", "language", GameSettings.current_language)
	config.set_value("game", "difficulty", GameSettings.difficulty)
	var err = config.save("user://settings.cfg")
	if err != OK:
		push_warning("Failed to save settings: " + str(err))

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		GameSettings.theme = config.get_value("game", "theme", "light")
		GameSettings.current_language = config.get_value("game", "language", "en")
		GameSettings.difficulty = config.get_value("game", "difficulty", "normal")
	else:
		# File doesn't exist yet, use defaults
		pass
