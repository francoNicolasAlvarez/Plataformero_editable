class_name GimmickZone
extends Area2D
## Base de las zonas con efecto sobre el jugador (Fase 4, 2026-11-18): un
## rectángulo `zone_size` centrado en el nodo que avisa cuando el jugador
## entra y sale (`player_inside`). Las subclases (p. ej. `DarkZone`) aplican
## el efecto en `_on_player_entered()`/`_on_player_exited()`. `reset()` lo
## llama `TestLevel` al morir.

signal player_entered
signal player_exited

@export var zone_size: Vector2 = Vector2(600.0, 700.0)

var player_inside: bool = false


func _ready() -> void:
	add_to_group("gimmick_zones")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	shape.name = "ZoneShape"
	var rectangle := RectangleShape2D.new()
	rectangle.size = zone_size
	shape.shape = rectangle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func contains_x(x: float) -> bool:
	return absf(x - global_position.x) <= zone_size.x * 0.5


func reset() -> void:
	player_inside = false
	_on_reset()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not player_inside:
		player_inside = true
		_on_player_entered()
		player_entered.emit()


func _on_body_exited(body: Node2D) -> void:
	if body is Player and player_inside:
		player_inside = false
		_on_player_exited()
		player_exited.emit()


func _on_player_entered() -> void:
	pass


func _on_player_exited() -> void:
	pass


func _on_reset() -> void:
	pass
