extends Control

@onready var play_button: Button = %PlayButton
@onready var stats_button: Button = %StatsButton
@onready var settings_button: Button = %SettingsButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")

func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Stats.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
