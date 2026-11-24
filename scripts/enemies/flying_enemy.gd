class_name FlyingEnemy
extends TrainingDummy
## Enemigo volador (2026-11-13): cruza la pantalla de un extremo al otro sin
## perseguir al jugador y con un patrón ondulante vertical. El generador
## (FlyingSpawner) decide el lado, la altura y la frecuencia; este enemigo solo
## se mueve en horizontal y suma una onda senoidal sobre su altura de origen.
## No usa gravedad ni colisiones con el mundo: el daño es por contacto.
## 2026-11-16: desaparece al salir por el borde visible en su dirección.

@export var horizontal_speed: float = 190.0
@export_range(0.0, 200.0, 1.0) var wave_amplitude: float = 84.0
@export_range(0.0, 12.0, 0.05) var wave_frequency: float = 4.4
@export var despawn_margin: float = 48.0
@export var direction: int = 1

var _flight_time: float = 0.0
var _spawn_y: float = 0.0
var _wing_time: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("flying_enemies")
	_spawn_y = position.y
	direction = 1 if direction >= 0 else -1
	rotation = 0.0


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_flight_time += delta
	position.x += float(direction) * horizontal_speed * delta
	position.y = _spawn_y + sin(_flight_time * wave_frequency) * wave_amplitude
	_check_contact_damage()
	if _is_past_visible_edge():
		queue_free()


func _is_past_visible_edge() -> bool:
	var bounds := _visible_world_rect()
	if direction > 0:
		return global_position.x > bounds.end.x + despawn_margin
	return global_position.x < bounds.position.x - despawn_margin


func _visible_world_rect() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return get_viewport_rect()
	var viewport_size := get_viewport_rect().size
	var zoom := Vector2(maxf(camera.zoom.x, 0.01), maxf(camera.zoom.y, 0.01))
	var half_size := viewport_size * 0.5 / zoom
	var center := camera.get_screen_center_position()
	return Rect2(center - half_size, half_size * 2.0)


func _process(delta: float) -> void:
	if _is_dead:
		return
	_wing_time += delta
	var flap := sin(_wing_time * 12.0) * 0.45
	var wing_left := get_node_or_null("Visual/WingLeft") as Node2D
	var wing_right := get_node_or_null("Visual/WingRight") as Node2D
	if wing_left != null:
		wing_left.rotation = flap
	if wing_right != null:
		wing_right.rotation = -flap
	visual.position.y = sin(_wing_time * 3.4) * 2.0
