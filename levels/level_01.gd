extends Node2D

@onready var player: WellPlayer = $Player
@onready var health_label: Label = $HUD/HealthLabel
@onready var status_label: Label = $HUD/StatusLabel

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.checkpoint_reached.connect(_on_checkpoint_reached)
	_apply_spawn()
	_on_health_changed(player.health, player.max_health)

func _apply_spawn() -> void:
	var spawn_id := GameState.consume_spawn_id()
	if spawn_id == "":
		return
	var marker := get_node_or_null("SpawnPoints/" + spawn_id) as Marker2D
	if marker:
		var level_path := get_tree().current_scene.scene_file_path
		player.global_position = marker.global_position
		player.checkpoint_position = GameState.get_checkpoint(level_path, marker.global_position)

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP  " + "■ ".repeat(current) + "□ ".repeat(maximum - current)

func _on_checkpoint_reached(_position: Vector2) -> void:
	status_label.text = "CHECKPOINT АКТИВИРОВАН"
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(func() -> void: status_label.text = "A / D — движение   SPACE — прыжок   SHIFT — dash   Z — атака")
