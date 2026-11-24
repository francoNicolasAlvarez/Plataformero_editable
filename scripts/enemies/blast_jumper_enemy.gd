class_name BlastJumperEnemy
extends TrainingDummy
## Saltador explosivo (2026-11-17). Permanece quieto hasta detectar al jugador;
## entonces comprime el cuerpo y parpadea en rojo (señal visual) durante
## `windup_time`, salta rápido hacia delante describiendo una parábola y, al
## aterrizar, genera una onda expansiva a ras de suelo (ShockWave). Después
## necesita `rest_time` segundos para volver a prepararse. No basta con saltar
## sobre el enemigo: hay que calcular también dónde aterrizar para esquivar la
## onda.
## Variación `long_jump`: saltos más largos y onda mayor, pero con preparación
## más lenta.

signal blasted(position: Vector2, radius: float)

enum State { IDLE, WINDUP, AIR, REST }

const FEET_OFFSET := 17.0
const SHORT_DISTANCE := 470.0
const LONG_DISTANCE := 640.0

@export var long_jump: bool = false
@export_range(100.0, 900.0, 10.0) var detect_range: float = 520.0
@export_range(40.0, 400.0, 5.0) var detect_height: float = 200.0
@export_range(0.0, 4000.0, 10.0) var gravity: float = 2000.0
@export_range(200.0, 1400.0, 10.0) var jump_speed: float = 720.0
@export_range(0.2, 3.0, 0.05) var windup_time: float = 0.7
@export_range(0.5, 8.0, 0.1) var rest_time: float = 5.0
@export_range(60.0, 400.0, 5.0) var wave_radius: float = 260.0

var state: State = State.IDLE
var max_distance: float = SHORT_DISTANCE
var last_target_x: float = 0.0

var _timer: float = 0.0
var _flash: float = 0.0
var _body_poly: Polygon2D


func _ready() -> void:
	_build_visual()
	super._ready()
	_visual_base_y = 0.0
	if long_jump:
		max_distance = LONG_DISTANCE
		windup_time = maxf(windup_time, 1.1)
		rest_time = maxf(rest_time, 6.0)
		jump_speed = 820.0
		wave_radius = 340.0


func _reset_state() -> void:
	state = State.IDLE
	_timer = 0.0
	_flash = 0.0


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if not is_on_floor():
		velocity.y += gravity * _gravity_sign * delta
	else:
		velocity.y = 0.0

	match state:
		State.IDLE:
			velocity.x = 0.0
			_try_detect()
		State.WINDUP:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_launch()
		State.REST:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				state = State.IDLE

	move_and_slide()

	if state == State.AIR and is_on_floor() and velocity.y * _gravity_sign >= 0.0:
		_land()
	_check_contact_damage()


func _process(delta: float) -> void:
	super._process(delta)
	if _is_dead:
		return
	var squash := Vector2.ONE
	var target := get_tree().get_first_node_in_group("player") as Node2D
	var facing := 1.0 if visual.scale.x >= 0.0 else -1.0
	if target != null and state != State.AIR:
		facing = 1.0 if target.global_position.x >= global_position.x else -1.0
	match state:
		State.WINDUP:
			var progress := 1.0 - clampf(_timer / windup_time, 0.0, 1.0)
			squash = Vector2(1.0 + 0.3 * progress, 1.0 - 0.4 * progress)
			_flash += delta * (10.0 + 20.0 * progress)
			var blink := 0.5 + 0.5 * sin(_flash)
			visual.modulate = Color(1.0, 1.0 - 0.6 * blink, 1.0 - 0.6 * blink, 1.0)
		State.AIR:
			squash = Vector2(0.85, 1.25)
			visual.modulate = Color.WHITE
		State.REST:
			squash = Vector2(1.1, 0.9)
			visual.modulate = Color(0.8, 0.8, 0.8, 1.0)
		_:
			visual.modulate = Color.WHITE
	visual.scale = Vector2(facing * squash.x, squash.y * _gravity_sign)
	visual.position.y += FEET_OFFSET * _gravity_sign * (1.0 - squash.y)


func _try_detect() -> void:
	if not is_on_floor():
		return
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return
	var offset := target.global_position - global_position
	if absf(offset.x) > detect_range or absf(offset.y) > detect_height:
		return
	state = State.WINDUP
	_timer = windup_time
	_flash = 0.0


