extends Control
## Stats dashboard displaying player progress and records

@onready var back_button: Button = %BackButton
@onready var reset_button: Button = %ResetButton
@onready var share_button: Button = %ShareButton
@onready var confirm_dialog: ConfirmationDialog = %ConfirmDialog
@onready var history_chart: Control = %HistoryChart
@onready var definition_button: Button = %DefinitionButton

# Records section
@onready var high_score_label: Label = %HighScoreValue
@onready var longest_word_label: Label = %LongestWordValue
@onready var max_wpm_label: Label = %MaxWPMValue

# Definition modal
var _definition_modal: Control = null

# Totals section
@onready var total_words_label: Label = %TotalWordsValue
@onready var total_tiles_label: Label = %TotalTilesValue
@onready var total_time_label: Label = %TotalTimeValue

# Averages section
@onready var avg_score_label: Label = %AvgScoreValue
@onready var avg_wpm_label: Label = %AvgWPMValue
@onready var games_played_label: Label = %GamesPlayedValue

@onready var leaderboard_list: VBoxContainer = %LeaderboardList
@onready var leaderboard_loading: Label = %LeaderboardLoading

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	share_button.pressed.connect(_on_share_pressed)
	confirm_dialog.confirmed.connect(_on_reset_confirmed)
	definition_button.pressed.connect(_show_definition)
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)
	_update_display()
	_update_definition_button_visibility()
	_load_leaderboard()

func _load_leaderboard() -> void:
	if not has_node("%LeaderboardList"): return
	
	leaderboard_loading.show()
	leaderboard_loading.text = "Loading Leaderboard..."
	
	for child in leaderboard_list.get_children():
		child.queue_free()
		
	var query = SupabaseQuery.new().from("leaderboards").select(PackedStringArray(["score", "profiles(display_name)"])).order("score", false).range(0, 19)
	var task = Supabase.database.query(query)
	task.completed.connect(func(result):
		leaderboard_loading.hide()
		if result is Array:
			if result.is_empty():
				leaderboard_loading.show()
				leaderboard_loading.text = "No entries yet"
			else:
				for entry in result:
					_add_leaderboard_entry(entry)
		else:
			leaderboard_loading.show()
			leaderboard_loading.text = "Failed to load leaderboard"
	)

func _add_leaderboard_entry(entry: Dictionary) -> void:
	var hbox = HBoxContainer.new()
	var name_label = Label.new()
	var score_label = Label.new()

	var profile = entry.get("profiles", {})
	name_label.text = profile.get("display_name", "Anonymous")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	score_label.text = str(entry.get("score", 0))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	hbox.add_child(name_label)
	hbox.add_child(score_label)
	leaderboard_list.add_child(hbox)

func _update_display() -> void:
	"""Refresh all stat displays with current data"""
	# Records
	high_score_label.text = str(StatsManager.high_score)
	longest_word_label.text = StatsManager.longest_word if StatsManager.longest_word else "—"
	max_wpm_label.text = "%.1f" % StatsManager.max_wpm

	# Totals
	total_words_label.text = str(StatsManager.total_words_found)
	total_tiles_label.text = str(StatsManager.total_tiles_cleared)
	total_time_label.text = _format_time(StatsManager.total_time_played)

	# Averages
	var games_played: int = StatsManager.session_history.size()
	games_played_label.text = str(games_played)
	avg_score_label.text = "%.0f" % StatsManager.get_average_score()
	avg_wpm_label.text = "%.1f" % StatsManager.get_average_wpm()

	# Redraw history chart
	_draw_history_chart()

func _draw_history_chart() -> void:
	"""Draw a simple bar chart of recent session scores"""
	history_chart.queue_redraw()

	# Connect draw signal if not already connected
	if not history_chart.draw.is_connected(_on_chart_draw):
		history_chart.draw.connect(_on_chart_draw)

