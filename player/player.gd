class_name WellPlayer
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal checkpoint_reached(position: Vector2)

@export var max_speed := 320.0
@export var ground_acceleration := 2200.0
@export var ground_friction := 2800.0
@export var air_acceleration := 1500.0
@export var air_friction := 700.0
@export var jump_velocity := -560.0
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.12
@export var variable_jump_multiplier := 0.45

@export var dash_speed := 950.0
@export var dash_duration := 0.14
@export var dash_cooldown := 0.20

@export var max_health := 3
@export var attack_duration := 0.16
@export var attack_cooldown := 0.12
@export var attack_knockback := 480.0
@export var hurt_invulnerability := 0.55

var health := max_health
var checkpoint_position := Vector2.ZERO
var facing_direction := 1.0

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_available := true
var dash_direction := Vector2.RIGHT

var is_attacking := false
var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var attack_hit_targets: Dictionary = {}

var hurt_invulnerability_timer := 0.0
var respawning := false

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_visual: Polygon2D = $AttackVisual
@onready var body_visual: Polygon2D = $Body

func _ready() -> void:
	var scene_root := get_parent()
	var level_path := scene_root.scene_file_path if scene_root != null else ""
	checkpoint_position = GameState.get_checkpoint(level_path, global_position)
	attack_hitbox.monitoring = false
	attack_visual.visible = false
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	GameState.max_hp = max_health
	health = max_health
	GameState.current_hp = health
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_respawn()
		return

	if respawning or DialogueManager.is_active():
		return

	if global_position.y > 900.0:
		_respawn()
		return

	_update_timers(delta)

	if is_dashing:
		_process_dash(delta)
		move_and_slide()
		_update_visuals()
		return

	if is_attacking:
		_process_attack(delta)
	else:
		_process_movement(delta)

	_process_dash_input()
	_process_attack_input()
	_apply_jump()

	move_and_slide()
	_update_visuals()

func _update_timers(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if hurt_invulnerability_timer > 0.0:
		hurt_invulnerability_timer -= delta
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	if coyote_timer > 0.0:
		coyote_timer -= delta

	if is_on_floor():
		coyote_timer = coyote_time
		dash_available = true

func _process_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		facing_direction = sign(direction)
		var acceleration := ground_acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		var friction := ground_friction if is_on_floor() else air_friction
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

func _apply_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not is_attacking:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		dash_available = true

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= variable_jump_multiplier

func _process_dash_input() -> void:
	if not Input.is_action_just_pressed("dash"):
		return
	if not dash_available or dash_cooldown_timer > 0.0 or is_attacking:
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction == Vector2.ZERO:
		dash_direction = Vector2(facing_direction, 0.0)
	else:
		dash_direction = input_direction.normalized()

	is_dashing = true
	dash_available = false
	dash_timer = dash_duration

func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_direction * dash_speed

	if dash_timer <= 0.0:
		is_dashing = false
		dash_cooldown_timer = dash_cooldown
		velocity = Vector2(dash_direction.x * max_speed, min(velocity.y, 140.0))

func _process_attack_input() -> void:
	if not Input.is_action_just_pressed("attack"):
		return
	if is_attacking or attack_cooldown_timer > 0.0 or is_dashing:
		return

	is_attacking = true
	attack_timer = attack_duration
	attack_cooldown_timer = attack_duration + attack_cooldown
	attack_hit_targets.clear()
	attack_hitbox.monitoring = true
	attack_visual.visible = true
	velocity.x *= 0.20

func _process_attack(delta: float) -> void:
	attack_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 2400.0 * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if attack_timer <= 0.0:
		is_attacking = false
		attack_hitbox.monitoring = false
		attack_visual.visible = false

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if not is_attacking:
		return

	var target := area.get_parent()
	if target == null or attack_hit_targets.has(target):
		return

	if target.has_method("take_damage"):
		attack_hit_targets[target] = true
		target.take_damage(1, facing_direction * attack_knockback)

func take_damage(amount: int, source_x: float) -> void:
	if respawning or hurt_invulnerability_timer > 0.0:
		return

	health = max(health - amount, 0)
	GameState.current_hp = health
	hurt_invulnerability_timer = hurt_invulnerability
	velocity.x = source_x
	velocity.y = -280.0
	health_changed.emit(health, max_health)

	if health <= 0:
		_respawn()

func set_checkpoint(new_position: Vector2) -> void:
	checkpoint_position = new_position
	var scene_root := get_parent()
	var level_path := scene_root.scene_file_path if scene_root != null else ""
	GameState.set_checkpoint(level_path, new_position)
	GameState.current_hp = max_health
	checkpoint_reached.emit(new_position)

func _respawn() -> void:
	if respawning:
		return

	respawning = true
	is_dashing = false
	is_attacking = false
	attack_hitbox.monitoring = false
	attack_visual.visible = false
	velocity = Vector2.ZERO
	global_position = checkpoint_position
	health = max_health
	GameState.current_hp = health
	health_changed.emit(health, max_health)
	hurt_invulnerability_timer = 0.8
	body_visual.modulate = Color(1, 1, 1, 0.55)

	await get_tree().create_timer(0.20).timeout
	respawning = false

func _update_visuals() -> void:
	attack_hitbox.position.x = 38.0 * facing_direction
	attack_visual.position.x = 35.0 * facing_direction
	body_visual.scale.x = facing_direction

	if hurt_invulnerability_timer > 0.0:
		body_visual.modulate.a = 0.55 if int(hurt_invulnerability_timer * 18.0) % 2 == 0 else 1.0
	else:
		body_visual.modulate = Color.WHITE
