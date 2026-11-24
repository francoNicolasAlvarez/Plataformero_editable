class_name LevelFiveLayout
extends RefCounted
## Nivel 5 (2026-11-13): "CIELO". Un recorrido aéreo con muchas plataformas
## separadas entre sí. Se usan los cinco tipos del asset modular: estáticas,
## vaivén horizontal, órbitas circulares, pinchos en los bordes y giro sobre
## el eje. El único enemigo es el volador: FlyingSpawner crea uno cada 4 s a
## una altura aleatoria y el enemigo cruza la pantalla ondulando.
## 2026-11-16: recorrido ampliado y sierras suspendidas sobre los huecos.

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const CLOUD_SCENE := preload("res://scenes/decor/cloud.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")

const LEVEL_WIDTH := 17000.0
const GROUND_Y := 680.0
const GROUND_TOP := 640.0
const START_CENTER := 600.0
const END_CENTER := 15800.0
const PLAYER_START := Vector2(70.0, 600.0)
const ROUTE_START_X := 1500.0
const ROUTE_STEP := 480.0
const ROUTE_COUNT := 28
const PLATFORM_SIZE := Vector2(190.0, 24.0)
const ROUTE_Y := [550.0, 450.0, 350.0]
const CHECKPOINT_INDEX := 13
const HERB_INDICES := [5, 18, 24]
const AIR_SAW_INDICES := [4, 10, 17, 23]


static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelFiveGenerated"
	level.add_child(world)

	_build_sky(world)
	_build_terrain(world)
	_place_player(level)
	_build_route(world)
	_build_air_saws(world)
	_build_spawner(world)
	_build_finish(level)


static func _place_player(level: Node2D) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.global_position = PLAYER_START


static func _build_sky(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color("#7fd8ff"),
		Color("#4fa7e8"),
		Color("#1c4d8f"),
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

	var sun := _spawn(SUN_SCENE, world, Vector2.ZERO)
	sun.set("screen_offset", Vector2(380.0, -160.0))
	sun.modulate = Color(1.0, 0.93, 0.68, 1.0)
	sun.scale = Vector2.ONE * 0.9

	var hill_parallax := Parallax2D.new()
	hill_parallax.name = "HillParallax"
	hill_parallax.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(hill_parallax)
	for i in 12:
		var hill := Polygon2D.new()
		hill.color = [Color("#6aa9c9"), Color("#4d8eb5"), Color("#39779f")][i % 3]
		hill.position = Vector2(380.0 + float(i) * 880.0, 640.0)
		hill.polygon = PackedVector2Array([
			Vector2(-620, 0),
			Vector2(-150, -210),
			Vector2(280, 0),
		])
		hill.z_index = -22
		hill_parallax.add_child(hill)

	var cloud_parallax := Parallax2D.new()
	cloud_parallax.name = "CloudParallax"
	cloud_parallax.scroll_scale = Vector2(0.55, 1.0)
	world.add_child(cloud_parallax)
	for i in 16:
		var cloud := _spawn(CLOUD_SCENE, cloud_parallax, Vector2(
			280.0 + float(i) * 420.0,
			80.0 + float(i % 4) * 74.0
		))
		cloud.scale = Vector2.ONE * (0.8 + float(i % 3) * 0.18)

	# Islas flotantes decorativas: rellenan el vacío sin colisión.
	for rock in [
		Vector2(2400.0, 250.0), Vector2(4100.0, 310.0),
		Vector2(6900.0, 220.0), Vector2(8800.0, 300.0),
		Vector2(10900.0, 260.0), Vector2(12800.0, 280.0),
		Vector2(14500.0, 240.0), Vector2(15800.0, 320.0),
	]:
		var chunk := Polygon2D.new()
		chunk.color = Color("#2c6a8e", 0.9)
		chunk.position = rock
		chunk.polygon = PackedVector2Array([
			Vector2(-58, 8), Vector2(-34, -22), Vector2(4, -30),
			Vector2(44, -16), Vector2(52, 10), Vector2(10, 26), Vector2(-30, 22),
		])
		chunk.z_index = -12
		world.add_child(chunk)


static func _build_terrain(world: Node2D) -> void:
	_add_platform(
		world,
		Vector2(START_CENTER, GROUND_Y),
		Vector2(1200.0, 80.0),
		Color("#4b6f8f")
	)
	_add_platform(
		world,
		Vector2(END_CENTER, GROUND_Y),
		Vector2(2200.0, 80.0),
		Color("#4b6f8f")
	)
	# La zona de caída cubre TODO el ancho del nivel: cualquier hueco mata.
	var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(LEVEL_WIDTH * 0.5, 780.0))
	fall_zone.name = "FallZoneSky"
	var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
	fall_shape.size = Vector2(LEVEL_WIDTH + 800.0, 120.0)