func _update_definition_button_visibility() -> void:
	"""Show definition button only when there's a valid word to look up"""
	definition_button.visible = (
		FeatureFlags.word_definitions_enabled and
		not StatsManager.longest_word.is_empty()
	)

func _on_chart_draw() -> void:
	"""Custom drawing for session history chart"""
	var history: Array = StatsManager.session_history
	if history.is_empty():
		# Draw "No data" message
		history_chart.draw_string(
			ThemeDB.fallback_font,
			Vector2(history_chart.size.x / 2 - 60, history_chart.size.y / 2),
			"No games played yet",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			ThemeManager.get_color("text_secondary")
		)
		return

	# Get last 10 sessions
	var recent: Array = history.slice(-10) if history.size() > 10 else history
	var count: int = recent.size()

	# Find max score for scaling
	var max_score: float = 1.0
	for session in recent:
		var session_score: float = session.get("score", 0)
		if session_score > max_score:
			max_score = session_score

	# Chart dimensions
	var chart_width: float = history_chart.size.x
	var chart_height: float = history_chart.size.y - 30  # Leave space for labels
	var bar_width: float = (chart_width / count) * 0.7
	var spacing: float = (chart_width / count) * 0.3

	# Draw bars
	for i in range(count):
		var session: Dictionary = recent[i]
		var session_score: float = session.get("score", 0)
		var bar_height: float = (session_score / max_score) * chart_height
		var x: float = i * (bar_width + spacing) + spacing / 2
		var y: float = chart_height - bar_height

		# Bar color (gradient based on position - newer = brighter)
		# Use theme-aware accent color
		var base_color: Color = ThemeManager.get_color("accent")
		var alpha: float = 0.4 + (float(i) / count) * 0.6
		var bar_color: Color = Color(base_color.r, base_color.g, base_color.b, alpha)

		# Draw bar
		history_chart.draw_rect(
			Rect2(x, y, bar_width, bar_height),
			bar_color,
			true
		)

		# Draw score label on top of bar
		if bar_height > 20:  # Only if bar is tall enough
			history_chart.draw_string(
				ThemeDB.fallback_font,
				Vector2(x + bar_width / 2 - 10, y - 5),
				str(int(session_score)),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				ThemeManager.get_color("text_primary")
			)

func _format_time(seconds: float) -> String:
	"""Convert seconds to human-readable format (e.g. '2h 15m')"""
	var hours: int = int(seconds / 3600)
	var minutes: int = int((seconds - hours * 3600) / 60)

	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	elif minutes > 0:
		return "%dm" % minutes
	else:
		return "<1m"

func _on_back_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.wordfallGoHome && window.wordfallGoHome()")
	else:
		get_tree().change_scene_to_file("res://scenes/Home.tscn")

func _on_reset_pressed() -> void:
	"""Show confirmation dialog before resetting stats"""
	confirm_dialog.dialog_text = "Are you sure you want to reset all stats? This cannot be undone."
	confirm_dialog.popup_centered()

func _on_reset_confirmed() -> void:
	"""Reset all stats after confirmation"""
	# Clear all stats
	StatsManager.total_tiles_cleared = 0
	StatsManager.total_words_found = 0
	StatsManager.total_time_played = 0.0
	StatsManager.high_score = 0
	StatsManager.longest_word = ""
	StatsManager.max_wpm = 0.0
	StatsManager.session_history.clear()
	StatsManager.save_stats()

	# Refresh display
	_update_display()

