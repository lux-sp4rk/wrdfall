extends Node
## Boot scene: routes to LoomDrop on web (React Shell owns navigation),
## or to Home on desktop/editor builds.

func _ready() -> void:
	GameSettings.load_from_localstorage()
	if OS.has_feature("web"):
		get_tree().change_scene_to_file("res://scenes/LoomDrop.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Home.tscn")
