extends Control
class_name TutorialUI

## Tutorial UI
## Overlay UI for the tutorial system
## Displays phase title, instructions, progress indicator, and skip button

# Constants
const PROGRESS_DOT_SIZE: float = 12.0
const PROGRESS_DOT_SPACING: float = 8.0

# Node references
var tutorial_controller: TutorialController = null

# UI Elements (initialized in _ready or dynamically created)
var title_label: Label = null
var instruction_label: Label = null
var progress_container: HBoxContainer = null
var skip_button: Button = null
var progress_dots: Array = []

# Theme colors
var dot_active_color: Color = Color(0.88, 0.47, 0.34, 1.0)  # Terracotta
var dot_inactive_color: Color = Color(0.6, 0.6, 0.6, 0.4)

func _ready() -> void:
	# Set up UI layer
	layout_mode = 3
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	
	# Create UI elements
	_create_title_label()
	_create_instruction_label()
	_create_progress_indicator()
	_create_skip_button()
	
	# Apply theme
	_apply_theme()
	ThemeManager.theme_changed.connect(_apply_theme)

func setup(controller: TutorialController) -> void:
	"""Set up the UI with the tutorial controller."""
	tutorial_controller = controller
	
	# Connect to controller signals
	tutorial_controller.phase_changed.connect(_on_phase_changed)
	tutorial_controller.tutorial_completed.connect(_on_tutorial_completed)
	
	# Initialize with current phase
	_update_ui_for_phase(tutorial_controller.current_phase, tutorial_controller.get_current_phase_config())

# === UI Creation ===

func _create_title_label() -> void:
	"""Create the phase title label (top center)."""
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
	
	# Position at top center
	title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_label.position = Vector2(0, 80)
	title_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	add_child(title_label)

func _create_instruction_label() -> void:
	"""Create the instruction text label (bottom center)."""
	instruction_label = Label.new()
	instruction_label.name = "InstructionLabel"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 28)
	instruction_label.add_theme_color_override("font_color", ThemeManager.get_color("text_secondary"))
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Position at bottom center
	instruction_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	instruction_label.position = Vector2(0, -160)
	instruction_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	instruction_label.custom_minimum_size = Vector2(600, 0)
	
	add_child(instruction_label)

func _create_progress_indicator() -> void:
	"""Create the progress dots indicator."""
	progress_container = HBoxContainer.new()
	progress_container.name = "ProgressContainer"
	progress_container.theme_override_constants/separation = PROGRESS_DOT_SPACING
	progress_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Position below title
	progress_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progress_container.position = Vector2(0, 130)
	progress_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	add_child(progress_container)
	
	# Create dots (will be populated when controller is set)
	_populate_progress_dots()

func _populate_progress_dots() -> void:
	"""Create progress dots for all phases."""
	# Clear existing dots
	for dot in progress_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	progress_dots.clear()
	
	var total_phases: int = TutorialController.TutorialPhase.size()
	
	for i in range(total_phases):
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(PROGRESS_DOT_SIZE, PROGRESS_DOT_SIZE)
		
		# Style the dot
		var stylebox := StyleBoxFlat.new()
		stylebox.set_corner_radius_all(int(PROGRESS_DOT_SIZE / 2))
		stylebox.bg_color = dot_inactive_color
		dot.add_theme_stylebox_override("panel", stylebox)
		
		progress_container.add_child(dot)
		progress_dots.append(dot)
	
	_update_progress_dots(0)

func _create_skip_button() -> void:
	"""Create the skip button (top right)."""
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = _get_skip_button_text()
	skip_button.add_theme_font_size_override("font_size", 20)
	skip_button.custom_minimum_size = Vector2(80, 44)
	
	# Style the button
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.6, 0.6, 0.6, 0.3)
	normal_style.set_corner_radius_all(8)
	skip_button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.8, 0.4, 0.3, 0.5)
	hover_style.set_corner_radius_all(8)
	skip_button.add_theme_stylebox_override("hover", hover_style)
	
	# Position at top right
	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_button.position = Vector2(-20, 20)
	
	skip_button.pressed.connect(_on_skip_pressed)
	
	add_child(skip_button)

# === Event Handlers ===

func _on_phase_changed(new_phase: TutorialController.TutorialPhase, phase_data: TutorialController.PhaseConfig) -> void:
	"""Handle phase change."""
	_update_ui_for_phase(new_phase, phase_data)

