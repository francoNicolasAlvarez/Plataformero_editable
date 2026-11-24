extends Area2D
## Pinchos estáticos colocados en el suelo o en el fondo de los fosos.

@export_range(1, 99, 1) var damage: int = 15

@onready var visual: Polygon2D = $Visual

var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Brillo pulsante (2026-11-12) para que los pinchos destaquen del suelo.
	_time += delta
	visual.modulate = Color(1.0, 1.0, 1.0, 0.82 + 0.18 * sin(_time * 3.2))


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage, self)
