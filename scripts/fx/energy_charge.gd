class_name EnergyCharge
extends Node2D
## Efecto de luz de carga (2026-11-18): destellos que convergen hacia un punto y
## un núcleo luminoso que crece, como si el mago acumulara energía antes de
## lanzar. Se dibuja con mezcla aditiva. `set_progress(0..1)` lo actualiza cada
## frame; `stop()` lo oculta.

const SPARK_COUNT := 8

var color: Color = Color(1.0, 0.7, 0.3, 1.0)
var max_radius: float = 40.0
## Radio máximo del núcleo luminoso (px).
var core_max: float = 9.0
var progress: float = 0.0
var active: bool = false

var _spin: float = 0.0


func _ready() -> void:
	var material_add := CanvasItemMaterial.new()
	material_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = material_add
	z_index = 10
	visible = false


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	active = true
	visible = true
	queue_redraw()


func stop() -> void:
	active = false
	visible = false
	progress = 0.0


func _process(delta: float) -> void:
	if active:
		_spin += delta * (4.0 + 10.0 * progress)
		queue_redraw()


func _draw() -> void:
	if not active:
		return
	# Núcleo y halos que crecen y se intensifican.
	var core := lerpf(core_max * 0.25, core_max, progress)
	draw_circle(Vector2.ZERO, core * 2.2, Color(color.r, color.g, color.b, 0.10 + 0.14 * progress))
	draw_circle(Vector2.ZERO, core * 1.4, Color(color.r, color.g, color.b, 0.25 + 0.25 * progress))
	draw_circle(Vector2.ZERO, core, Color(1.0, 0.97, 0.85, 0.55 + 0.45 * progress))
	# Chispas que convergen hacia el núcleo.
	for index in SPARK_COUNT:
		var phase := fmod(progress * 1.6 + float(index) / float(SPARK_COUNT), 1.0)
		var angle := _spin * 0.25 + TAU * float(index) / float(SPARK_COUNT)
		var radius := lerpf(max_radius, core, phase)
		var spark := Vector2(cos(angle), sin(angle)) * radius
		var tail := Vector2(cos(angle), sin(angle)) * (radius + 7.0)
		var alpha := 0.35 + 0.65 * phase
		draw_line(tail, spark, Color(color.r, color.g, color.b, alpha), 2.0)
		draw_circle(spark, 1.8, Color(1.0, 0.95, 0.8, alpha))
