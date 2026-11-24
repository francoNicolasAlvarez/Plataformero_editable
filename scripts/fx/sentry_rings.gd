class_name SentryRings
extends Node2D
## Tres círculos que se encogen hasta envolver el ojo del centinela (2026-11-18)
## a tres velocidades: rápido, medio y lento. Todos arrancan a la vez con el
## mismo radio; el rápido se cierra primero, luego el medio y por último el
## lento, y al cerrarse el tercero el centinela dispara. Un anillo ya cerrado se
## queda ajustado al ojo. Los radios están en píxeles de pantalla (el nodo no
## hereda la escala del dibujo del centinela).

const START_RADIUS := 78.0
const END_RADIUS := 24.0
## Tiempo (s) que tarda cada círculo en cerrarse: rápido, medio, lento.
const CLOSE_TIMES := [0.4, 0.8, 1.2]
const COLORS := [Color(1.0, 0.85, 0.35), Color(1.0, 0.55, 0.2), Color(1.0, 0.22, 0.15)]

## Colores de los tres círculos (rápido, medio, lento); el centinela azul usa otros.
var palette: Array = COLORS
var elapsed: float = 0.0
var active: bool = false


func _ready() -> void:
	var material_add := CanvasItemMaterial.new()
	material_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = material_add
	z_index = 10
	visible = false


static func total_time() -> float:
	return CLOSE_TIMES[CLOSE_TIMES.size() - 1]


func ring_radius(index: int) -> float:
	var progress := clampf(elapsed / CLOSE_TIMES[index], 0.0, 1.0)
	return lerpf(START_RADIUS, END_RADIUS, progress)


func is_closed(index: int) -> bool:
	return elapsed >= CLOSE_TIMES[index]


func set_elapsed(seconds: float) -> void:
	elapsed = maxf(0.0, seconds)
	active = true
	visible = true
	queue_redraw()


func stop() -> void:
	active = false
	visible = false
	elapsed = 0.0


func _draw() -> void:
	if not active:
		return
	for index in 3:
		var color: Color = palette[index]
		var radius := ring_radius(index)
		var closed := is_closed(index)
		# Destello breve en el instante de cerrarse.
		var since_close := elapsed - float(CLOSE_TIMES[index])
		var flash := clampf(1.0 - since_close / 0.15, 0.0, 1.0) if closed else 0.0
		var width := 2.5 + 3.0 * flash
		var alpha := 0.55 + 0.35 * (elapsed / total_time()) + 0.3 * flash
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, minf(alpha, 1.0)), width)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.18), width + 5.0)
