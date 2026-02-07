extends Control

@onready var grid_container: GridContainer = %"GridContainer"
@onready var back_button: Button = %"BackButton"

const ROWS = 12
const COLS = 8

var grid: Array = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_initialize_grid()

func _initialize_grid() -> void:
	# Clear existing children if any
	for child in grid_container.get_children():
		child.queue_free()
	
	grid_container.columns = COLS
	
	# Scrabble-like distribution (simplified for now)
	var bag = "EEEEEEEEEEEEAAAAAAAAAIIIIIIIIIOOOOOOOOONNNNNNRRRRRRTTTTTTTTLLLLSSSSUUUUUDDDDGGGBBCCMMPPFFHHVVWWYYKJXQZ"
	
	for i in range(ROWS * COLS):
		var letter = bag[randi() % bag.length()]
		var btn := Button.new()
		btn.text = letter
		btn.custom_minimum_size = Vector2(48, 48)
		btn.add_theme_font_size_override("font_size", 24)
		grid_container.add_child(btn)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
