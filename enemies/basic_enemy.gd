class_name WellBasicEnemy
extends CharacterBody2D

@export var max_health := 2
@export var move_speed := 70.0
@export var gravity := 1400.0
@export var patrol_left := -160.0
@export var patrol_right := 160.0
@export var contact_damage := 1
@export var knockback_resistance := 0.82

var health := max_health
var move_direction := -1.0
var hurt_timer := 0.0
var dead := false
var origin_x := 0.0

@onready var body_visual: Polygon2D = $Body
@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
	origin_x = global_position.x
	damage_area.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
	if dead:
		return

	if hurt_timer > 0.0:
		hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
	else:
		velocity.x = move_direction * move_speed

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = min(velocity.y, 40.0)

	if global_position.x < origin_x + patrol_left:
		move_direction = 1.0
	if global_position.x > origin_x + patrol_right:
		move_direction = -1.0
	if is_on_wall():
		move_direction *= -1.0

	move_and_slide()

	body_visual.scale.x = move_direction
	body_visual.modulate = Color(1.0, 0.45, 0.38) if hurt_timer <= 0.0 else Color(1.0, 0.95, 0.95)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body.has_method("take_damage"):
		body.take_damage(contact_damage, -move_direction * 360.0)

func take_damage(amount: int, knockback: float) -> void:
	if dead:
		return

	health -= amount
	hurt_timer = 0.18
	velocity.x = knockback * (1.0 - knockback_resistance)
	velocity.y = -210.0

	if health <= 0:
		_die()

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	damage_area.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body_visual, "scale", Vector2(1.25, 0.25), 0.12)
	tween.tween_property(body_visual, "modulate:a", 0.0, 0.18)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
