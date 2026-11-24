extends AnimatableBody2D
## Plataforma móvil con cuatro comportamientos (2026-11-12):
## - Lineal/diagonal: viaja entre dos puntos con `travel` y `speed`.
## - Circular: orbita su origen con `circle_radius` y `circle_speed`.
## - Giro sobre su eje: `rotation_speed` (rad/s), independiente del movimiento.
## La inclinación nunca supera MAX_TILT_RADIANS (30°): las plataformas oscilan
## en vez de dar vueltas completas, así siguen siendo pisables.
## Los valores por defecto conservan el vaivén horizontal de los niveles 2 y 3.

const MAX_TILT_RADIANS := PI / 6.0
const PLATFORM_TEXTURE := preload("res://scripts/world/platform_texture.gd")

@export var travel: Vector2 = Vector2(260.0, 0.0)
@export_range(0.1, 5.0, 0.05) var speed: float = 1.1
@export var circle_radius: float = 0.0
@export_range(0.0, 5.0, 0.05) var circle_speed: float = 0.9
@export_range(-6.0, 6.0, 0.05) var rotation_speed: float = 0.0

var _origin: Vector2
var _time: float = 0.0
var _base_rotation: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = position
	_base_rotation = clampf(rotation, -MAX_TILT_RADIANS, MAX_TILT_RADIANS)
	rotation = _base_rotation
	_refresh_texture()


func _physics_process(delta: float) -> void:
	_time += delta
	if circle_radius > 0.0:
		var angle := _time * circle_speed
		position = _origin + Vector2(cos(angle), sin(angle)) * circle_radius
	else:
		position = _origin + travel * (0.5 - 0.5 * cos(_time * speed))
	if not is_zero_approx(rotation_speed):
		rotation = _base_rotation + sin(_time * rotation_speed) * MAX_TILT_RADIANS


func _refresh_texture() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var size := Vector2(180.0, 22.0)
	if collision != null and collision.shape is RectangleShape2D:
		size = (collision.shape as RectangleShape2D).size
	var color := Color("#d38f46")
	if visual != null:
		color = visual.color
	PLATFORM_TEXTURE.apply(self, size, color)
