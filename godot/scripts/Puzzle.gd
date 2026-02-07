extends Control

@onready var letter_tray: HBoxContainer = %"LetterTray" if has_node("%LetterTray") else $MarginContainer/VBox/LetterTray
@onready var back_button: Button = $MarginContainer/VBox/BackButton

var loader: PuzzleLoader
var current_puzzle: Dictionary
var tray_letters: Array[String] = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	loader = PuzzleLoader.new()
	load_puzzle(1)

func load_puzzle(puzzle_id: int) -> void:
	current_puzzle = loader.get_puzzle_by_id(puzzle_id)
	if current_puzzle.is_empty():
		return
	tray_letters.clear()
	for letter in current_puzzle.get("tray", []):
		tray_letters.append(letter)
	_populate_tray()

func _populate_tray() -> void:
	for child in letter_tray.get_children():
		child.queue_free()
	for letter in tray_letters:
		var btn := Button.new()
		btn.text = letter
		btn.custom_minimum_size = Vector2(56, 56)
		btn.add_theme_font_size_override("font_size", 26)
		letter_tray.add_child(btn)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
