class_name OrbEnemy
extends TrainingDummy
## Orbe perseguidor (2026-11-17). Permanece suspendido en el aire. Cuando el
## jugador entra en su radio de detección lo persigue en línea recta con
## aceleración progresiva (empieza lento y gana velocidad). Si choca contra una
## pared o una plataforma se detiene `stun_time` segundos (aturdido, apagado) y
## vuelve a activarse. Si el jugador se aleja demasiado, vuelve a quedarse
## suspendido.
## Variación `axis = VERTICAL`: solo se desplaza en vertical (sube o baja hasta
## la altura del jugador) y reacciona cuando éste pasa cerca de su columna.
## Cambio 2026-11-18: el orbe vertical ya no sigue al jugador; sube y baja sin
## parar entre `vertical_range` px por encima y por debajo de su posición
## inicial (y rebota si choca con una plataforma).

enum State { HOVER, CHASE, STUNNED }
enum Axis { FREE, VERTICAL }

@export var axis: Axis = Axis.FREE
@export_range(80.0, 900.0, 10.0) var detect_radius: float = 380.0
@export_range(10.0, 300.0, 5.0) var start_speed: float = 50.0
@export_range(60.0, 900.0, 10.0) var max_speed: float = 320.0
@export_range(20.0, 1500.0, 10.0) var acceleration: float = 220.0
@export_range(0.1, 3.0, 0.05) var stun_time: float = 0.8
@export_range(1.0, 3.0, 0.1) var lose_factor: float = 1.5
## Velocidad máxima de giro del rumbo (rad/s); ~100°/s por defecto.
@export_range(0.2, 12.0, 0.1) var turn_speed: float = 1.8

## Recorrido (px) hacia cada lado y velocidad del orbe vertical.
@export_range(20.0, 600.0, 5.0) var vertical_range: float = 140.0
@export_range(20.0, 600.0, 5.0) var vertical_speed: float = 120.0

var state: State = State.HOVER
var speed: float = 0.0

var _heading: Vector2 = Vector2.ZERO
var _origin_y: float = 0.0
var _origin_set: bool = false
var _vertical_dir: float = 1.0
var _timer: float = 0.0
var _pulse: float = 0.0
var _glow: Polygon2D
var _core: Polygon2D


func _ready() -> void:
	_build_visual()
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_visual_base_y = 0.0


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if axis == Axis.VERTICAL:
		_vertical_patrol()
		_check_contact_damage()
		return
	var target := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		State.HOVER:
			velocity = Vector2.ZERO
			if target != null and _in_range(target, 1.0):
				_start_chase()
		State.CHASE:
			if target == null or not _in_range(target, lose_factor):
				state = State.HOVER
				velocity = Vector2.ZERO
			else:
				speed = minf(max_speed, speed + acceleration * delta)
				_steer_toward(_direction_to(target), delta)
				velocity = _heading * speed
				move_and_slide()
				if get_slide_collision_count() > 0:
					_stun()
		State.STUNNED:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				if target != null and _in_range(target, 1.0):
					_start_chase()
				else:
					state = State.HOVER
	_check_contact_damage()


func _process(delta: float) -> void:
	super._process(delta)
	if _is_dead:
		return
	_pulse += delta * (9.0 if state == State.CHASE else 3.0)
	var scale_factor := 1.0 + 0.08 * sin(_pulse)
	visual.scale = Vector2.ONE * scale_factor
	if state == State.STUNNED:
		_core.color = Color("#6c5b8a")
		_glow.color = Color(0.55, 0.45, 0.8, 0.12)
	else:
		var heat := clampf(speed / max_speed, 0.0, 1.0)
		_core.color = Color("#b48cff").lerp(Color("#ff6fb0"), heat)
		_glow.color = Color(0.7, 0.5, 1.0, 0.25 + 0.2 * heat)


func _reset_state() -> void:
	state = State.HOVER
	speed = 0.0
	_heading = Vector2.ZERO
	_vertical_dir = 1.0
	_timer = 0.0


func _vertical_patrol() -> void:
	## Oscilación constante, independiente del jugador. El centro se fija en el
	## primer frame (los layouts colocan al enemigo tras añadirlo).
	if not _origin_set:
		_origin_set = true
		_origin_y = global_position.y
	state = State.CHASE
	speed = vertical_speed
	if global_position.y >= _origin_y + vertical_range:
		_vertical_dir = -1.0
	elif global_position.y <= _origin_y - vertical_range:
		_vertical_dir = 1.0
	velocity = Vector2(0.0, _vertical_dir * vertical_speed)
	move_and_slide()
	if get_slide_collision_count() > 0:
		_vertical_dir = -_vertical_dir


func _in_range(target: Node2D, factor: float) -> bool:
	var offset := target.global_position - global_position
	if axis == Axis.VERTICAL:
		return absf(offset.x) <= detect_radius * 0.5 * factor and absf(offset.y) <= detect_radius * factor
	return offset.length() <= detect_radius * factor


func _direction_to(target: Node2D) -> Vector2:
	var offset := target.global_position - global_position
	if axis == Axis.VERTICAL:
		return Vector2(0.0, signf(offset.y)) if absf(offset.y) > 6.0 else Vector2.ZERO
	return offset.normalized()


func _steer_toward(desired: Vector2, delta: float) -> void:
	## Giro limitado (2026-11-18): el rumbo solo puede rotar `turn_speed`
	## rad/s hacia el jugador, así que conserva inercia y se esquiva con
	## cambios bruscos de dirección. En eje vertical no hay giro que limitar.
	if axis == Axis.VERTICAL or desired == Vector2.ZERO:
		_heading = desired
		return
	if _heading == Vector2.ZERO:
		_heading = desired
		return
	var diff := wrapf(desired.angle() - _heading.angle(), -PI, PI)
	var step := clampf(diff, -turn_speed * delta, turn_speed * delta)
	_heading = _heading.rotated(step)


func _start_chase() -> void:
	state = State.CHASE
	speed = start_speed
	var target := get_tree().get_first_node_in_group("player") as Node2D
	_heading = _direction_to(target) if target != null else Vector2.ZERO


func _stun() -> void:
	state = State.STUNNED
	speed = 0.0
	velocity = Vector2.ZERO
	_timer = stun_time
	Sfx.play("hit", -18.0)


func _build_visual() -> void:
	var points := PackedVector2Array()
	for step in 16:
		var angle := TAU * float(step) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * 17.0)
	var halo_points := PackedVector2Array()
	for step in 16:
		var angle := TAU * float(step) / 16.0
		halo_points.append(Vector2(cos(angle), sin(angle)) * 26.0)
	_glow = Polygon2D.new()
	_glow.name = "Glow"
	_glow.polygon = halo_points
	_glow.color = Color(0.7, 0.5, 1.0, 0.25)
	$Visual.add_child(_glow)
	_core = Polygon2D.new()
	_core.name = "Core"
	_core.polygon = points
	_core.color = Color("#b48cff")
	$Visual.add_child(_core)
	var shine := Polygon2D.new()
	shine.name = "Shine"
	shine.polygon = PackedVector2Array([Vector2(-9, -9), Vector2(-2, -12), Vector2(-4, -5), Vector2(-10, -3)])
	shine.color = Color(1.0, 1.0, 1.0, 0.6)
	$Visual.add_child(shine)
	var eye := Polygon2D.new()
	eye.name = "Eye"
	eye.polygon = PackedVector2Array([Vector2(-5, -2), Vector2(5, -2), Vector2(5, 5), Vector2(-5, 5)])
	eye.color = Color("#2a1840")
	$Visual.add_child(eye)
	var outline := Line2D.new()
	outline.name = "Outline"
	outline.points = points
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	$Visual.add_child(outline)
