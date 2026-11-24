extends Node2D
## Ave posada en un árbol. Se balancea y picotea suavemente.

@export var bob_amount: float = 2.5
@export var bob_speed: float = 2.2

@onready var visual: Sprite2D = $Sprite2D

var _base_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_base_y = visual.position.y
	_time = randf() * 10.0


func _process(delta: float) -> void:
	_time += delta
	visual.position.y = _base_y + sin(_time * bob_speed) * bob_amount
	visual.rotation = sin(_time * 1.4) * 0.04
	visual.flip_h = fmod(_time, 6.0) > 3.0
