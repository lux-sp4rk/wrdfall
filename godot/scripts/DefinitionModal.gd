extends Control

signal dismissed

@onready var background: ColorRect = %Background
@onready var word_label: Label = %WordLabel
@onready var pos_label: Label = %POSLabel
@onready var definition_label: Label = %DefinitionLabel
@onready var close_button: Button = %CloseButton
@onready var loading_label: Label = %LoadingLabel

var _tween: Tween = null

func _ready() -> void:
    background.gui_input.connect(_on_background_input)
    close_button.pressed.connect(_dismiss)
    modulate.a = 0.0
    visible = false

func show_definition(word: String, definition: String, part_of_speech: String) -> void:
    visible = true
    word_label.text = word
    pos_label.text = part_of_speech
    definition_label.text = definition
    loading_label.visible = false
    word_label.visible = true
    pos_label.visible = true
    definition_label.visible = true

    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, "modulate:a", 1.0, 0.2)

func show_loading(word: String) -> void:
    visible = true
    word_label.visible = false
    pos_label.visible = false
    definition_label.visible = false
    loading_label.visible = true
    loading_label.text = "Looking up " + word + "..."

    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, "modulate:a", 1.0, 0.2)

func show_error(word: String, error: String) -> void:
    visible = true
    word_label.text = word
    pos_label.visible = false
    definition_label.text = "Definition unavailable"
    loading_label.visible = false
    word_label.visible = true
    definition_label.visible = true

    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _dismiss() -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, "modulate:a", 0.0, 0.2)
    await _tween.finished
    visible = false
    modulate.a = 0.0
    dismissed.emit()

func _on_background_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if not background.get_global_rect().has_point(background.get_global_mouse_position()):
            _dismiss()