class_name LevelFourLayout
extends RefCounted
## Nivel 4 (2026-11-12): "El Gran Pozo". Todo el recorrido central es vacío
## salvo el inicio y el final; se cruza por una cadena principal de
## plataformas móviles (verticales, diagonales, circulares y giratorias).
## Todas las plataformas de la ruta están activas a la vez: no se reciclan ni
## desaparecen. La separación entre huecos evita que las trayectorias se
## solapen.
##
## Regla de alcance: el hueco entre los bordes de dos plataformas
## consecutivas del tramo principal queda a menos de 300 px (MAX_REACH del
## test), de modo que siempre exista un instante en el que se pueda saltar de
## una a la siguiente. El test level_four_smoke_test.gd lo valida muestreando
## las trayectorias.

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker_enemy.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")

const GROUND_Y := 680.0
const GROUND_TOP := 640.0
const LEVEL_WIDTH := 12400.0
const PIT_START := 1900.0
const PIT_END := 10100.0
const START_CENTER := 950.0
const END_CENTER := 11250.0
const PLAYER_START := Vector2(70.0, 600.0)
const START_SAFE_X := 1100.0


static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelFourGenerated"
	level.add_child(world)

	_build_sky(world)
	_build_terrain(world)
	_place_player(level)
	_build_route(world, level)
	_build_enemies(world)
	_build_pickups(world)
	_build_checkpoints(world)
	_build_finish(level)


static func _place_player(level: Node2D) -> void:
	# 2026-11-13: el nivel 4 empieza con el jugador pegado al borde izquierdo
	# para dejar libre la mitad izquierda de la pantalla inicial.
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.global_position = PLAYER_START


static func _build_sky(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color("#120a24"),
		Color("#251340"),
		Color("#0b1b2c"),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 16
	texture.height = 256
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)

	var sky := TextureRect.new()
	sky.texture = texture
	sky.size = Vector2(LEVEL_WIDTH, 720.0)
	sky.z_index = -30
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	world.add_child(sky)

	var hill_parallax := Parallax2D.new()
	hill_parallax.name = "HillParallax"
	hill_parallax.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(hill_parallax)
	for i in 8:
		var hill := Polygon2D.new()
		hill.color = [Color("#1b1430"), Color("#241a3d"), Color("#2c2148")][i % 3]
		hill.position = Vector2(300.0 + float(i) * 780.0, 650.0)
		hill.polygon = PackedVector2Array([
			Vector2(-640, 0),
			Vector2(-140, -260),
			Vector2(300, 0),
		])
		hill.z_index = -22
		hill_parallax.add_child(hill)
		MountainBuilder.decorate(
			hill,
			Color("#6d7fb8"),
			hill.color.lightened(0.18),
			hill.color.darkened(0.3),
			true
		)

	# Rocas flotantes decorativas rellenan el vacío sin colisión.
	for rock in [
		Vector2(2600.0, 260.0), Vector2(4200.0, 320.0), Vector2(6900.0, 230.0),
		Vector2(8600.0, 300.0), Vector2(7600.0, 500.0),
	]:
		var chunk := Polygon2D.new()
		chunk.color = Color("#2a2140", 0.85)
		chunk.position = rock
		chunk.polygon = PackedVector2Array([
			Vector2(-46, 10), Vector2(-30, -20), Vector2(4, -30),
			Vector2(38, -12), Vector2(44, 14), Vector2(10, 26), Vector2(-24, 22),
		])
		chunk.z_index = -12
		world.add_child(chunk)


static func _build_terrain(world: Node2D) -> void:
	# Solo existen tres islas firmes: salida, descanso central y llegada. El
	# resto es abismo con una única zona de caída mortal que cubre el recorrido.
	_add_platform(
		world,
		Vector2(START_CENTER, GROUND_Y),
		Vector2(PIT_START, 80.0),
		Color("#2f3648")
	)
	# Isla de descanso a mitad del pozo (2026-11-12): alberga el único control
	# del nivel. Su superficie queda 30 px por debajo de la trayectoria más baja
	# de las plataformas móviles, así que no interfiere con el tramo principal.
	_add_platform(
		world,
		Vector2(6000.0, 720.0),
		Vector2(300.0, 80.0),
		Color("#2f3648")
	)
	_add_platform(
		world,
		Vector2(END_CENTER, GROUND_Y),
		Vector2(LEVEL_WIDTH - PIT_END, 80.0),
		Color("#2f3648")
	)
	var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(6000.0, 780.0))
	fall_zone.name = "FallZonePit"


static func _build_route(world: Node2D, level: Node2D) -> void:
	# 2026-11-13: todas las plataformas del tramo existen a la vez.
	var route := LevelFourRoute.new()
	route.name = "RouteStream"
	world.add_child(route)
	route.setup(level.get_node("Player") as Player)


static func _build_enemies(world: Node2D) -> void:
	# Solo hay suelo firme en la salida y la llegada. El control central queda
	# despejado; los enemigos del pozo viajan sobre las plataformas móviles.
	# La salida mantiene la mitad izquierda de la pantalla inicial sin enemigos.
	for x in [1350.0, 1700.0, 10450.0, 10700.0, 11000.0]:
		var walker := _spawn(WALKER_SCENE, world, Vector2(x, GROUND_TOP - 26.0))
		walker.set("patrol_speed", 150.0)
		walker.set("patrol_distance", 140.0)
	_spawn(SPREAD_SCENE, world, Vector2(11600.0, GROUND_TOP - 40.0))

	# Magos recuperados (2026-11-13): uno en cada isla firme, fuera de la
	# zona segura inicial y del control central.
	for x in [1200.0, 12200.0]:
		var ranged := _spawn(RANGED_SCENE, world, Vector2(x, GROUND_TOP - 28.0))
		ranged.set("shoot_range", 480.0)


static func _build_pickups(world: Node2D) -> void:
	for x in [1600.0, 12000.0]:
		_spawn(HERB_SCENE, world, Vector2(x, GROUND_TOP - 22.0))


static func _build_checkpoints(world: Node2D) -> void:
	## Un único control en la isla de descanso central (2026-11-12), justo a
	## mitad del gran pozo.
	_spawn(CHECKPOINT_SCENE, world, Vector2(6000.0, 680.0 - 48.0))


static func _build_finish(level: Node2D) -> void:
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = Vector2(12050.0, 580.0)

	var camera := level.get_node_or_null("Camera") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(LEVEL_WIDTH)
		camera.limit_bottom = 720
		camera.snap_to_target()


static func _add_platform(world: Node2D, center: Vector2, size: Vector2, color: Color) -> Platform:
	var platform: Platform = PLATFORM_SCENE.instantiate()
	platform.platform_size = size
	platform.platform_color = color
	platform.position = center
	world.add_child(platform)
	return platform


static func _spawn(scene: PackedScene, parent: Node, position: Vector2) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.position = position
	parent.add_child(node)
	return node
