extends Control

@onready var play_button: Button = %PlayButton
@onready var stats_button: Button = %StatsButton
@onready var settings_button: Button = %SettingsButton

# Auth UI elements (add these to Home.tscn)
@onready var auth_panel: Control = %AuthPanel  # Container for auth buttons
@onready var google_button: Button = %GoogleButton
@onready var apple_button: Button = %AppleButton
@onready var guest_button: Button = %GuestButton
@onready var user_status: Label = %UserStatus  # Shows "Signed in as..."
@onready var sign_out_button: Button = %SignOutButton

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

	# Listen to auth state changes
	StatsManager.auth_completed.connect(_on_auth_completed)

	# Update UI based on current auth state (only if auth UI exists)
	if auth_panel:
		_update_auth_ui()

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
