extends Panel

## GameSidebar Component
## Slide-in navigation menu with Settings, Stats, Rules, Help buttons

signal sidebar_opened
signal sidebar_closed

var is_open: bool = false

@onready var background_overlay: ColorRect = %BackgroundOverlay
@onready var button_container: VBoxContainer = %ButtonContainer
@onready var close_button: Button = %CloseButton
@onready var settings_button: Button = %SettingsButton
@onready var stats_button: Button = %StatsButton
@onready var rules_button: Button = %RulesButton
@onready var help_button: Button = %HelpButton


func _ready() -> void:
	# Initial position (off-screen left)
	position.x = -300

	# Connect theme system
	ThemeManager.theme_changed.connect(_apply_theme)
	_apply_theme()

	# Connect button signals
	close_button.pressed.connect(_on_close_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	help_button.pressed.connect(_on_help_pressed)

	# Connect overlay click to close
	background_overlay.gui_input.connect(_on_overlay_input)

	# Initially hide overlay
	background_overlay.modulate.a = 0.0


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return

	is_open = true
	visible = true
	sidebar_opened.emit()

	# Slide in from left
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", 0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(background_overlay, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return

	is_open = false
	sidebar_closed.emit()

	# Slide out to left
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", -300, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(background_overlay, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)

	# Hide after animation completes
	await tween.finished
	visible = false


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func _on_close_pressed() -> void:
	close()


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Stats.tscn")


func _on_rules_pressed() -> void:
	print("Rules screen not yet created")
	# TODO: Navigate to Rules.tscn when created


func _on_help_pressed() -> void:
	print("Help screen not yet created")
	# TODO: Navigate to Help.tscn when created


func _apply_theme() -> void:
	var theme_colors = ThemeManager.get_current_theme()

	# Panel background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = theme_colors["bg"]
	panel_style.border_width_left = 0
	panel_style.border_width_top = 0
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 0
	panel_style.border_color = theme_colors["primary"]
	add_theme_stylebox_override("panel", panel_style)

	# Overlay (semi-transparent background behind sidebar)
	background_overlay.color = Color(theme_colors["text"], 0.3)

	# Style all buttons
	var buttons = [close_button, settings_button, stats_button, rules_button, help_button]
	for button in buttons:
		_style_button(button, theme_colors)


func _style_button(button: Button, theme_colors: Dictionary) -> void:
	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = theme_colors["bg"]
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = theme_colors["primary"]
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal_style)

	# Hover state
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = theme_colors["primary"]
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = theme_colors["primary"]
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed state
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = theme_colors["primary"].darkened(0.2)
	pressed_style.border_width_left = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = theme_colors["primary"]
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("pressed", pressed_style)

	# Text colors
	button.add_theme_color_override("font_color", theme_colors["text"])
	button.add_theme_color_override("font_hover_color", theme_colors["bg"])
	button.add_theme_color_override("font_pressed_color", theme_colors["bg"])

	# Font size
	button.add_theme_font_size_override("font_size", 28)
