extends Area2D

@export_file("*.tscn") var destination := "res://hub/hub.tscn"
@export var destination_spawn_id := ""
@export var prompt := "E — войти"

var _player_inside := false
@onready var prompt_label: Label = $Prompt

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.text = prompt
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if _player_inside and Input.is_action_just_pressed("interact") and not DialogueManager.is_active():
		if destination == "res://hub/hub.tscn":
			SceneFlow.go_to_hub(destination_spawn_id if destination_spawn_id != "" else "FromGarden")
		else:
			SceneFlow.go_to_level(destination, destination_spawn_id if destination_spawn_id != "" else "FromHub")

func _on_body_entered(body: Node) -> void:
	if body is WellPlayer:
		_player_inside = true
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body is WellPlayer:
		_player_inside = false
		prompt_label.visible = false
