extends Control
## Visual sand timer — draws an hourglass whose sand level depletes with the drop timer.
## Positioned in the action bar as a peripheral cue; no numbers needed.

@export var sand_color_top: Color = Color(0.85, 0.65, 0.25, 1.0)
@export var sand_color_bottom: Color = Color(0.72, 0.52, 0.15, 1.0)
@export var frame_color: Color = Color(0.45, 0.35, 0.25, 0.9)
@export var background_color: Color = Color(0.12, 0.10, 0.08, 0.6)

var _ratio: float = 1.0  # 1.0 = full, 0.0 = empty

func _ready() -> void:
	ratio = 1.0

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 4 or h < 4:
		return

	# Hourglass frame — slightly inset with rounded corners
	var frame_rect := Rect2(1.0, 1.0, w - 2.0, h - 2.0)
	draw_rect(frame_rect, background_color, true)

	var fill_w: float = w - 4.0
	var fill_h: float = h - 4.0

	# --- Top sand (depleting from top) ---
	var top_h: float = fill_h * 0.5 * _ratio
	if top_h > 0.5:
		var top_rect := Rect2(2.0, 2.0 + (fill_h * 0.5 - top_h), fill_w, top_h)
		_draw_sand_layer(top_rect, true)

	# --- Bottom sand (accumulating from bottom) ---
	var bottom_h: float = fill_h * 0.5 * (1.0 - _ratio)
	if bottom_h > 0.5:
		var bottom_rect := Rect2(2.0, 2.0 + fill_h * 0.5, fill_w, bottom_h)
		_draw_sand_layer(bottom_rect, false)

	# Frame outline
	draw_rect(frame_rect, frame_color, false, 2.0, true)

func _draw_sand_layer(rect: Rect2, is_top: bool) -> void:
	# Main sand fill
	draw_rect(rect, sand_color_top if is_top else sand_color_bottom, true)

	# Subtle shimmer line on top edge of each sand column
	var shimmer_col := Color(1.0, 1.0, 1.0, 0.12)
	if is_top:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), shimmer_col, true)
	else:
		# Bottom sand gets a slightly darker base
		var base_col := Color(0.0, 0.0, 0.0, 0.15)
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 2.0), Vector2(rect.size.x, 2.0)), base_col, true)

func set_ratio(r: float) -> void:
	_ratio = clampf(r, 0.0, 1.0)
	queue_redraw()
