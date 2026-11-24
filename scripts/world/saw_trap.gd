extends Area2D
## Sierra móvil que recorre una línea y gira sobre sí misma.
## 2026-11-16: rueda dentada y guía translúcida que marca el recorrido del eje.

const TOOTH_COUNT := 12
const TOOTH_OUTER_RADIUS := 27.0
const TOOTH_INNER_RADIUS := 18.0

@export_range(1, 99, 1) var damage: int = 18
@export_range(0.0, 400.0, 5.0) var move_range: float = 120.0
@export_range(0.1, 6.0, 0.05) var move_speed: float = 1.6
@export_range(0.0, 30.0, 0.5) var spin_speed: float = 9.0
@export_range(0.0, 2.0, 0.05) var warmup_time: float = 0.6

@onready var visual: Node2D = $Visual
@onready var path_guide: Line2D = $PathGuide

var _origin: Vector2
var _time: float = 0.0
var _warmup_left: float = 0.0
var _guide_range: float = -1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_origin = position
	_time = randf() * 10.0
	_warmup_left = warmup_time
	_build_toothed_wheel()
	path_guide.top_level = true
	path_guide.global_position = global_position
	_refresh_path_guide()


func _physics_process(delta: float) -> void:
	if not is_equal_approx(_guide_range, move_range):
		_refresh_path_guide()

	if _warmup_left > 0.0:
		# Aviso (2026-11-12): la sierra parpadea un instante antes de empezar
		# a moverse para que el jugador pueda anticipar el peligro.
		_warmup_left = maxf(0.0, _warmup_left - delta)
		visual.modulate.a = 0.55 + 0.45 * absf(sin(_warmup_left * 22.0))
		if _warmup_left <= 0.0:
			visual.modulate.a = 1.0
		return

	_time += delta
	position.x = _origin.x + sin(_time * move_speed) * move_range
	visual.rotation += spin_speed * delta


func _build_toothed_wheel() -> void:
	var wheel := get_node_or_null("Visual/Wheel") as Polygon2D
	var outline := get_node_or_null("Visual/Wheel/Outline") as Line2D
	var points := PackedVector2Array()
	for index in TOOTH_COUNT * 2:
		var angle := -PI * 0.5 + float(index) * PI / float(TOOTH_COUNT)
		var radius := TOOTH_OUTER_RADIUS if index % 2 == 0 else TOOTH_INNER_RADIUS
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	if wheel != null:
		wheel.polygon = points
	if outline != null:
		outline.points = points


func _refresh_path_guide() -> void:
	if path_guide == null:
		return
	_guide_range = move_range
	path_guide.visible = move_range > 0.0
	path_guide.points = PackedVector2Array([
		Vector2(-move_range, 0.0),
		Vector2(move_range, 0.0),
	])


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage, self)
