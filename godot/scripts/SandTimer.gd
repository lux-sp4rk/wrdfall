extends Control

## Visual sand timer (hourglass) that drains to show remaining drop time.
## Purely visual — no numbers. Designed as a peripheral cue near the action bar.

var drop_timer_ref: Timer = null
var _progress: float = 1.0  ## 1.0 = full, 0.0 = empty

func _ready() -> void:
	set_process(false)
	ThemeManager.theme_changed.connect(queue_redraw)

func set_drop_timer(timer: Timer) -> void:
	drop_timer_ref = timer
	set_process(true)
	queue_redraw()

func set_paused(paused: bool) -> void:
	set_process(not paused)
	if not paused:
		queue_redraw()

func _process(_delta: float) -> void:
	if drop_timer_ref and not drop_timer_ref.is_stopped():
		var total := drop_timer_ref.wait_time
		var left := drop_timer_ref.time_left
		_progress = clampf(left / total, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w / 2.0
	var top_y := 2.0
	var bottom_y := h - 2.0
	var neck_gap := 3.0
	var neck_y1 := h / 2.0 - neck_gap
	var neck_y2 := h / 2.0 + neck_gap
	var bulb_w := w * 0.42

	var outline_color := ThemeManager.get_color("text_secondary")
	var sand_color := ThemeManager.get_color("accent")
	var glass_color := ThemeManager.get_color("text_muted")
	glass_color.a = 0.15  # Very subtle glass tint

	# Draw glass background (subtle fill inside the hourglass)
	var glass_points := PackedVector2Array([
		Vector2(cx, top_y),
		Vector2(cx + bulb_w, neck_y1),
		Vector2(cx + bulb_w, neck_y2),
		Vector2(cx, bottom_y),
		Vector2(cx - bulb_w, neck_y2),
		Vector2(cx - bulb_w, neck_y1),
	])
	draw_colored_polygon(glass_points, glass_color)

	# Draw hourglass outline — six segments of the hexagon
	var outline := PackedVector2Array([
		Vector2(cx, top_y),
		Vector2(cx + bulb_w, neck_y1),
		Vector2(cx + bulb_w, neck_y2),
		Vector2(cx, bottom_y),
		Vector2(cx - bulb_w, neck_y2),
		Vector2(cx - bulb_w, neck_y1),
		Vector2(cx, top_y),
	])
	draw_polyline(outline, outline_color, 2.0, true)

	# Draw horizontal neck lines
	draw_line(Vector2(cx - bulb_w * 0.25, neck_y1), Vector2(cx + bulb_w * 0.25, neck_y1), outline_color, 1.5)
	draw_line(Vector2(cx - bulb_w * 0.25, neck_y2), Vector2(cx + bulb_w * 0.25, neck_y2), outline_color, 1.5)

	# Top bulb sand (drains as time passes — progress goes 1.0 → 0.0)
	if _progress > 0.0:
		var fill := _progress
		var sand_top_y := neck_y1 - (neck_y1 - top_y) * fill
		var sand_w := bulb_w * fill
		var top_sand := PackedVector2Array([
			Vector2(cx, neck_y1),
			Vector2(cx + sand_w, sand_top_y),
			Vector2(cx - sand_w, sand_top_y),
		])
		draw_colored_polygon(top_sand, sand_color)

	# Bottom bulb sand (fills as time passes)
	var bottom_fill := 1.0 - _progress
	if bottom_fill > 0.0:
		var sand_bottom_y := neck_y2 + (bottom_y - neck_y2) * bottom_fill
		var sand_w := bulb_w * bottom_fill
		var bottom_sand := PackedVector2Array([
			Vector2(cx, neck_y2),
			Vector2(cx + sand_w, sand_bottom_y),
			Vector2(cx - sand_w, sand_bottom_y),
		])
		draw_colored_polygon(bottom_sand, sand_color)
