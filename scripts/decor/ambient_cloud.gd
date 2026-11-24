extends Node2D
## Nube decorativa con deriva lenta.

@export var drift_speed: float = 5.0


func _process(delta: float) -> void:
	position.x += drift_speed * delta
