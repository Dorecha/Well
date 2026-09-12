extends Node2D

@onready var player: WellPlayer = $Player
@onready var health_label: Label = $HUD/HealthLabel
@onready var status_label: Label = $HUD/StatusLabel

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.checkpoint_reached.connect(_on_checkpoint_reached)
	_on_health_changed(player.health, player.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP  " + "■ ".repeat(current) + "□ ".repeat(maximum - current)

func _on_checkpoint_reached(_position: Vector2) -> void:
	status_label.text = "CHECKPOINT АКТИВИРОВАН"
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(func() -> void: status_label.text = "A / D — движение   SPACE — прыжок   SHIFT — dash   Z — атака")
