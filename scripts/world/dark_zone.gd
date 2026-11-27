class_name DarkZone
extends GimmickZone
## Zona oscura (Fase 4, 2026-11-18): mientras el jugador está dentro, la
## pantalla se oscurece y solo queda un círculo de luz alrededor de él
## (`light_radius`, px de pantalla); fuera de la luz se intuyen las siluetas.
## El efecto es una capa propia (por debajo del HUD) con una textura radial y
## se desvanece al entrar y salir (`fade_time`). Sirve para cuevas y minas.
## Balizas (2026-11-27): el portal, los controles, las hierbas y las llaves
## dibujan un halo de su color SOBRE la oscuridad, para que los objetos
## importantes no desaparezcan (guía de diseño, sección 2).

const OVERLAY_LAYER := 5
## Grupo -> color del halo de las balizas.
const BEACON_GROUPS := {
	"exit_portals": Color(0.3, 0.9, 1.0),
	"checkpoints": Color(1.0, 0.85, 0.35),
	"healing_pickups": Color(0.45, 1.0, 0.5),
	"keys": Color(1.0, 0.85, 0.3),
}
const BEACON_SIZE := 90.0

@export var light_radius: float = 260.0
@export var fade_time: float = 0.5
@export_range(0.0, 1.0, 0.05) var darkness: float = 0.93

var overlay_layer: CanvasLayer
var shade: TextureRect
var _amount: float = 0.0
var _beacon_root: Node2D
var _beacon_texture: GradientTexture2D


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
	_beacon_root = Node2D.new()
	_beacon_root.name = "Beacons"
	overlay_layer.add_child(_beacon_root)


func _process(delta: float) -> void:
	var target := 1.0 if player_inside else 0.0
	_amount = move_toward(_amount, target, delta / maxf(fade_time, 0.01))
	shade.modulate.a = _amount * darkness
	shade.visible = _amount > 0.001
	if not shade.visible:
		for beacon in _beacon_root.get_children():
			(beacon as CanvasItem).visible = false
		if not player_inside:
			set_process(false)
		return
	_update_beacons()
	var player := EnemySenses.player(self)
	if player == null:
		return
	# Posición del jugador en pantalla, para centrar el círculo de luz.
	var screen_position := player.get_global_transform_with_canvas().origin
	shade.position = screen_position - shade.size * 0.5


func _update_beacons() -> void:
	var screen := get_viewport().get_visible_rect().grow(BEACON_SIZE)
	var used := 0
	for group in BEACON_GROUPS:
		for target in get_tree().get_nodes_in_group(group):
			var item := target as CanvasItem
			if item == null or not item.is_visible_in_tree():
				continue
			var at := (target as Node2D).get_global_transform_with_canvas().origin
			if not screen.has_point(at):
				continue
			var beacon := _beacon(used)
			beacon.position = at
			beacon.modulate = Color(BEACON_GROUPS[group], 0.55 * _amount)
			beacon.visible = true
			used += 1
	for index in range(used, _beacon_root.get_child_count()):
		(_beacon_root.get_child(index) as CanvasItem).visible = false


## Número de balizas visibles (para tests).
func visible_beacons() -> int:
	if _beacon_root == null:
		return 0
	var count := 0
	for beacon in _beacon_root.get_children():
		if (beacon as CanvasItem).visible:
			count += 1
	return count


func _beacon(index: int) -> Sprite2D:
	if index < _beacon_root.get_child_count():
		return _beacon_root.get_child(index) as Sprite2D
	if _beacon_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		_beacon_texture = GradientTexture2D.new()
		_beacon_texture.gradient = gradient
		_beacon_texture.fill = GradientTexture2D.FILL_RADIAL
		_beacon_texture.fill_from = Vector2(0.5, 0.5)
		_beacon_texture.fill_to = Vector2(1.0, 0.5)
		_beacon_texture.width = 64
		_beacon_texture.height = 64
	var beacon := Sprite2D.new()
	beacon.texture = _beacon_texture
	beacon.scale = Vector2.ONE * (BEACON_SIZE / 64.0)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	beacon.material = material
	_beacon_root.add_child(beacon)
	return beacon


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
	if _beacon_root != null:
		for beacon in _beacon_root.get_children():
			(beacon as CanvasItem).visible = false


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
