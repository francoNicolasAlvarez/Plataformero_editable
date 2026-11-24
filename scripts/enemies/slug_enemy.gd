class_name SlugEnemy
extends TrainingDummy
## Babosa saltarina (2026-11-17). Permanece quieta y de vez en cuando salta con
## una de tres alturas (nunca repite la misma dos veces seguidas). Antes de
## cada salto se agacha (`windup_time`), así que el momento del salto se puede
## leer y hay que calcular si pasar por encima o esperar. Si el jugador está
## cerca salta hacia su posición aproximada (con error de +-50 px); si no, salta
## en el sitio. Antes de saltar hacia delante comprueba que haya suelo donde
## aterrizaría, para no caer a un foso.
## Variante `double_jump`: encadena dos saltos seguidos antes de detenerse
## (color naranja en vez de verde).

signal jumped(jump_speed: float, horizontal_speed: float)

enum State { IDLE, WINDUP, AIR, LANDING }

const JUMP_SPEEDS := [340.0, 470.0, 600.0]
const AIM_ERROR := 50.0
const FEET_OFFSET := 16.0

@export var double_jump: bool = false
@export_range(100.0, 900.0, 10.0) var aggro_range: float = 480.0
@export_range(0.0, 1.0, 0.05) var toward_player_chance: float = 0.75
@export_range(0.3, 6.0, 0.05) var idle_min: float = 0.6
@export_range(0.3, 6.0, 0.05) var idle_max: float = 1.2
@export_range(0.1, 1.5, 0.05) var windup_time: float = 0.4
@export_range(0.0, 3000.0, 10.0) var gravity: float = 1400.0
@export_range(50.0, 600.0, 10.0) var max_horizontal_speed: float = 330.0

var state: State = State.IDLE
var jumps_left: int = 0
var last_target_x: float = 0.0
var last_jump_was_aimed: bool = false

var _timer: float = 0.0
var _height_index: int = -1
var _pending_speed: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_build_visual()
	super._ready()
	_rng.randomize()
	_visual_base_y = 0.0
	_timer = _rng.randf_range(idle_min, idle_max)


func seed_random(value: int) -> void:
	_rng.seed = value


func _reset_state() -> void:
	state = State.IDLE
	jumps_left = 0
	_timer = 0.0


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
			if is_on_floor():
				_timer -= delta
				if _timer <= 0.0:
					jumps_left = 2 if double_jump else 1
					_begin_windup(windup_time)
		State.WINDUP:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_launch()
		State.LANDING:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				if jumps_left > 0:
					_begin_windup(windup_time * 0.6)
				else:
					state = State.IDLE
					_timer = _rng.randf_range(idle_min, idle_max)

	move_and_slide()

	if state == State.AIR and is_on_floor() and velocity.y * _gravity_sign >= 0.0:
		velocity.x = 0.0
		state = State.LANDING
		_timer = 0.18
	_check_contact_damage()


func _process(delta: float) -> void:
	super._process(delta)
	if _is_dead:
		return
	var squash := Vector2.ONE
	match state:
		State.WINDUP:
			var depth := 0.62 + 0.1 * float(maxi(_height_index, 0)) * -1.0 + 0.1
			squash = Vector2(1.25, clampf(depth, 0.5, 0.8))
		State.AIR:
			squash = Vector2(0.85, 1.2)
		State.LANDING:
			squash = Vector2(1.3, 0.7)
	var facing := 1.0 if visual.scale.x >= 0.0 else -1.0
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target != null and state != State.AIR:
		facing = 1.0 if target.global_position.x >= global_position.x else -1.0
	visual.scale = Vector2(facing * squash.x, squash.y * _gravity_sign)
	# Los pies se quedan en el suelo aunque el cuerpo se agache o se estire.
	visual.position.y += FEET_OFFSET * _gravity_sign * (1.0 - squash.y)


func _begin_windup(duration: float) -> void:
	state = State.WINDUP
	_timer = duration
	_height_index = _pick_height_index()
	_pending_speed = float(JUMP_SPEEDS[_height_index])


