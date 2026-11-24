class_name Player
extends CharacterBody2D
## Controlador principal del personaje.
## Mantiene las estadísticas en un recurso aparte (PlayerStats) para poder
## reutilizarlas con otros personajes. El juego no tiene combate del jugador.

signal jumped
signal dashed
signal landed
signal died

const ANIM_IDLE := &"idle"
const ANIM_WALK := &"walk"
const ANIM_RUN := &"run"
const ANIM_JUMP := &"jump"
const ANIM_FALL := &"fall"
const ANIM_DEATH := &"death"

@export var stats: PlayerStats
@export var inverted_gravity: bool = false
@export var inverted_controls: bool = false
## Viento (2026-11-17): velocidad horizontal que le suma un WindField (px/s, el signo
## es la dirección). En el suelo empuja menos; no se acumula en `velocity`.
const WIND_GROUND_FACTOR := 0.35
var wind_speed: float = 0.0
## Corriente ascendente (2026-11-23): un UpdraftZone escribe aquí la velocidad
## de ascenso (px/s, positiva = hacia arriba) y la aceleración mientras el
## jugador está dentro; 0 fuera. Se aplica al final de la física del frame
## para que también levante al jugador que está de pie en el suelo.
var updraft_speed: float = 0.0
var updraft_accel: float = 0.0

@onready var visual: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var visual_root: Node2D = $Visual
@onready var health: Health = $Health

var _facing: int = 1
var _is_running: bool = false
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _jump_hold_left: float = 0.0
var _jumps_used: int = 0
var _death_tween: Tween
var _squash_tween: Tween
var _dust: CPUParticles2D
var _fall_speed: float = 0.0
var _gravity_sign: float = 1.0
var _invulnerability_left: float = 0.0
var _is_dead: bool = false
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
## Intangibilidad (2026-11-19): durante el impulso y un instante después el
## jugador atraviesa a los enemigos (excepciones de colisión) y no recibe su daño.
const DASH_GRACE_TIME := 0.15
var _intangible_left: float = 0.0
var _intangible_active: bool = false
var _dash_direction: float = 1.0
var _afterimage_left: float = 0.0
## Lanzamiento (2026-11-21): mientras dura, el mando no frena ni cambia la
## velocidad horizontal (lo usa LaunchPad).
var _launch_lock_left: float = 0.0
## Verdadero durante el frame siguiente a un lanzamiento: evita que el suelo
## anule la velocidad vertical hacia arriba (is_on_floor() sigue activo ese frame).
var _launch_pending: bool = false

const AFTERIMAGE_INTERVAL := 0.035


func _ready() -> void:
	if stats == null:
		stats = PlayerStats.new()

	configure_gravity()
	configure_controls()

	health.died.connect(_on_health_died)
	visual.flip_h = _facing < 0
	_play_animation(ANIM_IDLE)
	landed.connect(_on_landed_fx)
	_dust = Fx.make_dust(self, Vector2(0.0, -22.0 if inverted_gravity else 22.0))

func configure_gravity() -> void:
	_gravity_sign = -1.0 if inverted_gravity else 1.0
	up_direction = Vector2.DOWN if inverted_gravity else Vector2.UP
	visual.scale.y = -1.0 if inverted_gravity else 1.0
	var shadow := get_node_or_null("Shadow") as Polygon2D
	if shadow != null:
		shadow.position.y = -24.0 if inverted_gravity else 24.0
	if _dust != null:
		_dust.position = Vector2(0.0, -22.0 if inverted_gravity else 22.0)

func configure_controls() -> void:
	## Nivel 8 (2026-11-16): invierte solo el eje horizontal, de modo que D y
	## flecha derecha mueven hacia la izquierda. El mando pasa por las mismas
	## acciones, así que también queda invertido.
	_facing = -1 if inverted_controls else 1
	visual.flip_h = inverted_controls


func _physics_process(delta: float) -> void:
	if _is_dead:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, stats.deceleration * delta)
		move_and_slide()
		return

	var was_on_floor := is_on_floor()

	_tick_timers(delta)
	_update_jump_windows(delta)
	_handle_dash_input()
	_update_intangibility(delta)
	if _dash_time_left > 0.0:
		_run_dash(delta)
	else:
		if _launch_lock_left <= 0.0:
			_handle_horizontal_movement(delta)
		_apply_gravity(delta)
		_handle_jump()

	if updraft_speed > 0.0:
		velocity.y = move_toward(velocity.y, -updraft_speed, updraft_accel * delta)

	# Velocidad de caída justo antes del impacto: alimenta el squash y el
	# polvo al aterrizar.
	_fall_speed = velocity.y
	var wind_push := wind_speed * (WIND_GROUND_FACTOR if is_on_floor() else 1.0)
	velocity.x += wind_push
	move_and_slide()
	if not is_on_wall():
		velocity.x -= wind_push

	# La señal permite añadir después partículas, sonido o sacudida de cámara.
	if not was_on_floor and is_on_floor():
		landed.emit()

	_update_animation()


