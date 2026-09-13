extends Node

## Temporary upgraded dialogue implementation. This file will be promoted after review.

signal dialogue_started
signal dialogue_finished
signal choice_selected(index: int)

var _queue: Array[Dictionary] = []
var _index := 0
var _active := false
var _waiting_for_choice := false
var _speaker_label: Label
var _text_label: Label
var _hint_label: Label
var _panel: PanelContainer
var _choices_box: VBoxContainer
var _layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 90
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(54, -198)
	_panel.size = Vector2(1044, 170)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_layer.add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.add_theme_color_override("font_color", Color(0.92, 0.68, 0.38))
	box.add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 20)
	_text_label.custom_minimum_size = Vector2(0, 54)
	box.add_child(_text_label)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 5)
	box.add_child(_choices_box)
	_hint_label = Label.new()
	_hint_label.text = "SPACE / E — продолжить"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.modulate = Color(0.7, 0.7, 0.72, 0.8)
	box.add_child(_hint_label)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.065, 0.97)
	style.border_color = Color(0.55, 0.42, 0.28, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style

func start_dialogue(lines: Array[Dictionary]) -> void:
	if lines.is_empty() or _active:
		return
	_queue = lines.duplicate(true)
	_index = 0
	_active = true
	_waiting_for_choice = false
	_panel.visible = true
	get_tree().paused = true
	dialogue_started.emit()
	_show_current()

func say(speaker: String, text: String) -> void:
	start_dialogue([{"speaker": speaker, "text": text}])

func _show_current() -> void:
	_clear_choices()
	_waiting_for_choice = false
	if _index < 0 or _index >= _queue.size():
		_finish()
		return
	var entry := _queue[_index]
	_speaker_label.text = str(entry.get("speaker", ""))
	_text_label.text = str(entry.get("text", ""))
	var choices: Array = entry.get("choices", [])
	if not choices.is_empty():
		_waiting_for_choice = true
		_hint_label.text = "Выбери вариант"
		for i in choices.size():
			var choice: Dictionary = choices[i]
			var button := Button.new()
			button.text = str(choice.get("text", "Вариант %d" % (i + 1)))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size.y = 30
			button.pressed.connect(_choose.bind(i, choice))
			_choices_box.add_child(button)
	else:
		_hint_label.text = "SPACE / E — продолжить"

func _choose(index: int, choice: Dictionary) -> void:
	if not _active or not _waiting_for_choice:
		return
	var flag := str(choice.get("flag", ""))
	if flag != "":
		GameState.set_flag(flag, choice.get("flag_value", true))
	choice_selected.emit(index)
	_waiting_for_choice = false
	_index = int(choice.get("next", _index + 1))
	_show_current()

func _unhandled_input(event: InputEvent) -> void:
	if not _active or _waiting_for_choice:
		return
	if event.is_action_pressed("dialogue_advance") or event.is_action_pressed("interact"):
		_index += 1
		_show_current()
		get_viewport().set_input_as_handled()

func _clear_choices() -> void:
	if _choices_box == null:
		return
	for child in _choices_box.get_children():
		child.queue_free()

func _finish() -> void:
	_active = false
	_waiting_for_choice = false
	_queue.clear()
	_clear_choices()
	_panel.visible = false
	get_tree().paused = false
	dialogue_finished.emit()

func is_active() -> bool:
	return _active