func _on_share_pressed() -> void:
	"""Copy stats summary to clipboard"""
	var stats_text: String = "Word Loom Stats\n"
	stats_text += "━━━━━━━━━━━━━━━\n"
	stats_text += "High Score: %d\n" % StatsManager.high_score
	stats_text += "Longest Word: %s\n" % (StatsManager.longest_word if StatsManager.longest_word else "—")
	stats_text += "Max WPM: %.1f\n" % StatsManager.max_wpm
	stats_text += "\n"
	stats_text += "Total Words: %d\n" % StatsManager.total_words_found
	stats_text += "Total Tiles: %d\n" % StatsManager.total_tiles_cleared
	stats_text += "Time Played: %s\n" % _format_time(StatsManager.total_time_played)
	stats_text += "\n"
	stats_text += "Games Played: %d\n" % StatsManager.session_history.size()
	stats_text += "Avg Score: %.0f\n" % StatsManager.get_average_score()
	stats_text += "Avg WPM: %.1f" % StatsManager.get_average_wpm()

	DisplayServer.clipboard_set(stats_text)

	# Show feedback (temporarily change button text)
	var original_text: String = share_button.text
	share_button.text = "Copied!"
	share_button.disabled = true
	await get_tree().create_timer(1.5).timeout
	share_button.text = original_text
	share_button.disabled = false

func _apply_theme() -> void:
	"""Apply current theme colors to all UI elements"""
	# Update background
	var bg = $ColorRect
	if bg:
		bg.color = ThemeManager.get_color("background")

	# Update title
	var title = $MarginContainer/VBox/Title
	if title:
		title.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update section titles
	var section_titles = [
		$MarginContainer/VBox/ScrollContainer/ContentVBox/RecordsSection/SectionTitle,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/TotalsSection/SectionTitle,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/HistorySection/SectionTitle,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/AveragesSection/SectionTitle
	]
	for section_title in section_titles:
		if section_title:
			section_title.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update all stat labels (both label and value in each row)
	var stat_rows = [
		$MarginContainer/VBox/ScrollContainer/ContentVBox/RecordsSection/HighScoreRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/RecordsSection/LongestWordRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/RecordsSection/MaxWPMRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/TotalsSection/TotalWordsRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/TotalsSection/TotalTilesRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/TotalsSection/TotalTimeRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/AveragesSection/GamesPlayedRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/AveragesSection/AvgScoreRow,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/AveragesSection/AvgWPMRow
	]
	for row in stat_rows:
		if row:
			for child in row.get_children():
				if child is Label:
					child.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	# Update separators
	var separators = [
		$MarginContainer/VBox/ScrollContainer/ContentVBox/Separator1,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/Separator2,
		$MarginContainer/VBox/ScrollContainer/ContentVBox/Separator3
	]
	for separator in separators:
		if separator:
			separator.add_theme_constant_override("separation", 1)
			# Note: HSeparator color is handled via theme

	# Update dynamically created leaderboard labels
	if leaderboard_list:
		for hbox in leaderboard_list.get_children():
			for label in hbox.get_children():
				if label is Label:
					label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))

	if leaderboard_loading:
		leaderboard_loading.add_theme_color_override("font_color", ThemeManager.get_color("text_secondary"))

	# Redraw chart with new theme colors
	if history_chart:
		history_chart.queue_redraw()

func _show_definition() -> void:
	"""Show definition modal for the longest word"""
	var word: String = StatsManager.longest_word
	if word.is_empty():
		return

	if not _definition_modal:
		_definition_modal = preload("res://scenes/DefinitionModal.tscn").instantiate()
		add_child(_definition_modal)
		_definition_modal.dismissed.connect(_on_definition_modal_dismissed)
		DefinitionService.definition_ready.connect(_on_definition_ready)
		DefinitionService.definition_error.connect(_on_definition_error)

	_definition_modal.show_loading(word)
	DefinitionService.lookup_definition(word)

func _on_definition_ready(word: String, definition: String, part_of_speech: String) -> void:
	if _definition_modal and _definition_modal.visible:
		_definition_modal.show_definition(word, definition, part_of_speech)

func _on_definition_error(word: String, error: String) -> void:
	if _definition_modal and _definition_modal.visible:
		_definition_modal.show_error(word, error)

func _on_definition_modal_dismissed() -> void:
	pass  # Future: resume game if needed
