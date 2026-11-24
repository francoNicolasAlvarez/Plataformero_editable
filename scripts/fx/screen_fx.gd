class_name ScreenFx
extends RefCounted
## Efectos de pantalla de "game feel" (2026-11-18), tomados de las guías de
## Godot 4 sobre pulido: parada de impacto (hit-stop) al recibir daño y viñeta
## suave que oscurece los bordes y centra la mirada en el jugador.

const VIGNETTE_LAYER := 8
const VIGNETTE_STRENGTH := 0.38
const HIT_STOP_SCALE := 0.06

static var _hit_stop_active: bool = false


## Congela casi todo el juego `duration` s reales. No hace nada en headless
## (los tests miden el tiempo por fotogramas) ni si ya hay una parada activa.
static func hit_stop(tree: SceneTree, duration: float = 0.07) -> void:
	if tree == null or _hit_stop_active or DisplayServer.get_name() == "headless":
		return
	_hit_stop_active = true
	Engine.time_scale = HIT_STOP_SCALE
	# Temporizador que ignora la escala de tiempo (ignore_time_scale = true).
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


## Añade al nivel una capa con una viñeta radial (por debajo del HUD).
static func add_vignette(parent: Node) -> CanvasLayer:
	var existing := parent.get_node_or_null("VignetteLayer") as CanvasLayer
	if existing != null:
		return existing
	var layer := CanvasLayer.new()
	layer.name = "VignetteLayer"
	layer.layer = VIGNETTE_LAYER
	parent.add_child(layer)
	var rect := TextureRect.new()
	rect.name = "Vignette"
	rect.texture = _vignette_texture()
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer


static func _vignette_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, VIGNETTE_STRENGTH),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.8)
	texture.width = 256
	texture.height = 144
	return texture
