extends Area2D

@export_file("*.tscn") var destination := "res://hub/hub.tscn"
@export var prompt := "E — войти"
var _player_inside := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _player_inside and Input.is_action_just_pressed("interact") and not DialogueManager.is_active():
		SceneFlow.change_scene(destination)

func _on_body_entered(body: Node) -> void:
	if body is WellPlayer:
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is WellPlayer:
		_player_inside = false
