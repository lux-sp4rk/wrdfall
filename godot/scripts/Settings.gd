extends Control

@onready var language_option: OptionButton = %LanguageOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var difficulty_label: Label = %DifficultyLabel
@onready var back_button: Button = %BackButton
@onready var login_button: Button = %LoginButton
@onready var sync_status: Label = %SyncStatus

func _ready() -> void:
	_setup_ui_text()
	_setup_languages()
	_setup_difficulties()
	_update_sync_ui()
	back_button.pressed.connect(_on_back_pressed)
	# login_button and sync_status references removed for cleaner UI
	StatsManager.auth_completed.connect(_on_auth_completed)
	StatsManager.sync_completed.connect(_on_sync_completed)

func _update_sync_ui() -> void:
	# UI elements removed from scene should not be updated via code
	pass

func _on_login_pressed() -> void:
	# Logic handled automatically on boot or via Home screen auth buttons
	pass

func _on_auth_completed(success: bool) -> void:
	_update_sync_ui()
	if success:
		sync_status.text = "Successfully signed in!"

func _on_sync_completed(success: bool) -> void:
	if success:
		sync_status.text = "Stats synced with cloud"
	else:
		sync_status.text = "Sync failed"

func _setup_ui_text() -> void:
	var cfg = LanguageConfig.get_config(GameSettings.current_language)
	difficulty_label.text = cfg.ui_strings["difficulty_label"]

func _setup_languages() -> void:
	language_option.clear()
	var languages: Array = LanguageConfig.available_languages()
	for i in range(languages.size()):
		var lang: Dictionary = languages[i]
		language_option.add_item(lang.display_name, i)
		if lang.code == GameSettings.current_language:
			language_option.selected = i
	
	language_option.item_selected.connect(_on_language_selected)

func _on_language_selected(index: int) -> void:
	var languages: Array = LanguageConfig.available_languages()
	GameSettings.current_language = languages[index].code
	_setup_ui_text()
	_setup_difficulties()

func _setup_difficulties() -> void:
	difficulty_option.clear()
	var cfg = LanguageConfig.get_config(GameSettings.current_language)

	difficulty_option.add_item(cfg.ui_strings["difficulty_normal"], 0)
	difficulty_option.set_item_metadata(0, "normal")

	difficulty_option.add_item(cfg.ui_strings["difficulty_hard"], 1)
	difficulty_option.set_item_metadata(1, "hard")

	var selected_index: int = 0
	for i in range(difficulty_option.get_item_count()):
		if difficulty_option.get_item_metadata(i) == GameSettings.difficulty:
			selected_index = i
			break
	difficulty_option.selected = selected_index

	if not difficulty_option.item_selected.is_connected(_on_difficulty_selected):
		difficulty_option.item_selected.connect(_on_difficulty_selected)

func _on_difficulty_selected(index: int) -> void:
	GameSettings.difficulty = difficulty_option.get_item_metadata(index)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")