func air_time() -> float:
	return 2.0 * jump_speed / gravity


func _launch() -> void:
	var horizontal := 0.0
	var target := get_tree().get_first_node_in_group("player") as Node2D
	last_target_x = global_position.x
	if target != null:
		# Apunta a donde estará el jugador al aterrizar (2026-11-18) para que la
		# explosión caiga lo más cerca posible de él.
		var predicted_x := target.global_position.x
		if target is CharacterBody2D:
			predicted_x += (target as CharacterBody2D).velocity.x * air_time() * 0.85
		var dx := clampf(predicted_x - global_position.x, -max_distance, max_distance)
		# Si donde aterrizaría no hay suelo, acorta el salto (hasta saltar en el sitio).
		for _attempt in 4:
			if absf(dx) < 8.0 or _has_floor_at(global_position.x + dx):
				break
			dx *= 0.5
		if not _has_floor_at(global_position.x + dx):
			dx = 0.0
		horizontal = dx / air_time()
		last_target_x = global_position.x + dx
	velocity = Vector2(horizontal, -jump_speed * _gravity_sign)
	state = State.AIR
	Sfx.play("jump", -14.0)


func _land() -> void:
	velocity.x = 0.0
	state = State.REST
	_timer = rest_time
	var wave := ShockWave.new()
	wave.name = "ShockWave"
	wave.max_radius = wave_radius
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector2(0.0, FEET_OFFSET * _gravity_sign)
	Fx.make_burst(get_parent(), wave.global_position, Color(0.85, 0.6, 0.35, 0.9))
	Sfx.play("bomb", -10.0)
	blasted.emit(wave.global_position, wave_radius)


func _has_floor_at(x: float) -> bool:
	var from := Vector2(x, global_position.y - 40.0 * _gravity_sign)
	var to := Vector2(x, global_position.y + 320.0 * _gravity_sign)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _build_visual() -> void:
	## Criatura rechoncha con barriles de explosivo en el lomo (40 px de ancho,
	## pies en +17). La variante de salto largo es morada.
	var base_color := Color("#8a4fa8") if long_jump else Color("#e07a2f")
	var dark := base_color.darkened(0.35)
	var body := PackedVector2Array([
		Vector2(-19, 17), Vector2(-21, 4), Vector2(-14, -9), Vector2(0, -13),
		Vector2(14, -9), Vector2(21, 4), Vector2(19, 17),
	])
	_body_poly = _poly("Body", body, base_color)
	_poly("Stripe", PackedVector2Array([Vector2(-20, 1), Vector2(20, 1), Vector2(21, 6), Vector2(-21, 6)]), Color("#ffd23f"))
	_poly("FootLeft", PackedVector2Array([Vector2(-19, 12), Vector2(-5, 12), Vector2(-5, 17), Vector2(-19, 17)]), dark)
	_poly("FootRight", PackedVector2Array([Vector2(5, 12), Vector2(19, 12), Vector2(19, 17), Vector2(5, 17)]), dark)
	_poly("Fuse", PackedVector2Array([Vector2(-1, -13), Vector2(2, -13), Vector2(2, -19), Vector2(-1, -19)]), Color("#3a2416"))
	_poly("Spark", PackedVector2Array([Vector2(-3, -24), Vector2(4, -24), Vector2(4, -18), Vector2(-3, -18)]), Color("#ffdd55"))
	_poly("EyeLeft", PackedVector2Array([Vector2(-11, -6), Vector2(-4, -6), Vector2(-4, 0), Vector2(-11, 0)]), Color.WHITE)
	_poly("EyeRight", PackedVector2Array([Vector2(4, -6), Vector2(11, -6), Vector2(11, 0), Vector2(4, 0)]), Color.WHITE)
	_poly("PupilLeft", PackedVector2Array([Vector2(-7, -4), Vector2(-4, -4), Vector2(-4, -1), Vector2(-7, -1)]), Color.BLACK)
	_poly("PupilRight", PackedVector2Array([Vector2(8, -4), Vector2(11, -4), Vector2(11, -1), Vector2(8, -1)]), Color.BLACK)
	var outline := Line2D.new()
	outline.name = "Outline"
	outline.points = body
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	$Visual.add_child(outline)


func _poly(node_name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	$Visual.add_child(polygon)
	return polygon
