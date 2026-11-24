class_name MenuBackdrop
extends Control
## Fondo diurno del menú principal (2026-11-17), hecho solo con recursos que ya
## existen: cielo en degradado, sol, nubes, colinas, árboles y el jugador
## corriendo en el sitio con sus sprites. Las animaciones son lentas y se
## calculan en _process (nubes, arbustos y ciclo de carrera); no compite con
## los botones. El viewport es fijo (canvas_items), por lo que se maqueta en
## el espacio lógico de 1152x648.

const VIEW := Vector2(1152.0, 648.0)
const GROUND_Y := 560.0
const RUN_FRAME_TIME := 0.14
const BUSH_SPEED := 120.0

var _clouds: Array[TextureRect] = []
var _cloud_speeds: Array[float] = [9.0, 15.0, 12.0]
var _bushes: Array[Sprite2D] = []
var _runner: Sprite2D
var _run_frames: Array[Texture2D] = []
var _run_time: float = 0.0


func _ready() -> void:
	name = "MenuBackdrop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_sky()
	_build_sun()
	_build_clouds()
	_build_hills()
	_build_trees()
	_build_ground()
	_build_runner()


func _process(delta: float) -> void:
	for index in _clouds.size():
		var cloud := _clouds[index]
		cloud.position.x += _cloud_speeds[index] * delta
		if cloud.position.x > VIEW.x + 20.0:
			cloud.position.x = -cloud.size.x - 20.0

	for bush in _bushes:
		bush.position.x -= BUSH_SPEED * delta
		if bush.position.x < -120.0:
			bush.position.x = VIEW.x + 80.0

	if _runner != null and _run_frames.size() > 1:
		_run_time += delta
		_runner.texture = _run_frames[int(_run_time / RUN_FRAME_TIME) % _run_frames.size()]


func _build_sky() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([MenuStyle.SKY_DEEP, MenuStyle.SKY, MenuStyle.SKY_PALE])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 8
	texture.height = 256
	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.texture = texture
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)


func _build_sun() -> void:
	var sun := _make_texture_rect("Sun", "res://assets/decor/sun.svg", Vector2(170.0, 170.0))
	sun.position = Vector2(880.0, 24.0)


func _build_clouds() -> void:
	var placements := [Vector2(620.0, 70.0), Vector2(900.0, 160.0), Vector2(380.0, 250.0)]
	for index in placements.size():
		var cloud := _make_texture_rect("Cloud%d" % (index + 1), "res://assets/decor/cloud.svg", Vector2(200.0, 82.0))
		cloud.position = placements[index]
		_clouds.append(cloud)


func _build_hills() -> void:
	_add_hill("HillsBack", GROUND_Y - 150.0, 70.0, 0.0042, 0.8, Color("#4A8F7A"))
	_add_hill("HillsFront", GROUND_Y - 70.0, 50.0, 0.0068, 2.1, Color("#4E9A4A"))


func _add_hill(node_name: String, base_y: float, amplitude: float, frequency: float, phase: float, color: Color) -> void:
	var points := PackedVector2Array()
	var x := 0.0
	while x <= VIEW.x + 24.0:
		var wave := sin(x * frequency + phase) * 0.5 + 0.5
		points.append(Vector2(x, base_y - amplitude * wave))
		x += 24.0
	points.append(Vector2(VIEW.x + 24.0, GROUND_Y + 8.0))
	points.append(Vector2(0.0, GROUND_Y + 8.0))
	var hill := Polygon2D.new()
	hill.name = node_name
	hill.polygon = points
	hill.color = color
	add_child(hill)


func _build_trees() -> void:
	# Solo a la derecha: la zona izquierda queda libre para el panel de botones.
	for tree_x in [640.0, 735.0, 1020.0, 1100.0]:
		var tree := _make_sprite("res://assets/decor/tree.svg", 0.55)
		if tree == null:
			continue
		tree.position = Vector2(tree_x, GROUND_Y - 112.0 + 12.0)
		add_child(tree)


func _build_ground() -> void:
	var ground := Polygon2D.new()
	ground.name = "Ground"
	ground.polygon = PackedVector2Array([
		Vector2(0.0, GROUND_Y), Vector2(VIEW.x, GROUND_Y), Vector2(VIEW.x, VIEW.y), Vector2(0.0, VIEW.y)
	])
	ground.color = MenuStyle.GRASS
	add_child(ground)

	var edge := Polygon2D.new()
	edge.name = "GroundEdge"
	edge.polygon = PackedVector2Array([
		Vector2(0.0, GROUND_Y), Vector2(VIEW.x, GROUND_Y), Vector2(VIEW.x, GROUND_Y + 10.0), Vector2(0.0, GROUND_Y + 10.0)
	])
	edge.color = Color("#6DBB59")
	add_child(edge)

	var soil := Polygon2D.new()
	soil.name = "Soil"
	soil.polygon = PackedVector2Array([
		Vector2(0.0, GROUND_Y + 48.0), Vector2(VIEW.x, GROUND_Y + 48.0), Vector2(VIEW.x, VIEW.y), Vector2(0.0, VIEW.y)
	])
	soil.color = Color("#5B4630")
	add_child(soil)

	for bush_x in [700.0, 900.0, 1080.0]:
		var bush := _make_sprite("res://assets/decor/bush.svg", 0.45)
		if bush == null:
			continue
		bush.position = Vector2(bush_x, GROUND_Y - 6.0)
		add_child(bush)
		_bushes.append(bush)


func _build_runner() -> void:
	for path in ["res://assets/player/player_run_1.svg", "res://assets/player/player_run_2.svg"]:
		var texture := load(path) as Texture2D
		if texture != null:
			_run_frames.append(texture)
	if _run_frames.is_empty():
		return
	_runner = Sprite2D.new()
	_runner.name = "Runner"
	_runner.texture = _run_frames[0]
	_runner.scale = Vector2(3.0, 3.0)
	_runner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_runner.position = Vector2(850.0, GROUND_Y - 60.0)
	add_child(_runner)


func _make_texture_rect(node_name: String, path: String, rect_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = rect_size
	add_child(rect)
	return rect


func _make_sprite(path: String, sprite_scale: float) -> Sprite2D:
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	return sprite