static func _build_route(world: Node2D) -> void:
	var checkpoint_position := Vector2.ZERO
	for index in ROUTE_COUNT:
		var x := ROUTE_START_X + float(index) * ROUTE_STEP
		var y: float = ROUTE_Y[index % ROUTE_Y.size()]
		var platform := _add_platform(
			world,
			Vector2(x, y),
			PLATFORM_SIZE,
			[Color("#355070"), Color("#4a6285"), Color("#2c4868")][index % 3]
		)
		platform.kind = _kind_for(index)
		if platform.kind == Platform.Kind.HORIZONTAL:
			platform.travel = Vector2(70.0, 0.0)
			platform.speed = 1.1
		elif platform.kind == Platform.Kind.CIRCULAR:
			platform.circle_radius = 50.0
			platform.circle_speed = 1.0
		elif platform.kind == Platform.Kind.ROTATING:
			platform.rotation_speed = 1.2
		elif platform.kind == Platform.Kind.SPIKED:
			platform.spike_damage = 15

		if index == CHECKPOINT_INDEX:
			platform.kind = Platform.Kind.STATIC
			checkpoint_position = platform.position + Vector2(0.0, -60.0)
		elif index in HERB_INDICES:
			_spawn(HERB_SCENE, world, platform.position + Vector2(0.0, -34.0))

	if checkpoint_position != Vector2.ZERO:
		_spawn(CHECKPOINT_SCENE, world, checkpoint_position)


## Sierras suspendidas (2026-11-16): patrullan el hueco entre dos plataformas.
## El recorrido completo mide el doble del ancho de una plataforma normal.
static func _build_air_saws(world: Node2D) -> void:
	for index in AIR_SAW_INDICES:
		var left_x := ROUTE_START_X + float(index) * ROUTE_STEP
		var right_x := ROUTE_START_X + float(index + 1) * ROUTE_STEP
		var left_y: float = ROUTE_Y[index % ROUTE_Y.size()]
		var right_y: float = ROUTE_Y[(index + 1) % ROUTE_Y.size()]
		var y := minf(left_y, right_y) - 80.0 - float(index % 2) * 10.0
		_spawn_saw(
			world,
			Vector2((left_x + right_x) * 0.5, y),
			PLATFORM_SIZE.x,
			1.15
		)


static func _spawn_saw(world: Node2D, center: Vector2, move_range: float, speed: float) -> Node2D:
	var saw := SAW_SCENE.instantiate()
	saw.position = center
	saw.set("move_range", move_range)
	saw.set("move_speed", speed)
	saw.set("warmup_time", 0.6)
	world.add_child(saw)
	return saw


static func _kind_for(index: int) -> Platform.Kind:
	return [
		Platform.Kind.STATIC,
		Platform.Kind.HORIZONTAL,
		Platform.Kind.SPIKED,
		Platform.Kind.CIRCULAR,
		Platform.Kind.ROTATING,
		Platform.Kind.SPIKED,
	][index % 6]


static func _build_spawner(world: Node2D) -> void:
	var spawner := FlyingSpawner.new()
	spawner.name = "FlyingSpawner"
	spawner.spawn_interval = 3.0
	spawner.initial_delay = 1.5
	spawner.height_mode = FlyingSpawner.HeightMode.RANDOM
	spawner.min_height = 110.0
	spawner.max_height = 560.0
	spawner.side_margin = 40.0
	world.add_child(spawner)


static func _build_finish(level: Node2D) -> void:
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = Vector2(16400.0, 580.0)

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
