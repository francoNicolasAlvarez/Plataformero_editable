class_name SpearmanEnemy
extends TrainingDummy
## Lancero de patrulla (2026-11-17). Patrulla su plataforma de un extremo al
## otro y no se cae por el borde. Cuando el jugador entra en su alcance se
## detiene en postura de preparación (la lanza hacia atrás) medio segundo,
## realiza una estocada horizontal muy rápida y queda recuperándose un rato
## con la lanza baja. Hay que calcular el momento: saltar sobre la estocada o
## aprovechar la recuperación para pasar.
## Variación `narrow`: cubre plataformas estrechas (apenas se mueve) y su lanza
## llega más lejos, así que obliga a saltos precisos.
## Cambio 2026-11-18: el alcance sube un 50 % (180 / 225 px desde el cuerpo) y la
## estocada ya no es una línea sino un abanico de 90 grados (±45° respecto a la
## horizontal). El abanico se dibuja como aviso durante la preparación.
## Cambio 2026-11-18: la estocada dura 0,1 s y es un barrido: la lanza parte
## apuntando hacia delante y sube hasta 90° (vertical); el abanico cubre ese
## cuarto de círculo (de la horizontal hacia arriba). La frecuencia de ataque
## baja un 50 %: tras recuperarse espera `attack_cooldown` antes del siguiente.

signal thrust_started

enum State { PATROL, WINDUP, THRUST, RECOVER }

const REACH := 180.0
const REACH_NARROW := 225.0
const SWEEP_ANGLE_DEG := 90.0
const FAN_ORIGIN := Vector2(18.0, -2.0)
## Posición local de la lanza durante el barrido (la mano).
const SPEAR_SWEEP_X := 20.0
const SPEAR_REST_X := 0.0
const SPEAR_WINDUP_X := -24.0
const SPEAR_THRUST_X := 62.0

@export var narrow: bool = false
@export_range(0.0, 300.0, 5.0) var patrol_speed: float = 70.0
@export_range(10.0, 600.0, 5.0) var patrol_distance: float = 140.0
@export_range(60.0, 600.0, 10.0) var detect_range: float = 280.0
@export_range(20.0, 300.0, 5.0) var detect_height: float = 90.0
@export_range(0.1, 2.0, 0.05) var windup_time: float = 0.5
@export_range(0.05, 0.5, 0.01) var thrust_time: float = 0.1
@export_range(0.2, 3.0, 0.05) var recover_time: float = 0.9
@export_range(0.0, 3000.0, 10.0) var gravity: float = 1400.0
## Pausa entre ataques (la duración del ciclo se duplica: -50 % de frecuencia).
@export_range(0.0, 5.0, 0.05) var attack_cooldown: float = 1.55
@export var thrust_damage: int = 15

var state: State = State.PATROL
var facing: int = -1
var reach: float = REACH

var _origin_x: float = 0.0
var _timer: float = 0.0
var _cooldown_left: float = 0.0
var _thrust_hit: bool = false
var _spear: Node2D
var _hitbox: Area2D
var _spear_tween: Tween
var _fan: Polygon2D


func _ready() -> void:
	_build_visual()
	super._ready()
	if narrow:
		patrol_distance = 30.0
		patrol_speed = 40.0
		reach = REACH_NARROW
	_origin_x = global_position.x
	_build_hitbox()
	_build_fan_indicator()
	_set_spear(SPEAR_REST_X, 0.0)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if not is_on_floor():
		velocity.y += gravity * _gravity_sign * delta
	else:
		velocity.y = 0.0

	match state:
		State.PATROL:
			_patrol()
			_cooldown_left = maxf(0.0, _cooldown_left - delta)
			_try_detect()
		State.WINDUP:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_begin_thrust()
		State.THRUST:
			velocity.x = 0.0
			_timer -= delta
			_apply_thrust_damage()
			if _timer <= 0.0:
				_begin_recover()
		State.RECOVER:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				state = State.PATROL
				_set_spear(SPEAR_REST_X, 0.15)

	move_and_slide()
	_check_contact_damage()


