extends Control

@onready var language_option: OptionButton = %LanguageOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var difficulty_label: Label = %DifficultyLabel
@onready var theme_option: OptionButton = %ThemeOption
@onready var back_button: Button = %BackButton

func _ready() -> void:
	_setup_ui_text()
	_setup_languages()
	_setup_difficulties()
	_setup_themes()
	_apply_theme()
	_update_sync_ui()
	back_button.pressed.connect(_on_back_pressed)
	ThemeManager.theme_changed.connect(_apply_theme)
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

func _on_sync_completed(success: bool) -> void:
	# Sync status UI removed - no action needed
	pass

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

func _setup_themes() -> void:
	theme_option.clear()
	theme_option.add_item("Light", 0)
	theme_option.set_item_metadata(0, "light")
	theme_option.add_item("Dark", 1)
	theme_option.set_item_metadata(1, "dark")

	var selected_index: int = 0 if GameSettings.theme == "light" else 1
	theme_option.selected = selected_index

	if not theme_option.item_selected.is_connected(_on_theme_selected):
		theme_option.item_selected.connect(_on_theme_selected)

func _on_theme_selected(index: int) -> void:
	var theme_name = theme_option.get_item_metadata(index)
	ThemeManager.set_theme(theme_name)

func _apply_theme() -> void:
	# Update background
	var bg = $ColorRect
	if bg:
		bg.color = ThemeManager.get_color("background")

	# Update difficulty label color
	difficulty_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update all labels in LanguageBox
	var lang_label = $MarginContainer/VBox/LanguageBox/Label
	if lang_label:
		lang_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update ThemeBox label
	var theme_label = $MarginContainer/VBox/ThemeBox/Label
	if theme_label:
		theme_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update title
	var title = $MarginContainer/VBox/Title
	if title:
		title.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