func _tick_timers(delta: float) -> void:
	_launch_lock_left = maxf(0.0, _launch_lock_left - delta)
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)

	if _invulnerability_left > 0.0:
		_invulnerability_left = maxf(0.0, _invulnerability_left - delta)
		visual.modulate.a = 0.45 if fmod(_invulnerability_left * 14.0, 2.0) > 1.0 else 1.0
		if _invulnerability_left <= 0.0:
			visual.modulate = Color.WHITE


func _update_jump_windows(delta: float) -> void:
	if is_on_floor():
		_coyote_left = stats.coyote_time
		_jumps_used = 0
		_jump_hold_left = 0.0
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)

		# Si se cayó de una plataforma sin saltar, se consume el salto de suelo
		# al terminar el tiempo de coyote. Deja la puerta abierta al doble salto.
		if _coyote_left <= 0.0 and _jumps_used == 0:
			_jumps_used = 1

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = stats.jump_buffer_time
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	# Soltar el botón durante el ascenso recorta la altura del salto.
	if Input.is_action_just_released("jump"):
		_jump_hold_left = 0.0
		if velocity.y * _gravity_sign < 0.0:
			velocity.y *= stats.jump_cut_multiplier


var _fast_fall_planted: bool = false


func _handle_horizontal_movement(delta: float) -> void:
	# Tras una caída rápida, mantener el botón deja al jugador clavado donde cae
	# (2026-11-18): sin deslizarse ni caminar hasta soltar la tecla.
	if not Input.is_action_pressed("move_down"):
		_fast_fall_planted = false
	elif is_on_floor() and _fast_fall_planted:
		velocity.x = 0.0
		return
	var direction := Input.get_axis("move_left", "move_right")
	if inverted_controls:
		direction = -direction
	# Se corre siempre por defecto (2026-11-18); Ctrl es ahora el impulso.
	_is_running = not is_zero_approx(direction)

	if not is_zero_approx(direction):
		_facing = 1 if direction > 0.0 else -1
		visual.flip_h = _facing < 0

	var target_speed := 0.0
	if not is_zero_approx(direction):
		var speed := stats.run_speed if _is_running else stats.max_speed
		target_speed = direction * speed

	var current_acceleration := stats.acceleration
	if not is_on_floor():
		current_acceleration = stats.air_acceleration

	if is_zero_approx(direction):
		current_acceleration = stats.deceleration if is_on_floor() else stats.air_deceleration
	elif not is_zero_approx(velocity.x) and signf(velocity.x) != signf(direction):
		current_acceleration = stats.turn_acceleration

	velocity.x = move_toward(velocity.x, target_speed, current_acceleration * delta)


func _handle_dash_input() -> void:
	## Impulso rápido hacia delante (Ctrl), en el suelo y en el aire. Ya no
	## cuenta como doble salto (2026-11-18) y mientras dura el jugador atraviesa
	## enemigos y proyectiles sin recibir daño (ver `take_damage`).
	if not Input.is_action_just_pressed("dash") or _dash_cooldown_left > 0.0:
		return
	if _dash_time_left > 0.0:
		return
	_dash_direction = float(_facing)
	_dash_time_left = stats.dash_time
	_dash_cooldown_left = stats.dash_cooldown
	_jump_hold_left = 0.0
	_squash(Vector2(1.3, 0.8), 0.14)
	_dust.restart()
	Sfx.play("jump", -14.0)
	dashed.emit()


func _run_dash(delta: float) -> void:
	_dash_time_left = maxf(0.0, _dash_time_left - delta)
	_afterimage_left -= delta
	if _afterimage_left <= 0.0:
		_afterimage_left = AFTERIMAGE_INTERVAL
		_spawn_afterimage()
	velocity.x = _dash_direction * stats.dash_speed
	if not is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y = _gravity_sign * maxf(velocity.y * _gravity_sign, 0.0)
	if _dash_time_left <= 0.0:
		velocity.x = _dash_direction * stats.run_speed