func _process(delta: float) -> void:
	super._process(delta)
	if _is_dead:
		return
	visual.scale.x = float(facing) * absf(visual.scale.y)
	_update_fan_indicator()
	# Aviso visual: el cuerpo se tiñe de amarillo mientras se prepara.
	if state == State.WINDUP:
		visual.modulate = Color(1.0, 0.95, 0.55, 1.0)
	elif visual.modulate != Color.WHITE and state != State.WINDUP:
		visual.modulate = visual.modulate.lerp(Color.WHITE, minf(1.0, delta * 12.0))


func _reset_state() -> void:
	state = State.PATROL
	facing = -1
	_timer = 0.0
	_cooldown_left = 0.0
	_thrust_hit = false
	if _hitbox != null:
		_hitbox.monitoring = false
	visual.modulate = Color.WHITE
	_set_spear(SPEAR_REST_X, 0.0, 0.0)


func _patrol() -> void:
	if is_on_wall():
		facing = -facing
	if absf(global_position.x - _origin_x) >= patrol_distance:
		facing = -1 if global_position.x > _origin_x else 1
	if is_on_floor() and not _floor_ahead():
		facing = -facing
	velocity.x = float(facing) * patrol_speed


func _floor_ahead() -> bool:
	var from := global_position + Vector2(float(facing) * 24.0, 0.0)
	var to := from + Vector2(0.0, 60.0 * _gravity_sign)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _try_detect() -> void:
	if not is_on_floor() or _cooldown_left > 0.0:
		return
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return
	var offset := target.global_position - global_position
	if absf(offset.x) > detect_range or absf(offset.y) > detect_height:
		return
	facing = 1 if offset.x >= 0.0 else -1
	state = State.WINDUP
	_timer = windup_time
	velocity.x = 0.0
	_set_spear(SPEAR_WINDUP_X, windup_time * 0.6, 0.0)


func _begin_thrust() -> void:
	state = State.THRUST
	_timer = thrust_time
	_thrust_hit = false
	_hitbox.position.x = float(facing) * FAN_ORIGIN.x
	_hitbox.scale.x = float(facing)
	_hitbox.monitoring = true
	_set_spear(SPEAR_SWEEP_X, thrust_time, -SWEEP_ANGLE_DEG)
	Sfx.play("attack", -14.0)
	thrust_started.emit()


func _begin_recover() -> void:
	state = State.RECOVER
	_timer = recover_time
	_hitbox.monitoring = false
	_cooldown_left = attack_cooldown
	_set_spear(SPEAR_THRUST_X * 0.4, 0.15, 0.0)
	visual.modulate = Color(0.75, 0.75, 0.85, 1.0)


func _apply_thrust_damage() -> void:
	if _thrust_hit:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(thrust_damage, self)
			_thrust_hit = true
			return


func _set_spear(x: float, duration: float, angle_deg: float = 0.0) -> void:
	## Coloca la lanza en `x` con una inclinación (grados, negativo = hacia
	## arriba); durante el barrido ambas cosas se animan en `duration`.
	if _spear == null:
		return
	if _spear_tween != null and _spear_tween.is_valid():
		_spear_tween.kill()
	if duration <= 0.0:
		_spear.position.x = x
		_spear.rotation_degrees = angle_deg
		return
	_spear_tween = create_tween().set_parallel(true)
	_spear_tween.tween_property(_spear, "position:x", x, duration)
	_spear_tween.tween_property(_spear, "rotation_degrees", angle_deg, duration)


