extends Node

## Persistent game state shared between levels and the hub.
## This is intentionally small: narrative flags can grow here without coupling them to level scenes.

var current_hp: int = 3
var max_hp: int = 3
var last_checkpoint: Vector2 = Vector2.ZERO
var current_level: String = "res://levels/level_01.tscn"
var returning_to_hub: bool = false
var flags: Dictionary = {}

func reset_run() -> void:
	current_hp = max_hp
	last_checkpoint = Vector2.ZERO
	current_level = "res://levels/level_01.tscn"
	returning_to_hub = false
	flags.clear()

func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value

func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))

func get_flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)
