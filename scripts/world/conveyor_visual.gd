class_name ConveyorVisual
extends Node2D
## Dibujo de cinta transportadora de fábrica (2026-11-24): banda de goma con
## tacos en chevron y un rodillo en cada extremo. La animación tiene 3
## fotogramas distintos (los tacos avanzan un tercio de su paso en cada uno) y
## el sentido sigue el signo de `speed`. Lo crea `Platform` al activar su
## `conveyor_speed`; no tiene colisión (la mueve la propia plataforma).

const FRAME_COUNT := 3
const TREAD_PITCH := 24.0
const MAX_FPS := 18.0

var size: Vector2 = Vector2(200.0, 24.0)
var speed: float = 160.0
var frame: int = 0
var _time: float = 0.0


func _ready() -> void:
	z_index = 1
	set_process(not Engine.is_editor_hint())


func configure(new_size: Vector2, new_speed: float) -> void:
	size = new_size
	speed = new_speed
	queue_redraw()


## Fotogramas por segundo según la velocidad de la cinta.
func frames_per_second() -> float:
	return clampf(absf(speed) / TREAD_PITCH * FRAME_COUNT * 0.5, 4.0, MAX_FPS)


func _process(delta: float) -> void:
	_time += delta
	var next := int(_time * frames_per_second()) % FRAME_COUNT
	if next != frame:
		frame = next
		queue_redraw()


## Desplazamiento de los tacos (px) en el fotograma actual.
func tread_offset() -> float:
	var step := TREAD_PITCH / float(FRAME_COUNT)
	return step * float(frame) * signf(speed)


func _draw() -> void:
	var half := size * 0.5
	var band_inset := minf(half.y * 0.55, 9.0)
	var band := Rect2(Vector2(-half.x + band_inset, -half.y), Vector2(size.x - band_inset * 2.0, size.y))
	draw_rect(band, Color(0.13, 0.13, 0.15))
	# Rodillos metálicos de los extremos.
	var radius := half.y * 0.95
	for side in [-1.0, 1.0]:
		var center := Vector2(side * (half.x - radius), 0.0)
		draw_circle(center, radius, Color(0.45, 0.47, 0.52))
		draw_circle(center, radius * 0.45, Color(0.2, 0.2, 0.24))
		draw_arc(center, radius, 0.0, TAU, 20, Color.BLACK, 2.0)
	# Tacos en chevron (">" según el sentido) que se desplazan por fotograma.
	var direction := signf(speed)
	if is_zero_approx(direction):
		direction = 1.0
	var left := band.position.x
	var right := band.end.x
	var offset := fposmod(tread_offset(), TREAD_PITCH)
	var x := left - TREAD_PITCH + offset
	var tip := minf(half.y * 0.8, 9.0)
	var tread_color := Color(0.95, 0.78, 0.2)
	while x < right + TREAD_PITCH:
		var points := PackedVector2Array([
			Vector2(x - tip * 0.5 * direction, -tip),
			Vector2(x + tip * 0.5 * direction, 0.0),
			Vector2(x - tip * 0.5 * direction, tip),
		])
		var inside := true
		for point in points:
			inside = inside and point.x >= left and point.x <= right
		if inside:
			draw_polyline(points, tread_color, 3.0)
		x += TREAD_PITCH
	# Bordes de la banda.
	draw_line(Vector2(band.position.x, -half.y + 1.0), Vector2(band.end.x, -half.y + 1.0), Color(0.55, 0.55, 0.6), 2.0)
	draw_line(Vector2(band.position.x, half.y - 1.0), Vector2(band.end.x, half.y - 1.0), Color(0.05, 0.05, 0.07), 2.0)
