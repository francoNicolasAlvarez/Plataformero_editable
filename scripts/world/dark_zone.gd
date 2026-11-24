class_name DarkZone
extends GimmickZone
## Zona oscura (Fase 4, 2026-11-18): mientras el jugador está dentro, la
## pantalla se oscurece y solo queda un círculo de luz alrededor de él
## (`light_radius`, px de pantalla); fuera de la luz se intuyen las siluetas.
## El efecto es una capa propia (por debajo del HUD) con una textura radial y
## se desvanece al entrar y salir (`fade_time`). Sirve para cuevas y minas.

const OVERLAY_LAYER := 5

@export var light_radius: float = 260.0
@export var fade_time: float = 0.5
@export_range(0.0, 1.0, 0.05) var darkness: float = 0.93

var overlay_layer: CanvasLayer
var shade: TextureRect
var _amount: float = 0.0


func _ready() -> void:
	super._ready()
	_build_overlay()
	set_process(false)  # solo trabaja mientras hay oscuridad que animar


func _build_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.name = "DarkOverlay"
	overlay_layer.layer = OVERLAY_LAYER
	add_child(overlay_layer)
	shade = TextureRect.new()
	shade.name = "Shade"
	shade.texture = _make_light_texture()
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.size = Vector2(light_radius * 2.0, light_radius * 2.0) * 6.0
	shade.pivot_offset = shade.size * 0.5
	shade.modulate.a = 0.0
	shade.visible = false
	overlay_layer.add_child(shade)


func _process(delta: float) -> void:
	var target := 1.0 if player_inside else 0.0
	_amount = move_toward(_amount, target, delta / maxf(fade_time, 0.01))
	shade.modulate.a = _amount * darkness
	shade.visible = _amount > 0.001
	if not shade.visible:
		if not player_inside:
			set_process(false)
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	# Posición del jugador en pantalla, para centrar el círculo de luz.
	var screen_position := player.get_global_transform_with_canvas().origin
	shade.position = screen_position - shade.size * 0.5


## Oscuridad actual 0..1 (para tests y otros efectos).
func current_amount() -> float:
	return _amount


func _on_player_entered() -> void:
	set_process(true)


func _on_reset() -> void:
	_amount = 0.0
	if shade != null:
		shade.modulate.a = 0.0
		shade.visible = false


func _make_light_texture() -> GradientTexture2D:
	## Centro transparente (luz) que se cierra en negro; el radio de luz
	## es 1/6 de la mitad del ancho de la textura (12 veces el radio de luz).
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.117, 0.167, 0.27, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.02, 0.02, 0.06, 0.0),
		Color(0.02, 0.02, 0.06, 0.0),
		Color(0.02, 0.02, 0.06, 0.55),
		Color(0.01, 0.01, 0.03, 1.0),
		Color(0.01, 0.01, 0.03, 1.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture
