class_name ShockWave
extends Node2D
## Onda expansiva a ras de suelo (2026-11-17), creada por el saltador explosivo
## al aterrizar. Crece desde el punto de impacto hasta `max_radius` en
## `duration` segundos. Daña una vez al jugador que esté dentro del radio con
## los pies a ras de suelo; saltando por encima se evita. Se construye por
## código.

const PLAYER_FEET := 24.0
const GROUND_TOLERANCE := 22.0

@export var max_radius: float = 150.0
@export var duration: float = 0.4
@export var damage: int = 15

var ground_y: float = 0.0
var hit_player: bool = false

var _time: float = 0.0
var _ring: Line2D
var _fill: Polygon2D


func _ready() -> void:
	add_to_group("shock_waves")
	z_index = 5
	_fill = Polygon2D.new()
	_fill.color = Color(1.0, 0.55, 0.2, 0.25)
	add_child(_fill)
	_ring = Line2D.new()
	_ring.width = 5.0
	_ring.default_color = Color(1.0, 0.7, 0.3, 0.9)
	_ring.closed = true
	add_child(_ring)
	_update_shape(0.0)


func current_radius() -> float:
	return max_radius * clampf(_time / duration, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if _time == 0.0:
		# La posición se asigna después de añadir el nodo: el suelo se fija aquí.
		ground_y = global_position.y
	_time += delta
	var radius := current_radius()
	_update_shape(radius)
	modulate.a = 1.0 - clampf((_time - duration) / 0.2, 0.0, 1.0)
	if not hit_player and _time <= duration:
		_check_player(radius)
	if _time >= duration + 0.2:
		queue_free()


func _check_player(radius: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var dx := absf(player.global_position.x - global_position.x)
	var feet := player.global_position.y + PLAYER_FEET
	if dx <= radius and feet >= ground_y - GROUND_TOLERANCE and feet <= ground_y + 40.0:
		hit_player = true
		player.take_damage(damage, self)


func _update_shape(radius: float) -> void:
	var ring := PackedVector2Array()
	var fill := PackedVector2Array()
	var height := maxf(2.0, radius * 0.16)
	for step in 24:
		var angle := TAU * float(step) / 24.0
		var point := Vector2(cos(angle) * radius, -absf(sin(angle)) * height)
		ring.append(point)
		fill.append(point)
	_ring.points = ring
	_fill.polygon = fill
