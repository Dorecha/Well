extends Node2D

@onready var player: WellPlayer = $Player
@onready var npc_area: Area2D = $Guide/NPCArea
@onready var npc_prompt: Label = $Guide/Prompt

var _near_guide := false

func _ready() -> void:
	npc_area.body_entered.connect(_on_guide_entered)
	npc_area.body_exited.connect(_on_guide_exited)
	npc_prompt.visible = false
	$HUD/Info.text = "H — ХАБ   |   E — взаимодействие   |   A / D — движение   |   SPACE — прыжок   |   SHIFT — dash   |   Z — атака"

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
			{"speaker": "Велл", "text": "Мне нужно найти дорогу домой."},
			{"speaker": "Незнакомец", "text": "Конечно. Все здесь сначала хотят найти дорогу домой."},
			{"speaker": "Незнакомец", "text": "Начни с сада. Дверь туда уже открыта. А если встретишь Чешира — не верь всему, что он говорит."}
		])
	else:
		DialogueManager.start_dialogue([
			{"speaker": "Незнакомец", "text": "Сад ждёт тебя."},
			{"speaker": "Велл", "text": "Что-то подсказывает мне, что это плохой знак."}
		])

func _on_guide_entered(body: Node) -> void:
	if body is WellPlayer:
		_near_guide = true
		npc_prompt.visible = true

func _on_guide_exited(body: Node) -> void:
	if body is WellPlayer:
		_near_guide = false
		npc_prompt.visible = false
