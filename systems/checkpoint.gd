class_name WellCheckpoint
extends Area2D

var activated := false

@onready var flag: Polygon2D = $Flag
@onready var glow: Polygon2D = $Glow

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if not body.has_method("set_checkpoint"):
		return

	activated = true
	body.set_checkpoint(global_position + Vector2(0, -42))
	flag.color = Color(0.35, 1.0, 0.55, 1.0)
	glow.color = Color(0.35, 1.0, 0.55, 0.20)
