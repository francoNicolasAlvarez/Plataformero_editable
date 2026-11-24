class_name RangedEnemy
extends TrainingDummy
## Enemigo a distancia: mago azul con baston que lanza orbes de energia azul.
## Reutiliza vida, daño por contacto y muerte del enemigo base, y añade
## gravedad y disparos cuando detecta al jugador.
## Cambio 2026-11-18: ya no exige línea de visión (ataca siempre dentro de su
## alcance, con su aviso) y su frecuencia de disparo baja un 50 % (3,4 s).
## Cambio 2026-11-11: ya no apunta al jugador; los proyectiles vuelan siempre
## en horizontal, hacia el lado en el que esté el jugador (se esquiva
## saltando o cambiando de altura).
## Cambio 2026-11-16 (visuales/sonido): cada disparo lanza 3 orbes de
## energia azul en un abanico horizontal de +-10 grados, con sonido propio.

const PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

const FIREBALL_COUNT := 3
const FIREBALL_SPREAD_DEG := 10.0

@export_range(60.0, 900.0, 10.0) var shoot_range: float = 430.0
@export_range(0.4, 6.0, 0.05) var shoot_interval: float = 3.4
@export_range(80.0, 600.0, 10.0) var projectile_speed: float = 240.0
@export_range(0.0, 3000.0, 10.0) var gravity: float = 1400.0
@export_range(0.0, 200.0, 5.0) var patrol_speed: float = 32.0
@export_range(10.0, 400.0, 5.0) var patrol_distance: float = 52.0
## Los guardias que viajan sobre plataformas móviles no deben moverse por su
## cuenta: el padre ya los desplaza y move_and_slide los desincronizaba.
@export var anchored: bool = false
## Segundos de aviso visual antes de cada disparo: el mago acumula energía
## en el bastón y el arquero tensa el arco (ver `_telegraph_update`).
@export_range(0.1, 1.5, 0.05) var telegraph_time: float = 0.6

var _shoot_cooldown: float = 0.8
var _origin_x: float = 0.0
var _direction: int = -1
var _telegraphing: bool = false
var _charge: EnergyCharge


func _ready() -> void:
	super._ready()
	_origin_x = global_position.x
	_setup_telegraph()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if anchored:
		_check_contact_damage()
		return
	if not is_on_floor():
		velocity.y += gravity * _gravity_sign * delta
	else:
		velocity.y = 0.0

	velocity.x = float(_direction) * patrol_speed
	move_and_slide()

	if is_on_wall():
		_direction *= -1
	if absf(global_position.x - _origin_x) >= patrol_distance:
		_direction = -1 if global_position.x > _origin_x else 1

	_check_contact_damage()


func _process(delta: float) -> void:
	super._process(delta)
	if _is_dead:
		return

	_shoot_cooldown -= delta
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return

	var offset := target.global_position - global_position
	if absf(offset.x) > shoot_range or absf(offset.y) > 170.0:
		_telegraph_end()
		return

	var direction := 1.0 if offset.x >= 0.0 else -1.0
	visual.scale.x = direction

	if _shoot_cooldown > 0.0:
		# Aviso visual justo antes del disparo (2026-11-18).
		if _shoot_cooldown <= telegraph_time:
			_telegraphing = true
			_telegraph_update(1.0 - _shoot_cooldown / telegraph_time)
		return

	_telegraph_end()
	_shoot(direction)
	_shoot_cooldown = shoot_interval


func _reset_state() -> void:
	_telegraph_end()
	_shoot_cooldown = 0.8
	_direction = -1


func is_telegraphing() -> bool:
	return _telegraphing


func _setup_telegraph() -> void:
	## Mago: luz de carga sobre el orbe del bastón (hijo de `Visual`, así se
	## voltea con el enemigo).
	var staff := get_node_or_null("Visual/Staff")
	if staff == null:
		return
	_charge = EnergyCharge.new()
	_charge.name = "EnergyCharge"
	_charge.position = Vector2(0.0, -20.0)
	_charge.color = Color(1.0, 0.62, 0.25, 1.0)
	_charge.max_radius = 30.0
	_charge.core_max = 7.0
	staff.add_child(_charge)


func _telegraph_update(progress: float) -> void:
	if _charge != null:
		_charge.set_progress(progress)
	var glow := get_node_or_null("Visual/Staff/OrbGlow") as Polygon2D
	if glow != null:
		glow.scale = Vector2.ONE * (1.0 + 1.2 * progress)


func _telegraph_end() -> void:
	if not _telegraphing:
		return
	_telegraphing = false
	if _charge != null:
		_charge.stop()
	var glow := get_node_or_null("Visual/Staff/OrbGlow") as Polygon2D
	if glow != null:
		glow.scale = Vector2.ONE


## Los proyectiles deben vivir en el mundo, no dentro de una plataforma móvil:
## si fueran hijos de ella, la plataforma los arrastraría al desplazarse.
func _projectile_parent() -> Node:
	var node := get_parent()
	while node != null and node.is_in_group("moving_platforms"):
		node = node.get_parent()
	return node if node != null else get_parent()


func _shoot(direction: float) -> void:
	## Tres bolas de fuego en abanico horizontal (2026-11-11): no persiguen al
	## jugador; salen hacia su lado a la altura del enemigo, así que se
	## esquivan saltando. Los ángulos son fijos alrededor de la horizontal.
	var aim := Vector2(direction, 0.0)
	var step := deg_to_rad(FIREBALL_SPREAD_DEG)
	var start_angle := -step * float(FIREBALL_COUNT - 1) * 0.5
	for i in FIREBALL_COUNT:
		var shot_velocity := aim.rotated(start_angle + step * float(i)) * projectile_speed
		var projectile := PROJECTILE_SCENE.instantiate()
		_projectile_parent().add_child(projectile)
		projectile.global_position = global_position + Vector2(direction * 30.0, -14.0 * _gravity_sign)
		projectile.direction = direction
		projectile.speed = projectile_speed
		projectile.velocity = shot_velocity
		projectile.rotation = shot_velocity.angle()
	Sfx.play("magic", -13.0)
