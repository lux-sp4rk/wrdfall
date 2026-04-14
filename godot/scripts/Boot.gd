extends Node
## Boot scene: routes to LoomDrop on web (React Shell owns navigation),
## or to Home on desktop/editor builds.

func _ready() -> void:
	GameSettings.load_from_localstorage()
	var target_scene: String
	if OS.has_feature("web"):
		var launch_scene: String = _get_launch_scene_from_js()
		target_scene = "res://scenes/LoomDrop.tscn"
	else:
		target_scene = "res://scenes/Home.tscn"
	get_tree().call_deferred("change_scene_to_file", target_scene)


func _get_launch_scene_from_js() -> String:
	"""Read launch scene from JavaScript-injected window.WORD_LOOM_LAUNCH_SCENE."""
	if not OS.has_feature("web"):
		return ""
	
	var js_bridge = JavaScriptBridge.get_interface("window")
	if js_bridge == null:
		return ""
	
	# Use eval to safely read the value
	var result = JavaScriptBridge.eval("window.WORD_LOOM_LAUNCH_SCENE || ''")
	if result == null or not (result is String):
		return ""
	
	return result
