class_name WalkerEnemy
extends TrainingDummy
## Enemigo patrullero. Reutiliza toda la lógica de vida y daño del enemigo
## de prueba y añade movimiento horizontal con detección de bordes.

@export_range(0.0, 500.0, 5.0) var patrol_speed: float = 60.0
@export_range(10.0, 1000.0, 5.0) var patrol_distance: float = 120.0
@export_range(0.0, 3000.0, 10.0) var gravity: float = 1400.0

# 2026-11-13: los enemigos que patrullan sin disparar se mueven algo más
# rápido; se aplica a todos los niveles sin tocar sus overrides de velocidad.
const MOVE_SPEED_SCALE := 1.25

@onready var floor_ray: RayCast2D = $FloorAhead

var _origin_x: float = 0.0
var _direction: int = -1


func _ready() -> void:
	super._ready()
	_origin_x = global_position.x
	floor_ray.position.x = float(_direction) * 20.0
	if inverted_gravity:
		floor_ray.target_position.y = -34.0


func _reset_state() -> void:
	_direction = -1
	floor_ray.position.x = float(_direction) * 20.0


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * _gravity_sign * delta
	else:
		velocity.y = 0.0

	velocity.x = float(_direction) * patrol_speed * MOVE_SPEED_SCALE
	move_and_slide()

	if is_on_wall():
		_direction *= -1

	if absf(global_position.x - _origin_x) >= patrol_distance:
		_direction = -1 if global_position.x > _origin_x else 1

	# Si no hay suelo delante, gira antes de caer de la plataforma.
	floor_ray.position.x = float(_direction) * 20.0
	floor_ray.force_raycast_update()
	if is_on_floor() and not floor_ray.is_colliding():
		_direction *= -1

	_check_contact_damage()
