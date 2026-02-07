extends Control

@onready var letter_tray: HBoxContainer = %"LetterTray" if has_node("%LetterTray") else $MarginContainer/VBox/LetterTray
@onready var back_button: Button = $MarginContainer/VBox/BackButton

var tray_letters: Array[String] = ["S", "T", "A", "R", "E", "L", "M"]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_tray()

func _populate_tray() -> void:
	for letter in tray_letters:
		var btn := Button.new()
		btn.text = letter
		btn.custom_minimum_size = Vector2(56, 56)
		btn.add_theme_font_size_override("font_size", 26)
		letter_tray.add_child(btn)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
