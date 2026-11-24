class_name HorizontalCamera
extends Camera2D
## Cámara de seguimiento horizontal con suavizado independiente del framerate.
## La altura se mantiene fija para que el nivel conserve una lectura estable.
## Los límites se configuran con las propiedades limit_* de Camera2D.

@export var target_path: NodePath
@export var follow_offset: Vector2 = Vector2.ZERO
@export var fixed_y: float = 360.0
## Seguimiento vertical (2026-11-18) para niveles altos como el laberinto; los
## límites limit_top/limit_bottom de Camera2D acotan el recorrido.
@export var follow_y: bool = false
@export_range(0.0, 30.0, 0.1) var follow_smoothing: float = 8.0

var _target: Node2D
var _shake_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		push_warning("HorizontalCamera: no se encontró el nodo objetivo.")
		set_physics_process(false)
		return

	global_position = Vector2(
		_target.global_position.x + follow_offset.x,
		_desired_y()
	)


func _desired_y() -> float:
	if follow_y:
		return _target.global_position.y + follow_offset.y
	return fixed_y + follow_offset.y


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	var desired_x := _target.global_position.x + follow_offset.x
	var desired_y := _desired_y()
	var weight := 1.0 - exp(-follow_smoothing * delta)

	global_position.x = lerpf(global_position.x, desired_x, weight)
	global_position.y = lerpf(global_position.y, desired_y, weight) if follow_y else desired_y

	if _shake_left > 0.0:
		_shake_left = maxf(0.0, _shake_left - delta)
		var fade := _shake_left / maxf(0.001, _shake_duration)
		global_position += Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * _shake_strength * fade


func shake(strength: float, duration: float) -> void:
	## Sacudida breve al recibir daño (2026-11-12) para dar feedback claro.
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(0.01, duration)
	_shake_left = _shake_duration


func snap_to_target() -> void:
	## Coloca la cámara al instante tras reaparecer en un checkpoint.
	if is_instance_valid(_target):
		global_position = Vector2(
			_target.global_position.x + follow_offset.x,
			_desired_y()
		)
