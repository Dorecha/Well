extends Node

## Persistent game state shared by the hub, levels and dialogue system.
## Scene instances are disposable; important progression lives here.

var current_hp: int = 3
var max_hp: int = 3
var current_level: String = "res://levels/level_01.tscn"
var checkpoint_by_level: Dictionary = {}
var flags: Dictionary = {}
var pending_spawn_id: String = ""
var last_scene: String = ""

func reset_run() -> void:
	current_hp = max_hp
	current_level = "res://levels/level_01.tscn"
	checkpoint_by_level.clear()
	flags.clear()
	pending_spawn_id = ""
	last_scene = ""

func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value

func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))

func get_flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)

func set_checkpoint(level_path: String, position: Vector2) -> void:
	checkpoint_by_level[level_path] = position

func has_checkpoint(level_path: String) -> bool:
	return checkpoint_by_level.has(level_path)

func get_checkpoint(level_path: String, fallback: Vector2) -> Vector2:
	return checkpoint_by_level.get(level_path, fallback)

func prepare_spawn(spawn_id: String) -> void:
	pending_spawn_id = spawn_id

func consume_spawn_id() -> String:
	var result := pending_spawn_id
	pending_spawn_id = ""
	return result