func fan_points(radius: float) -> PackedVector2Array:
	## Sector de 90 grados: de la horizontal (+X) hasta la vertical hacia arriba.
	var points := PackedVector2Array([Vector2.ZERO])
	var sweep := deg_to_rad(SWEEP_ANGLE_DEG)
	var steps := 8
	for step in steps + 1:
		var angle := -sweep + sweep * float(step) / float(steps)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _build_hitbox() -> void:
	_hitbox = Area2D.new()
	_hitbox.name = "SpearHitbox"
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitoring = false
	var shape := CollisionPolygon2D.new()
	shape.polygon = fan_points(reach)
	_hitbox.add_child(shape)
	_hitbox.position = Vector2(float(facing) * FAN_ORIGIN.x, FAN_ORIGIN.y)
	add_child(_hitbox)


func _build_fan_indicator() -> void:
	## Abanico translúcido que marca la zona de la estocada (aviso de ataque).
	_fan = Polygon2D.new()
	_fan.name = "FanIndicator"
	_fan.polygon = fan_points(reach)
	_fan.color = Color(1.0, 0.25, 0.2, 0.0)
	_fan.z_index = 5
	_fan.visible = false
	add_child(_fan)


func _update_fan_indicator() -> void:
	if _fan == null:
		return
	_fan.position = Vector2(float(facing) * FAN_ORIGIN.x, FAN_ORIGIN.y * _gravity_sign)
	_fan.scale = Vector2(float(facing), _gravity_sign)
	match state:
		State.WINDUP:
			var progress := 1.0 - clampf(_timer / windup_time, 0.0, 1.0)
			_fan.visible = true
			_fan.color = Color(1.0, 0.3, 0.2, 0.08 + 0.3 * progress)
		State.THRUST:
			_fan.visible = true
			_fan.color = Color(1.0, 0.9, 0.5, 0.6)
		_:
			_fan.visible = false


func _build_visual() -> void:
	## Soldado de armadura azul con casco y una lanza larga; la lanza es un nodo
	## aparte (`Spear`) para poder echarla hacia atrás y proyectarla.
	var armor := Color("#4a6fa5")
	var armor_dark := Color("#37537c")
	var skin := Color("#d9a077")
	_rect("LegLeft", Rect2(-9, 10, 7, 14), Color("#2f3f5e"))
	_rect("LegRight", Rect2(2, 10, 7, 14), Color("#2f3f5e"))
	_rect("Torso", Rect2(-11, -10, 22, 21), armor)
	_rect("TorsoShade", Rect2(2, -10, 9, 21), armor_dark)
	_rect("Belt", Rect2(-11, 6, 22, 4), Color("#3a2416"))
	_rect("ArmBack", Rect2(-14, -8, 5, 14), armor_dark)
	_rect("Neck", Rect2(-3, -13, 6, 4), skin)
	_rect("Head", Rect2(-7, -24, 14, 12), skin)
	_rect("Helmet", Rect2(-8, -26, 16, 7), Color("#9aa7b8"))
	_rect("HelmetCrest", Rect2(-2, -30, 4, 5), Color("#c62828"))
	_rect("EyeFront", Rect2(2, -19, 3, 3), Color.BLACK)
	_spear = Node2D.new()
	_spear.name = "Spear"
	$Visual.add_child(_spear)
	var shaft := Polygon2D.new()
	shaft.name = "Shaft"
	shaft.color = Color("#7a5230")
	shaft.polygon = PackedVector2Array([Vector2(-30, -3), Vector2(76, -3), Vector2(76, 0), Vector2(-30, 0)])
	_spear.add_child(shaft)
	var tip := Polygon2D.new()
	tip.name = "Tip"
	tip.color = Color("#d8dee6")
	tip.polygon = PackedVector2Array([Vector2(76, -6), Vector2(90, -1.5), Vector2(76, 3)])
	_spear.add_child(tip)
	_rect("ArmFront", Rect2(8, -6, 12, 5), armor)
	_rect("HandFront", Rect2(18, -6, 5, 5), skin)


func _rect(node_name: String, rect: Rect2, color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	$Visual.add_child(polygon)
