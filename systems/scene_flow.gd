extends Node

## Small scene-flow service: fade transitions without loading/menu screens.

var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.04, 0.06, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_fade)

func change_scene(path: String, duration := 0.22) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out_tween := create_tween()
	out_tween.tween_property(_fade, "color:a", 1.0, duration)
	await out_tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var in_tween := create_tween()
	in_tween.tween_property(_fade, "color:a", 0.0, duration)
	await in_tween.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func go_to_hub() -> void:
	GameState.returning_to_hub = true
	change_scene("res://hub/hub.tscn")

func go_to_level(path: String) -> void:
	GameState.current_level = path
	GameState.returning_to_hub = false
	change_scene(path)
