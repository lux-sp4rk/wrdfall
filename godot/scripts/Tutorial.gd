extends Control
class_name Tutorial

@onready var tutorial_controller: TutorialController = %TutorialController
@onready var tutorial_ui: TutorialUI = %TutorialUI

func _ready() -> void:
	# Tutorial temporarily disabled - see issue #238
	# To re-enable: uncomment below and remove the immediate scene change
	# tutorial_controller.start_tutorial()
	# tutorial_ui.setup(tutorial_controller)
	# tutorial_controller.tutorial_completed.connect(_on_tutorial_completed)

	# Skip tutorial and go straight to game
	get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")

func _on_tutorial_completed(skipped: bool) -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")