func _spawn_afterimage() -> void:
	## Estela del impulso (2026-11-18): copias translúcidas del sprite que se
	## desvanecen en el mundo.
	var frames := visual.sprite_frames
	if frames == null or get_parent() == null:
		return
	var texture := frames.get_frame_texture(visual.animation, visual.frame)
	if texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.name = "DashAfterimage"
	ghost.texture = texture
	ghost.flip_h = visual.flip_h
	ghost.scale = visual.global_scale
	ghost.global_position = visual.global_position
	ghost.modulate = Color(0.55, 0.9, 1.0, 0.55)
	ghost.z_index = z_index - 1
	ghost.add_to_group("dash_afterimages")
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.28)
	tween.tween_callback(ghost.queue_free)


func is_dashing() -> bool:
	return _dash_time_left > 0.0


## Cierto durante el impulso y los instantes posteriores (margen para no quedar
## pegado a un enemigo atravesado y recibir daño al terminar).
func is_intangible() -> bool:
	return _dash_time_left > 0.0 or _intangible_left > 0.0


func _update_intangibility(delta: float) -> void:
	if _dash_time_left > 0.0:
		_intangible_left = DASH_GRACE_TIME
	elif _intangible_left > 0.0:
		_intangible_left = maxf(0.0, _intangible_left - delta)
	if is_intangible():
		_set_enemy_exceptions(true)
	elif _intangible_active:
		_set_enemy_exceptions(false)


## Añade o quita las excepciones de colisión con todos los enemigos que tengan
## `intangible_during_dash` (se refresca cada fotograma para incluir a los que
## aparecen durante el impulso).
func _set_enemy_exceptions(enabled: bool) -> void:
	_intangible_active = enabled
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is PhysicsBody2D or not bool(enemy.get("intangible_during_dash")):
			continue
		if enabled:
			add_collision_exception_with(enemy)
		else:
			remove_collision_exception_with(enemy)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		if _launch_pending:
			_launch_pending = false
		else:
			velocity.y = _gravity_sign * maxf(velocity.y * _gravity_sign, 0.0)
			return

	var fast_falling := Input.is_action_pressed("move_down")
	var falling_speed := velocity.y * _gravity_sign

	if not fast_falling and falling_speed < 0.0 and _jump_hold_left > 0.0 \
			and Input.is_action_pressed("jump"):
		velocity.y -= _gravity_sign * stats.jump_hold_acceleration * delta
		_jump_hold_left = maxf(0.0, _jump_hold_left - delta)
		falling_speed = velocity.y * _gravity_sign

	var current_gravity := stats.gravity
	if falling_speed > 0.0:
		current_gravity *= stats.fall_gravity_multiplier

	falling_speed = minf(falling_speed + current_gravity * delta, stats.max_fall_speed)
	velocity.y = _gravity_sign * falling_speed

	if fast_falling:
		_fast_fall_planted = true
		velocity.y = _gravity_sign * maxf(falling_speed, stats.fast_fall_speed)
		_jump_hold_left = 0.0


func _handle_jump() -> void:
	if _jump_buffer_left <= 0.0:
		return

	var on_ground := is_on_floor() or _coyote_left > 0.0

	if on_ground and _jumps_used == 0:
		_jump()
		_jumps_used = 1
	elif not on_ground and _jumps_used < 2:
		# El doble salto es una habilidad permanente (2026-11-12): siempre
		# hay un impulso aéreo disponible por cada salto desde el suelo.
		_jump()
		_jumps_used = 2


func _jump() -> void:
	# v = sqrt(2 * g * h) permite configurar la altura en lugar de la velocidad.
	velocity.y = -_gravity_sign * sqrt(2.0 * stats.gravity * stats.jump_height)
	_jump_buffer_left = 0.0
	_jump_hold_left = stats.jump_hold_time
	_squash(Vector2(0.84, 1.18), 0.14)
	_dust.restart()
	Sfx.play("jump", -12.0)
	jumped.emit()


