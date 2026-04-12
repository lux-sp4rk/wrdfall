extends Node
class_name HighlightManager

## Highlight Manager
## Visual cue system for the tutorial
## Creates pulsing highlights, hand cursor animations, and tile indicators
## Uses only GPU-accelerated properties (transform, opacity)

# Constants for animations
const PULSE_SCALE_MIN: float = 1.0
const PULSE_SCALE_MAX: float = 1.1
const PULSE_DURATION: float = 0.6
const HAND_CURSOR_SIZE: Vector2 = Vector2(64, 64)

# Node references
var tutorial_controller: TutorialController
var game_instance: Control
var overlay_layer: CanvasLayer

# Active highlight elements
var pulse_rings: Dictionary = {}  # Button -> Panel
var highlighted_tiles: Array = []
var active_tweens: Dictionary = {}

# Hand cursor reference
var _hand_cursor_control: Control = null
var highlight_color: Color = Color(0.35, 0.65, 1.0, 0.8)  # Blue highlight
var valid_tile_color: Color = Color(0.3, 0.7, 1.0, 0.4)

# Demo animation state
var is_demo_playing: bool = false

func _init(controller: TutorialController, game: Control, overlay: CanvasLayer) -> void:
	tutorial_controller = controller
	game_instance = game
	overlay_layer = overlay
	
	# Connect to tutorial signals
	tutorial_controller.request_highlight_cells.connect(_on_request_highlight_cells)
	tutorial_controller.request_clear_highlights.connect(clear_highlights)
	tutorial_controller.request_show_hand_cursor.connect(_on_request_show_hand_cursor)
	tutorial_controller.request_hide_hand_cursor.connect(_on_hide_hand_cursor)
	
	_create_hand_cursor()

func _create_hand_cursor() -> void:
	"""Create the hand cursor control."""
	# Create Control-based cursor
	var cursor_control := Control.new()
	cursor_control.name = "HandCursorControl"
	cursor_control.custom_minimum_size = HAND_CURSOR_SIZE
	cursor_control.z_index = 100
	cursor_control.visible = false
	cursor_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	var cursor_label := Label.new()
	cursor_label.text = "👆"
	cursor_label.add_theme_font_size_override("font_size", 48)
	cursor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cursor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cursor_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cursor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	cursor_control.add_child(cursor_label)
	overlay_layer.add_child(cursor_control)
	
	_hand_cursor_control = cursor_control

# === Public Methods ===

func create_pulse_ring(target_button: Button, color: Color = Color(0.35, 0.65, 1.0, 0.6)) -> void:
	"""Create a pulsing ring highlight around a button."""
	# Remove existing ring if any
	remove_pulse_ring(target_button)
	
	# Create ring panel
	var ring := Panel.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0, 0)
	stylebox.border_color = color
	stylebox.set_border_width_all(4)
	stylebox.set_corner_radius_all(8)
	ring.add_theme_stylebox_override("panel", stylebox)
	
	# Position over the target button
	ring.global_position = target_button.global_position
	ring.size = target_button.size
	ring.z_index = 50
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	overlay_layer.add_child(ring)
	pulse_rings[target_button] = ring
	
	# Create pulse animation
	var tween := ring.create_tween().set_loops()
	active_tweens[target_button] = tween
	
	# Scale from center
	ring.pivot_offset = ring.size / 2
	
	tween.tween_property(ring, "scale", Vector2(PULSE_SCALE_MAX, PULSE_SCALE_MAX), PULSE_DURATION / 2)
	tween.tween_property(ring, "scale", Vector2(PULSE_SCALE_MIN, PULSE_SCALE_MIN), PULSE_DURATION / 2)

func remove_pulse_ring(target_button: Button) -> void:
	"""Remove the pulse ring from a button."""
	if pulse_rings.has(target_button):
		var ring: Panel = pulse_rings[target_button]
		
		# Kill any active tween
		if active_tweens.has(target_button):
			var tween: Tween = active_tweens[target_button]
			if tween and tween.is_valid():
				tween.kill()
			active_tweens.erase(target_button)
		
		ring.queue_free()
		pulse_rings.erase(target_button)

func animate_hand_pointing(path: Array, gesture_type: String = "tap") -> void:
	"""Animate the hand cursor along a demo path."""
	if not _hand_cursor_control:
		return
	
	if path.is_empty():
		return
	
	is_demo_playing = true
	_hand_cursor_control.visible = true
	_hand_cursor_control.modulate.a = 0.0
	
	# Get button positions for path
	var positions: Array = []
	for cell in path:
		if cell is Vector2i:
			var btn: Button = _get_button_at_cell(cell)
			if btn:
				positions.append(btn.global_position + btn.size / 2)
		elif cell is Array and cell.size() >= 2:
			var cell_vec := Vector2i(cell[0], cell[1])
			var btn: Button = _get_button_at_cell(cell_vec)
			if btn:
				positions.append(btn.global_position + btn.size / 2)
	
	if positions.is_empty():
		return
	
	# Start position
	_hand_cursor_control.global_position = positions[0] - _hand_cursor_control.size / 2
	
	# Fade in
	var fade_tween := _hand_cursor_control.create_tween()
	fade_tween.tween_property(_hand_cursor_control, "modulate:a", 1.0, 0.3)
	await fade_tween.finished
	
	# Animate along path
	if gesture_type == "drag":
		await _animate_drag(positions)
	else:
		await _animate_tap(positions)
	
	# Fade out
	var fade_out_tween := _hand_cursor_control.create_tween()
	fade_out_tween.tween_property(_hand_cursor_control, "modulate:a", 0.0, 0.3)
	await fade_out_tween.finished
	
	_hand_cursor_control.visible = false
	is_demo_playing = false

