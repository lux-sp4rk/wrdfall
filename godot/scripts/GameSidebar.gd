extends Panel

## GameSidebar Component
## Slide-in navigation menu with Settings, Stats, Rules, Help buttons

signal sidebar_opened
signal sidebar_closed

var is_open: bool = false
var active_tween: Tween = null

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

	# Kill previous tween if still running
	if active_tween:
		active_tween.kill()

	# Slide in from left
	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(self, "position:x", 0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	active_tween.tween_property(background_overlay, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return

	is_open = false
	sidebar_closed.emit()

	# Kill previous tween if still running
	if active_tween:
		active_tween.kill()

	# Slide out to left
	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(self, "position:x", -300, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	active_tween.tween_property(background_overlay, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)

	# Hide after animation completes
	await active_tween.finished
	visible = false


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func _on_close_pressed() -> void:
	close()


func _on_settings_pressed() -> void:
	close()
	await sidebar_closed
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_stats_pressed() -> void:
	close()
	await sidebar_closed
	get_tree().change_scene_to_file("res://scenes/Stats.tscn")


func _on_rules_pressed() -> void:
	print("Rules screen not yet created")
	# TODO: Navigate to Rules.tscn when created


func _on_help_pressed() -> void:
	print("Help screen not yet created")
	# TODO: Navigate to Help.tscn when created


func _apply_theme() -> void:
	# Panel background
	var panel_style = get_theme_stylebox("panel")
	if panel_style:
		panel_style.bg_color = ThemeManager.get_color("card_background")
		panel_style.border_color = ThemeManager.get_color("accent")

	# Overlay (semi-transparent background behind sidebar)
	if background_overlay:
		var overlay_color = ThemeManager.get_color("text_primary")
		background_overlay.color = Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.5)

	# Style all buttons
	var buttons = [close_button, settings_button, stats_button, rules_button, help_button]
	for button in buttons:
		if button:
			# Normal state
			var normal_style = button.get_theme_stylebox("normal")
			if normal_style:
				normal_style.bg_color = ThemeManager.get_color("secondary_button")

			# Hover state
			var hover_style = button.get_theme_stylebox("hover")
			if hover_style:
				hover_style.bg_color = ThemeManager.get_color("secondary_button_hover")

			# Pressed state
			var pressed_style = button.get_theme_stylebox("pressed")
			if pressed_style:
				pressed_style.bg_color = ThemeManager.get_color("secondary_button_pressed")

			# Text colors
			button.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
			button.add_theme_color_override("font_hover_color", ThemeManager.get_color("text_primary"))
			button.add_theme_color_override("font_pressed_color", ThemeManager.get_color("text_primary"))
