extends Node2D
## Mantiene el sol fijo en pantalla, por encima del fondo y detrás del nivel.

@export var screen_offset: Vector2 = Vector2(360.0, -200.0)


func _ready() -> void:
	top_level = true
	z_index = -19


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		global_position = camera.get_screen_center_position() + screen_offset
