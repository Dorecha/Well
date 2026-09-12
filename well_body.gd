extends CharacterBody2D

# =========================
# ДВИЖЕНИЕ
# =========================

const SPEED := 300.0
const ACCELERATION := 2000.0
const FRICTION := 2500.0


# =========================
# ПРЫЖОК
# =========================

const JUMP_VELOCITY := -500.0
const JUMP_CUT_MULTIPLIER := 0.45


# =========================
# DASH
# =========================

const DASH_SPEED := 900.0
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 0.25


# =========================
# АТАКА
# =========================

const ATTACK_DURATION := 0.18


# =========================
# ПЕРЕМЕННЫЕ
# =========================

var is_dashing := false
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector2.RIGHT
var can_dash := true

var is_attacking := false
var attack_timer := 0.0

# 1 = вправо
# -1 = влево
var facing_direction := 1.0


func _physics_process(delta: float) -> void:

	# =========================
	# DASH COOLDOWN
	# =========================

	if dash_cooldown > 0:
		dash_cooldown -= delta


	# =========================
	# ВОССТАНОВЛЕНИЕ DASH
	# =========================

	if is_on_floor() and not is_dashing:
		can_dash = true


	# =========================
	# НАПРАВЛЕНИЕ
	# =========================

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		facing_direction = direction


	# =========================
	# ПОЗИЦИЯ HITBOX
	# =========================

	if facing_direction > 0:
		$AttackHitbox.position.x = 40
	else:
		$AttackHitbox.position.x = -40


	# =========================
	# АТАКА
	# =========================

	if Input.is_action_just_pressed("attack") and not is_dashing and not is_attacking:

		is_attacking = true
		attack_timer = ATTACK_DURATION

		$AttackHitbox.monitoring = true


	if is_attacking:

		attack_timer -= delta

		# Во время атаки останавливаем горизонтальное движение
		velocity.x = 0

		if attack_timer <= 0:

			is_attacking = false
			$AttackHitbox.monitoring = false


	# =========================
	# НАЧАЛО DASH
	# =========================

	if Input.is_action_just_pressed("dash") \
	and can_dash \
	and dash_cooldown <= 0 \
	and not is_attacking:

		is_dashing = true
		can_dash = false
		dash_timer = DASH_DURATION


		var input_direction := Input.get_vector(
			"ui_left",
			"ui_right",
			"ui_up",
			"ui_down"
		)


		if input_direction != Vector2.ZERO:

			dash_direction = input_direction.normalized()

		else:

			if velocity.x != 0:
				dash_direction = Vector2(sign(velocity.x), 0)
			else:
				dash_direction = Vector2.RIGHT


	# =========================
	# ВЫПОЛНЕНИЕ DASH
	# =========================

	if is_dashing:

		dash_timer -= delta

		velocity = dash_direction * DASH_SPEED


		if dash_timer <= 0:

			is_dashing = false
			dash_cooldown = DASH_COOLDOWN

			# После Dash возвращаем обычную скорость
			velocity = dash_direction * SPEED


	# =========================
	# ОБЫЧНОЕ ДВИЖЕНИЕ
	# =========================

	if not is_dashing and not is_attacking:

		# Гравитация
		if not is_on_floor():
			velocity += get_gravity() * delta


		# Прыжок
		if Input.is_action_just_pressed("jump") and is_on_floor():

			velocity.y = JUMP_VELOCITY


		# Прерывание прыжка
		if Input.is_action_just_released("jump") and velocity.y < 0:

			velocity.y *= JUMP_CUT_MULTIPLIER


		# Движение влево / вправо
		if direction != 0:

			velocity.x = move_toward(
				velocity.x,
				direction * SPEED,
				ACCELERATION * delta
			)

		else:

			velocity.x = move_toward(
				velocity.x,
				0,
				FRICTION * delta
			)


	move_and_slide()
