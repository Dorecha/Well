extends Node2D

@onready var player: WellPlayer = $Player
@onready var npc_area: Area2D = $Guide/NPCArea
@onready var npc_prompt: Label = $Guide/Prompt

var _near_guide := false

func _ready() -> void:
	npc_area.body_entered.connect(_on_guide_entered)
	npc_area.body_exited.connect(_on_guide_exited)
	npc_prompt.visible = false
	$HUD/Info.text = "E — взаимодействие   |   A / D — движение   |   SPACE — прыжок   |   SHIFT — dash   |   Z — атака"
	_apply_spawn()
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1600
		camera.limit_bottom = 720

func _apply_spawn() -> void:
	var spawn_id := GameState.consume_spawn_id()
	if spawn_id == "":
		return
	var marker := get_node_or_null("SpawnPoints/" + spawn_id) as Marker2D
	if marker:
		player.global_position = marker.global_position

func _unhandled_input(event: InputEvent) -> void:
	if not _near_guide or DialogueManager.is_active():
		return
	if event.is_action_pressed("interact"):
		_open_guide_dialogue()
		get_viewport().set_input_as_handled()

func _open_guide_dialogue() -> void:
	if not GameState.has_flag("met_guide"):
		GameState.set_flag("met_guide")
		DialogueManager.start_dialogue([
			{"speaker": "Незнакомец", "text": "Ты наконец проснулся."},
			{"speaker": "Велл", "text": "Где я?.."},
			{"speaker": "Незнакомец", "text": "В Стране чудес. Только не той, о которой тебе рассказывали."},
			{"speaker": "Незнакомец", "text": "Ты доверяешь мне?", "choices": [
				{"text": "Да.", "next": 4, "flag": "trusted_guide"},
				{"text": "Нет.", "next": 5, "flag": "distrusted_guide"}
			]},
			{"speaker": "Незнакомец", "text": "Тогда иди осторожно. Здесь доверие стоит дороже золота.", "next": 6},
			{"speaker": "Незнакомец", "text": "Хорошо. Не доверяй никому слишком быстро.", "next": 6},
			{"speaker": "Незнакомец", "text": "Начни с сада. Дверь туда уже открыта. А если встретишь Чешира — не верь всему, что он говорит."},
			{"speaker": "Велл", "text": "Что-то подсказывает мне, что это плохой знак."}
		])
	else:
		DialogueManager.start_dialogue([
			{"speaker": "Незнакомец", "text": "Сад ждёт тебя."},
			{"speaker": "Велл", "text": "Что-то подсказывает мне, что это плохой знак."},
			{"speaker": "Незнакомец", "text": "Тогда доверься этому чувству."}
		])

func _on_guide_entered(body: Node) -> void:
	if body is WellPlayer:
		_near_guide = true
		npc_prompt.visible = true

func _on_guide_exited(body: Node) -> void:
	if body is WellPlayer:
		_near_guide = false
		npc_prompt.visible = false
