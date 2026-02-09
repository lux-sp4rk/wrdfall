extends Control

@onready var language_option: OptionButton = %LanguageOption
@onready var back_button: Button = %BackButton

func _ready() -> void:
	_setup_languages()
	back_button.pressed.connect(_on_back_pressed)

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

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")