func _on_tutorial_completed(skipped: bool) -> void:
	"""Handle tutorial completion."""
	if skipped:
		# Fade out and return to home
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished

func _on_skip_pressed() -> void:
	"""Handle skip button press."""
	if tutorial_controller:
		tutorial_controller.skip_tutorial()

# === UI Updates ===

func _update_ui_for_phase(phase: TutorialController.TutorialPhase, phase_data: TutorialController.PhaseConfig) -> void:
	"""Update all UI elements for the current phase."""
	# Update title with animation
	_update_title(phase_data.title)
	
	# Update instruction with animation
	_update_instruction(phase_data.instruction)
	
	# Update progress dots
	_update_progress_dots(int(phase))
	
	# Update skip button text
	if skip_button:
		skip_button.text = _get_skip_button_text()

func _update_title(new_text: String) -> void:
	"""Update the title label with a fade transition."""
	if not title_label:
		return
	
	# Fade out, change text, fade in
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		title_label.text = new_text
	)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.15)

func _update_instruction(new_text: String) -> void:
	"""Update the instruction label with a fade transition."""
	if not instruction_label:
		return
	
	# Fade out, change text, fade in
	var tween := create_tween()
	tween.tween_property(instruction_label, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		instruction_label.text = new_text
	)
	tween.tween_property(instruction_label, "modulate:a", 1.0, 0.15)

func _update_progress_dots(current_phase_index: int) -> void:
	"""Update the progress dots to show current phase."""
	for i in range(progress_dots.size()):
		var dot: Panel = progress_dots[i]
		var stylebox: StyleBoxFlat = dot.get_theme_stylebox("panel").duplicate()
		
		if i == current_phase_index:
			# Current phase - active color
			stylebox.bg_color = dot_active_color
			dot.custom_minimum_size = Vector2(PROGRESS_DOT_SIZE * 1.3, PROGRESS_DOT_SIZE * 1.3)
		elif i < current_phase_index:
			# Completed phase - muted active color
			stylebox.bg_color = Color(dot_active_color.r, dot_active_color.g, dot_active_color.b, 0.5)
			dot.custom_minimum_size = Vector2(PROGRESS_DOT_SIZE, PROGRESS_DOT_SIZE)
		else:
			# Future phase - inactive color
			stylebox.bg_color = dot_inactive_color
			dot.custom_minimum_size = Vector2(PROGRESS_DOT_SIZE, PROGRESS_DOT_SIZE)
		
		dot.add_theme_stylebox_override("panel", stylebox)

func _apply_theme() -> void:
	"""Apply current theme to UI elements."""
	if title_label:
		title_label.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
	
	if instruction_label:
		instruction_label.add_theme_color_override("font_color", ThemeManager.get_color("text_secondary"))
	
	if skip_button:
		skip_button.add_theme_color_override("font_color", ThemeManager.get_color("text_primary"))
	
	# Update dot colors
	dot_active_color = ThemeManager.get_color("accent")
	_update_progress_dots(tutorial_controller.current_phase if tutorial_controller else 0)

# === Localization ===

func _get_skip_button_text() -> String:
	"""Get localized skip button text."""
	var lang_config: LanguageConfig = LanguageConfig.get_config(GameSettings.current_language)
	var tutorial_strings: Dictionary = lang_config.ui_strings.get("tutorial", {})
	return tutorial_strings.get("skip_button", "Skip")

func get_localized_phase_title(phase: TutorialController.TutorialPhase) -> String:
	"""Get localized title for a phase."""
	var phase_id: String = tutorial_controller.get_phase_name(phase).to_lower()
	return TutorialData.get_phase_title(phase_id, GameSettings.current_language)

func get_localized_phase_instruction(phase: TutorialController.TutorialPhase) -> String:
	"""Get localized instruction for a phase."""
	var phase_id: String = tutorial_controller.get_phase_name(phase).to_lower()
	return TutorialData.get_phase_instruction(phase_id, GameSettings.current_language)

# === Public Methods ===

func show_completion_message() -> void:
	"""Show the tutorial completion message."""
	_update_title("Tutorial Complete!")
	_update_instruction("Get ready to play...")

func hide_ui() -> void:
	"""Hide the tutorial UI."""
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)

func show_ui() -> void:
	"""Show the tutorial UI."""
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
