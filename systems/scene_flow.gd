extends Node

## Global scene transition service.
## Keeps the transition overlay alive while gameplay scenes are replaced.

var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.04, 0.06, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_fade)

func change_scene(path: String, duration := 0.22, spawn_id := "") -> void:
	if _busy:
		return
	if not ResourceLoader.exists(path):
		push_error("SceneFlow: scene does not exist: " + path)
		return

	_busy = true
	if spawn_id != "":
		GameState.prepare_spawn(spawn_id)

	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out_tween := create_tween()
	out_tween.tween_property(_fade, "color:a", 1.0, duration)
	await out_tween.finished

	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneFlow: failed to change scene to %s (error %s)" % [path, error])
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_busy = false
		return

	await get_tree().scene_changed
	await get_tree().process_frame

	var in_tween := create_tween()
	in_tween.tween_property(_fade, "color:a", 0.0, duration)
	await in_tween.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func go_to_hub(spawn_id := "FromGarden") -> void:
	GameState.last_scene = get_tree().current_scene.scene_file_path
	GameState.prepare_spawn(spawn_id)
	change_scene("res://hub/hub.tscn")

func go_to_level(path: String, spawn_id := "FromHub") -> void:
	GameState.current_level = path
	GameState.last_scene = get_tree().current_scene.scene_file_path
	change_scene(path, 0.22, spawn_id)