func _squash(target_scale: Vector2, duration: float) -> void:
	## Squash & stretch (2026-11-11): estira el cuerpo al saltar y lo
	## comprime al aterrizar; la escala siempre regresa a (1, 1).
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	visual_root.scale = target_scale
	_squash_tween = create_tween()
	_squash_tween.tween_property(visual_root, "scale", Vector2.ONE, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_landed_fx() -> void:
	## Aterrizar comprime el cuerpo según la velocidad de caída y levanta
	## polvo en los pies.
	var impact := clampf(absf(_fall_speed) / 900.0, 0.25, 1.0)
	_squash(Vector2(1.0 + 0.28 * impact, 1.0 - 0.28 * impact), 0.16 + 0.1 * impact)
	_dust.restart()


## Lanza al jugador con `launch_velocity` (px/s) sin hacerle daño. Durante
## `control_lock` segundos el mando no altera la velocidad horizontal.
func launch(launch_velocity: Vector2, control_lock: float = 0.35) -> void:
	if _is_dead:
		return
	velocity = launch_velocity
	_launch_pending = true
	_launch_lock_left = control_lock
	_dash_time_left = 0.0
	_jump_hold_left = 0.0
	_squash(Vector2(0.84, 1.18), 0.14)
	_dust.restart()


## Coloca al jugador en `target` (posición global) y lo detiene.
func teleport_to(target: Vector2) -> void:
	if _is_dead:
		return
	global_position = target
	velocity = Vector2.ZERO
	_launch_lock_left = 0.0
	_dash_time_left = 0.0


func take_damage(amount: int, source: Node = null) -> void:
	if _is_dead or _invulnerability_left > 0.0 or amount <= 0:
		return
	# Durante el impulso se atraviesan enemigos y proyectiles (no trampas).
	if is_intangible() and _is_dash_ignored_source(source):
		return

	# Cualquier golpe normal consume uno de los tres impactos permitidos.
	# Los valores enormes (pozos/cronómetro) siguen siendo letales al instante.
	var applied_damage := health.max_health if amount >= 9999 else 1
	health.take_damage(applied_damage, source)
	if health.is_dead:
		return

	_invulnerability_left = stats.invulnerability_time
	visual.modulate = Color(1.0, 0.55, 0.55, 1.0)
	Sfx.play("hit", -5.0)
	_apply_knockback(source)


func _is_dash_ignored_source(source: Node) -> bool:
	return source is TrainingDummy or source is EnemyProjectile 			or source is ThrownBoulder or source is ShockWave


func _apply_knockback(source: Node) -> void:
	var direction := -_facing
	if source is Node2D:
		direction = signi((source as Node2D).global_position.x - global_position.x)
		if direction == 0:
			direction = -_facing

	velocity.x = float(direction) * stats.knockback_force
	velocity.y = -_gravity_sign * stats.knockback_up_force


func _on_health_died() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	visual.play(ANIM_DEATH)
	visual.modulate = Color(1.0, 0.55, 0.55, 1.0)
	Sfx.play("death", -3.0)

	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	visual_root.scale = Vector2.ONE

	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()

	_death_tween = create_tween()
	_death_tween.set_parallel(true)
	_death_tween.tween_property(
		visual,
		"rotation",
		-PI * 0.42 * float(_facing) * _gravity_sign,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_death_tween.tween_property(visual, "position", Vector2(0.0, 20.0 * _gravity_sign), 0.45)
	_death_tween.tween_property(
		visual,
		"modulate",
		Color(0.65, 0.28, 0.28, 0.0),
		0.9
	).set_delay(0.35)

	died.emit()


func revive(spawn_position: Vector2) -> void:
	## Reaparición en un checkpoint (2026-11-12) sin recargar la escena:
	## restaura la vida y devuelve el cuerpo y la animación a su estado normal.
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()

	_is_dead = false
	health.reset()
	global_position = spawn_position
	velocity = Vector2.ZERO
	_jumps_used = 0
	_jump_buffer_left = 0.0
	_coyote_left = 0.0
	_invulnerability_left = stats.invulnerability_time
	visual.modulate = Color.WHITE
	visual.rotation = 0.0
	visual.position = Vector2.ZERO
	visual_root.scale = Vector2.ONE
	_play_animation(ANIM_IDLE)
	set_physics_process(true)


func _update_animation() -> void:
	var next_animation := ANIM_IDLE

	if not is_on_floor():
		next_animation = ANIM_JUMP if velocity.y * _gravity_sign < 0.0 else ANIM_FALL
	elif absf(velocity.x) > 8.0:
		next_animation = ANIM_RUN if _is_running else ANIM_WALK

	_play_animation(next_animation)


func _play_animation(animation_name: StringName) -> void:
	if visual.animation == animation_name and visual.is_playing():
		return
	visual.play(animation_name)