func _animate_drag(positions: Array) -> void:
	"""Animate a drag gesture along positions."""
	var total_duration: float = 1.5
	var segment_duration: float = total_duration / max(1, positions.size() - 1)
	
	for i in range(1, positions.size()):
		var tween := _hand_cursor_control.create_tween()
		tween.tween_property(
			_hand_cursor_control,
			"global_position",
			positions[i] - _hand_cursor_control.size / 2,
			segment_duration
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		await tween.finished

func _animate_tap(positions: Array) -> void:
	"""Animate tap gestures at each position."""
	for pos in positions:
		# Move to position
		_hand_cursor_control.global_position = pos - _hand_cursor_control.size / 2
		
		# Tap animation: scale down then up
		var tween := _hand_cursor_control.create_tween()
		tween.tween_property(_hand_cursor_control, "scale", Vector2(0.8, 0.8), 0.1)
		tween.tween_property(_hand_cursor_control, "scale", Vector2(1.0, 1.0), 0.1)
		
		await tween.finished
		await game_instance.get_tree().create_timer(0.2).timeout

func highlight_valid_tiles(cells: Array) -> void:
	"""Highlight valid/allowed tiles for gated phases."""
	clear_tile_highlights()
	
	for cell in cells:
		var btn: Button = _get_button_at_cell(cell)
		if btn:
			_highlight_tile(btn)
			highlighted_tiles.append(btn)

func clear_highlights() -> void:
	"""Remove all active highlights."""
	# Clear pulse rings
	var buttons_to_clear: Array = pulse_rings.keys()
	for btn in buttons_to_clear:
		remove_pulse_ring(btn)
	
	# Clear tile highlights
	clear_tile_highlights()
	
	# Hide hand cursor
	_on_hide_hand_cursor()

func clear_tile_highlights() -> void:
	"""Clear tile-specific highlights."""
	for btn in highlighted_tiles:
		if is_instance_valid(btn):
			_clear_tile_highlight(btn)
	highlighted_tiles.clear()

func highlight_powerup_button(button_name: String) -> void:
	"""Highlight a power-up button."""
	var button: Button = _get_powerup_button(button_name)
	if button:
		create_pulse_ring(button, Color(1.0, 0.8, 0.2, 0.8))  # Gold color

func remove_powerup_highlight(button_name: String) -> void:
	"""Remove highlight from a power-up button."""
	var button: Button = _get_powerup_button(button_name)
	if button:
		remove_pulse_ring(button)

# === Private Methods ===

func _on_request_highlight_cells(cells: Array) -> void:
	"""Handle request to highlight cells."""
	highlight_valid_tiles(cells)

func _on_request_show_hand_cursor(path: Array, gesture_type: String) -> void:
	"""Handle request to show hand cursor animation."""
	animate_hand_pointing(path, gesture_type)

func _on_hide_hand_cursor() -> void:
	"""Hide the hand cursor."""
	if _hand_cursor_control:
		_hand_cursor_control.visible = false

func _get_button_at_cell(cell: Vector2i) -> Button:
	"""Get the button at a specific grid cell."""
	if not game_instance:
		return null
	
	# Access the buttons array from the game instance
	# This assumes the game instance has a 'buttons' property
	if "buttons" in game_instance:
		var buttons: Array = game_instance.buttons
		if cell.y >= 0 and cell.y < buttons.size():
			var row: Array = buttons[cell.y]
			if cell.x >= 0 and cell.x < row.size():
				return row[cell.x]
	return null

func _highlight_tile(button: Button) -> void:
	"""Apply highlight effect to a tile button."""
	# Store original style
	if not button.has_meta("original_style"):
		var original_style: StyleBox = button.get_theme_stylebox("normal").duplicate()
		button.set_meta("original_style", original_style)
	
	# Create highlighted style
	var highlight_style: StyleBoxFlat = StyleBoxFlat.new()
	highlight_style.bg_color = valid_tile_color
	highlight_style.set_corner_radius_all(4)
	
	button.add_theme_stylebox_override("normal", highlight_style)
	button.add_theme_stylebox_override("hover", highlight_style)

func _clear_tile_highlight(button: Button) -> void:
	"""Clear highlight effect from a tile button."""
	if button.has_meta("original_style"):
		var original_style: StyleBox = button.get_meta("original_style")
		button.add_theme_stylebox_override("normal", original_style)
		button.add_theme_stylebox_override("hover", original_style)
		button.remove_meta("original_style")

func _get_powerup_button(button_name: String) -> Button:
	"""Get a power-up button by name."""
	if not game_instance:
		return null
	
	match button_name:
		"shake":
			return game_instance.get("shake_button") if "shake_button" in game_instance else null
		"swap":
			return game_instance.get("swap_button") if "swap_button" in game_instance else null
		"draw_more":
			return game_instance.get("draw_more_button") if "draw_more_button" in game_instance else null
		_:
			return null

func cleanup() -> void:
	"""Clean up all highlights and resources."""
	clear_highlights()
	
	if _hand_cursor_control:
		_hand_cursor_control.queue_free()
		_hand_cursor_control = null
