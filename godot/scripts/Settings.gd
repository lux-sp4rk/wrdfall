extends Control

@onready var language_option: OptionButton = %LanguageOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var difficulty_label: Label = %DifficultyLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	_setup_ui_text()
	_setup_languages()
	_setup_difficulties()
	back_button.pressed.connect(_on_back_pressed)

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
	
	difficulty_option.add_item(cfg.ui_strings["difficulty_easy"], 0)
	difficulty_option.set_item_metadata(0, "easy")
	
	difficulty_option.add_item(cfg.ui_strings["difficulty_hard"], 1)
	difficulty_option.set_item_metadata(1, "hard")
	
	if GameSettings.difficulty == "hard":
		difficulty_option.selected = 1
	else:
		difficulty_option.selected = 0
		
	if not difficulty_option.item_selected.is_connected(_on_difficulty_selected):
		difficulty_option.item_selected.connect(_on_difficulty_selected)

func _on_difficulty_selected(index: int) -> void:
	GameSettings.difficulty = difficulty_option.get_item_metadata(index)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")