func _pick_height_index() -> int:
	var choice := _rng.randi_range(0, JUMP_SPEEDS.size() - 1)
	if choice == _height_index:
		choice = (choice + 1 + _rng.randi_range(0, JUMP_SPEEDS.size() - 2)) % JUMP_SPEEDS.size()
	return choice


func _launch() -> void:
	var horizontal := 0.0
	last_jump_was_aimed = false
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target != null and _rng.randf() < toward_player_chance:
		var dx := target.global_position.x - global_position.x
		if absf(dx) <= aggro_range:
			dx += _rng.randf_range(-AIM_ERROR, AIM_ERROR)
			var air_time := 2.0 * _pending_speed / gravity
			horizontal = clampf(dx / air_time, -max_horizontal_speed, max_horizontal_speed)
			last_target_x = global_position.x + horizontal * air_time
			last_jump_was_aimed = true
			if not _has_floor_at(last_target_x):
				horizontal = 0.0
				last_jump_was_aimed = false
	velocity = Vector2(horizontal, -_pending_speed * _gravity_sign)
	jumps_left -= 1
	state = State.AIR
	Sfx.play("jump", -18.0)
	jumped.emit(_pending_speed, horizontal)


func _has_floor_at(x: float) -> bool:
	var from := Vector2(x, global_position.y - 40.0 * _gravity_sign)
	var to := Vector2(x, global_position.y + 320.0 * _gravity_sign)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _build_visual() -> void:
	## Cuerpo bajo y alargado (48 px de ancho, pies en +16), con ojos en
	## tallos. La variante de doble salto es naranja.
	var base_color := Color("#e08a3a") if double_jump else Color("#6aa84f")
	var dark := base_color.darkened(0.3)
	var belly := base_color.lightened(0.35)
	var body := PackedVector2Array([
		Vector2(-24, 16), Vector2(-24, 6), Vector2(-17, -5), Vector2(-5, -11),
		Vector2(10, -9), Vector2(20, -2), Vector2(24, 8), Vector2(24, 16),
	])
	_poly("Body", body, base_color)
	_poly("Belly", PackedVector2Array([Vector2(-24, 11), Vector2(24, 11), Vector2(24, 16), Vector2(-24, 16)]), belly)
	_poly("SpotA", PackedVector2Array([Vector2(-14, -1), Vector2(-8, -4), Vector2(-5, 2), Vector2(-11, 4)]), dark)
	_poly("SpotB", PackedVector2Array([Vector2(-2, 0), Vector2(4, -3), Vector2(7, 3), Vector2(1, 5)]), dark)
	_poly("StalkLeft", PackedVector2Array([Vector2(11, -8), Vector2(14, -8), Vector2(14, -21), Vector2(11, -21)]), base_color)
	_poly("StalkRight", PackedVector2Array([Vector2(18, -4), Vector2(21, -4), Vector2(21, -19), Vector2(18, -19)]), base_color)
	_poly("EyeLeft", PackedVector2Array([Vector2(9, -27), Vector2(16, -27), Vector2(16, -20), Vector2(9, -20)]), Color.WHITE)
	_poly("EyeRight", PackedVector2Array([Vector2(16, -25), Vector2(23, -25), Vector2(23, -18), Vector2(16, -18)]), Color.WHITE)
	_poly("PupilLeft", PackedVector2Array([Vector2(13, -25), Vector2(16, -25), Vector2(16, -22), Vector2(13, -22)]), Color.BLACK)
	_poly("PupilRight", PackedVector2Array([Vector2(20, -23), Vector2(23, -23), Vector2(23, -20), Vector2(20, -20)]), Color.BLACK)
	var outline := Line2D.new()
	outline.name = "Outline"
	outline.points = body
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	$Visual.add_child(outline)


func _poly(node_name: String, points: PackedVector2Array, color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	$Visual.add_child(polygon)
