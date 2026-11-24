@tool
extends Area2D
## Zona de caída. Elimina al jugador si cae fuera del nivel.
## `zone_size` se puede editar en el Inspector (y la forma se actualiza al
## instante en el editor); es el ancho/alto de la zona mortal.

const DEFAULT_SIZE := Vector2(14000.0, 80.0)

@export var zone_size: Vector2 = DEFAULT_SIZE:
	set(value):
		zone_size = value
		_apply_size()


func _ready() -> void:
	_apply_size()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _apply_size() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is RectangleShape2D and not zone_size.is_equal_approx(DEFAULT_SIZE):
		(collision.shape as RectangleShape2D).size = zone_size


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).health.take_damage(9999)
