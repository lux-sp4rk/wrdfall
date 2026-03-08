extends Control
class_name Tutorial

@onready var tutorial_controller: TutorialController = %TutorialController
@onready var tutorial_loom_drop: TutorialLoomDrop = %TutorialLoomDrop
@onready var tutorial_ui: TutorialUI = %TutorialUI

func _ready() -> void:
	tutorial_controller.start_tutorial()
	tutorial_loom_drop.setup_for_tutorial(tutorial_controller)
	tutorial_ui.setup(tutorial_controller)
	
	tutorial_controller.tutorial_completed.connect(_on_tutorial_completed)

func _on_tutorial_completed(skipped: bool) -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")
