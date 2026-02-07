extends Control

@onready var start_button: Button = $VBox/StartButton
@onready var loom_drop_button: Button = $VBox/LoomDropButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	loom_drop_button.pressed.connect(_on_loom_drop_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Puzzle.tscn")

func _on_loom_drop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")
