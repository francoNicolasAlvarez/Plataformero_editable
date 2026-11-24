class_name Health
extends Node
## Componente de vida reutilizable para jugadores, enemigos u objetos.
## Cualquier cuerpo que lo use solo necesita exponer take_damage().

signal health_changed(current: int, maximum: int)
signal damaged(amount: int, source: Node)
signal died

@export_range(1, 9999, 1) var max_health: int = 30

var current_health: int = 0
var is_dead: bool = false


func _ready() -> void:
	reset()


## Restaura la vida al máximo y reactiva el componente.
func reset() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: int, source: Node = null) -> void:
	if is_dead or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		is_dead = true
		died.emit()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
