extends Control

@onready var play_button: Button = %PlayButton
@onready var stats_button: Button = %StatsButton
@onready var settings_button: Button = %SettingsButton
@onready var high_score_label: Label = %HighScoreLabel
@onready var tagline: Label = $CenterContainer/MainCard/VBox/TitleContainer/Tagline

# Auth UI elements (optional - only if added to Home.tscn)
@onready var auth_panel: Control = get_node_or_null("%AuthPanel")  # Container for auth buttons
@onready var google_button: Button = get_node_or_null("%GoogleButton")
@onready var apple_button: Button = get_node_or_null("%AppleButton")
@onready var guest_button: Button = get_node_or_null("%GuestButton")
@onready var user_status: Label = get_node_or_null("%UserStatus")  # Shows "Signed in as..."
@onready var sign_out_button: Button = get_node_or_null("%SignOutButton")

func _ready() -> void:
	# Main navigation
	play_button.pressed.connect(_on_play_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# Auth buttons
	if google_button:
		google_button.pressed.connect(_on_google_pressed)
	if sign_out_button:
		sign_out_button.pressed.connect(_on_sign_out_pressed)

	# Listen to auth state changes (with guard to prevent duplicate connections)
	if not StatsManager.auth_completed.is_connected(_on_auth_completed):
		StatsManager.auth_completed.connect(_on_auth_completed)

	# Update UI based on current auth state (only if auth UI exists)
	if auth_panel:
		_update_auth_ui()

	# Show high score
	_update_high_score()

	# Set tagline from GameConstants
	if tagline:
		tagline.text = GameConstants.TAGLINE

	# Apply theme
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)

func _update_auth_ui() -> void:
	# Only update if auth UI exists in the scene
	if not auth_panel:
		return

	var is_authenticated = StatsManager.is_authenticated()

	# Show/hide auth panel vs user status
	auth_panel.visible = not is_authenticated

	if user_status:
		user_status.visible = is_authenticated
		if is_authenticated:
			user_status.text = "✓ " + StatsManager.get_user_email()

	if sign_out_button:
		sign_out_button.visible = is_authenticated

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")

func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Stats.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

# Auth handlers
func _on_google_pressed() -> void:
	print("Google sign-in requested")
	if user_status:
		user_status.text = "Signing in..."
		user_status.visible = true
	StatsManager.login_with_google()

func _on_sign_out_pressed() -> void:
	if has_node("/root/Supabase"):
		Supabase.auth.sign_out()
	_update_auth_ui()

func _on_auth_completed(success: bool) -> void:
	_update_auth_ui()
	if success:
		print("Auth successful!")
	else:
		print("Auth failed")

func _update_high_score() -> void:
	if high_score_label:
		if StatsManager.high_score > 0:
			high_score_label.text = "Best: %d" % StatsManager.high_score
			high_score_label.visible = true
		else:
			high_score_label.visible = false

func _apply_theme() -> void:
	# Update background
	var bg = $Background
	if bg:
		bg.color = ThemeManager.get_color("background")

	# Update main card
	var main_card = $CenterContainer/MainCard
	if main_card:
		var panel_style = main_card.get_theme_stylebox("panel")
		if panel_style:
			panel_style.bg_color = ThemeManager.get_color("card_background")
			panel_style.shadow_color = ThemeManager.get_color("shadow")

	# Update title
	var title = $CenterContainer/MainCard/VBox/TitleContainer/Title
	if title:
		title.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update tagline
	var tagline = $CenterContainer/MainCard/VBox/TitleContainer/Tagline
	if tagline:
		tagline.add_theme_color_override("font_color", ThemeManager.get_color("text_secondary"))

	# Update high score label
	if high_score_label:
		high_score_label.add_theme_color_override("font_color", ThemeManager.get_color("accent"))

	# Update Play button StyleBoxes
	var play_btn = %PlayButton
	if play_btn:
		_apply_button_theme(play_btn, "primary")

	# Update Stats and Settings buttons
	for btn_name in ["%StatsButton", "%SettingsButton"]:
		var btn = get_node_or_null(btn_name)
		if btn:
			var normal_style = btn.get_theme_stylebox("normal")
			if normal_style:
				normal_style.bg_color = ThemeManager.get_color("secondary_button")

			var hover_style = btn.get_theme_stylebox("hover")
			if hover_style:
				hover_style.bg_color = ThemeManager.get_color("secondary_button_hover")

			var pressed_style = btn.get_theme_stylebox("pressed")
			if pressed_style:
				pressed_style.bg_color = ThemeManager.get_color("secondary_button_pressed")

	# Update Google sign-in button (tertiary style)
	if google_button:
		var normal_style = google_button.get_theme_stylebox("normal")
		if normal_style:
			normal_style.bg_color = ThemeManager.get_color("tertiary_button")

		var hover_style = google_button.get_theme_stylebox("hover")
		if hover_style:
			hover_style.bg_color = ThemeManager.get_color("tertiary_button_hover")

		var pressed_style = google_button.get_theme_stylebox("pressed")
		if pressed_style:
			pressed_style.bg_color = ThemeManager.get_color("tertiary_button_pressed")

		# Update button text color to be theme-aware
		google_button.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update copyright
	var copyright = $Copyright
	if copyright:
		var muted = ThemeManager.get_color("text_muted")
		copyright.add_theme_color_override("font_color", Color(muted.r, muted.g, muted.b, 0.5))

func _apply_button_theme(btn: Button, button_type: String) -> void:
	"""Apply theme colors to a button based on its type."""
	match button_type:
		"primary":
			var normal_style = btn.get_theme_stylebox("normal")
			if normal_style:
				normal_style.bg_color = ThemeManager.get_color("primary_button")
				normal_style.shadow_color = Color(ThemeManager.get_color("primary_button").r,
					ThemeManager.get_color("primary_button").g,
					ThemeManager.get_color("primary_button").b, 0.2)

			var hover_style = btn.get_theme_stylebox("hover")
			if hover_style:
				hover_style.bg_color = ThemeManager.get_color("primary_button_hover")

			var pressed_style = btn.get_theme_stylebox("pressed")
			if pressed_style:
				pressed_style.bg_color = ThemeManager.get_color("primary_button_pressed")
		
		"secondary":
			var normal_style = btn.get_theme_stylebox("normal")
			if normal_style:
				normal_style.bg_color = ThemeManager.get_color("secondary_button")

			var hover_style = btn.get_theme_stylebox("hover")
			if hover_style:
				hover_style.bg_color = ThemeManager.get_color("secondary_button_hover")

			var pressed_style = btn.get_theme_stylebox("pressed")
			if pressed_style:
				pressed_style.bg_color = ThemeManager.get_color("secondary_button_pressed")
