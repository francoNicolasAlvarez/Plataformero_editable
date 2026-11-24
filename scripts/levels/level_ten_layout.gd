class_name LevelTenLayout
extends RefCounted
## Nivel 10 (2026-11-17): "TEMPLO" (mundo 2, nivel 5, final del mundo). Una
## ascensión zigzagueante por cuatro alturas sobre un abismo cubierto por una
## única zona de caída. La ruta combina los cinco tipos del asset modular de
## plataformas y añade altares anchos con un arquero o un mago, sierras
## suspendidas y murciélagos (FlyingSpawner cada 4 s). Un control a mitad de
## camino y hierbas en tres altares.
## 2026-11-17 (más difícil, como el nivel 9): plataformas altas a 150 px sobre
## los huecos de los altares, más arqueros y magos, rocas que caen por delante
## del jugador con aviso de 1,5 s (3 veces más frecuentes), dos brutos
## lanzarrocas con su pila y la babosa saltarina (normal y de doble salto).

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const BRUTE_SCENE := preload("res://scenes/enemies/brute_enemy.tscn")
const SLUG_SCENE := preload("res://scenes/enemies/slug_enemy.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")

const LEVEL_WIDTH := 16600.0
const GROUND_TOP := 640.0
const PLAYER_START := Vector2(70.0, 600.0)
const START_WIDTH := 1400.0
const END_START_X := 14800.0
const PORTAL_POSITION := Vector2(16000.0, 580.0)
const ROUTE_START_X := 1700.0
const ROUTE_STEP := 560.0
const ROUTE_COUNT := 24
const PLATFORM_SIZE := Vector2(240.0, 24.0)
const ALTAR_SIZE := Vector2(420.0, 24.0)
const ROUTE_Y := [550.0, 450.0, 350.0, 250.0, 350.0, 450.0, 550.0, 450.0, 350.0, 250.0, 350.0, 450.0]
const CHECKPOINT_INDEX := 12
const HERB_INDICES := [6, 18, 21]
const AIR_SAW_INDICES := [5, 11, 17, 22]
const ALTAR_PHASE := 3
const ALTAR_PERIOD := 6
const SKY_TIER := 150.0
const SKY_SIZE := Vector2(120.0, 24.0)
const SKY_STEP_INDICES := [3, 9, 15, 21]
const SKY_STEP_DX := 325.0
const MAGE_INDICES := [6, 18]
const BRUTE_ALTAR_NUMBER := 2
const ROCK_INTERVAL := 2.2 / 3.0
const ROCKFALL_MIN_X := 1700.0
const ROCKFALL_MAX_X := 14600.0
const END_PILE_X := 15200.0
const END_BRUTE_X := 15340.0
const END_SLUG_X := [15000.0, 15600.0]


static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelTenGenerated"
	level.add_child(world)

	_build_sky(world)
	_build_temple_decor(world)
	_build_terrain(world)
	_build_route(world)
	_build_sky_steps(world)
	_build_end_island_guards(world)
	_build_air_saws(world)
	_build_spawner(world)
	_place_player(level)
	_build_finish(level)


static func route_x(index: int) -> float:
	return ROUTE_START_X + float(index) * ROUTE_STEP


static func route_y(index: int) -> float:
	return ROUTE_Y[index % ROUTE_Y.size()]


static func is_altar(index: int) -> bool:
	return index % ALTAR_PERIOD == ALTAR_PHASE


static func _place_player(level: Node2D) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.global_position = PLAYER_START


static func _build_sky(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#170d2b"), Color("#3a2358"), Color("#8a4660")])
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

	var moon := _spawn(SUN_SCENE, world, Vector2.ZERO)
	moon.set("screen_offset", Vector2(-340.0, -180.0))
	moon.modulate = Color(1.0, 0.9, 0.55, 0.9)
	moon.scale = Vector2.ONE * 0.8

	var far := Parallax2D.new()
	far.name = "TempleParallax"
	far.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(far)
	var base := Polygon2D.new()
	base.color = Color("#241838")
	base.polygon = PackedVector2Array([
		Vector2(-400.0, 650.0), Vector2(LEVEL_WIDTH + 400.0, 650.0),
		Vector2(LEVEL_WIDTH + 400.0, 720.0), Vector2(-400.0, 720.0),
	])
	base.z_index = -23
	far.add_child(base)
	for i in 14:
		# Pirámides escalonadas lejanas.
		var pyramid := Polygon2D.new()
		pyramid.color = [Color("#2e2046"), Color("#3a2858"), Color("#281a3e")][i % 3]
		pyramid.position = Vector2(200.0 + float(i) * 640.0, 650.0)
		pyramid.polygon = PackedVector2Array([
			Vector2(-300, 0), Vector2(-300, -60), Vector2(-220, -60), Vector2(-220, -120),
			Vector2(-140, -120), Vector2(-140, -180), Vector2(-40, -180), Vector2(-40, -220),
			Vector2(40, -220), Vector2(40, -180), Vector2(140, -180), Vector2(140, -120),
			Vector2(220, -120), Vector2(220, -60), Vector2(300, -60), Vector2(300, 0),
		])
		pyramid.z_index = -22
		far.add_child(pyramid)


static func _build_temple_decor(world: Node2D) -> void:
	for i in 26:
		var column := Polygon2D.new()
		column.color = Color("#1c1230", 0.9)
		column.position = Vector2(600.0 + float(i) * 650.0, 650.0)
		var height := 260.0 + float((i * 53) % 140)
		column.polygon = PackedVector2Array([
			Vector2(-34, 0), Vector2(-26, -height), Vector2(-40, -height - 18),
			Vector2(40, -height - 18), Vector2(26, -height), Vector2(34, 0),
		])
		column.z_index = -15
		world.add_child(column)


static func _build_terrain(world: Node2D) -> void:
	_add_platform(world, Vector2(START_WIDTH * 0.5, 680.0), Vector2(START_WIDTH, 80.0), Color("#5a4668"))
	var end_width := LEVEL_WIDTH - END_START_X
	_add_platform(world, Vector2(END_START_X + end_width * 0.5, 700.0), Vector2(end_width, 120.0), Color("#5a4668"))
	var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(LEVEL_WIDTH * 0.5, 780.0))
	fall_zone.name = "FallZoneTemple"
	var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
	fall_shape.size = Vector2(LEVEL_WIDTH + 800.0, 120.0)


static func _build_route(world: Node2D) -> void:
	var checkpoint_position := Vector2.ZERO
	var altar_count := 0
	for index in ROUTE_COUNT:
		var altar := is_altar(index)
		var size := ALTAR_SIZE if altar else PLATFORM_SIZE
		var platform := _add_platform(
			world,
			Vector2(route_x(index), route_y(index)),
			size,
			[Color("#6c5380"), Color("#816799"), Color("#54406a")][index % 3]
		)
		platform.kind = _kind_for(index)
		if platform.kind == Platform.Kind.HORIZONTAL:
			platform.travel = Vector2(70.0, 0.0)
			platform.speed = 1.1
		elif platform.kind == Platform.Kind.CIRCULAR:
			platform.circle_radius = 50.0
			platform.circle_speed = 1.0
		elif platform.kind == Platform.Kind.ROTATING:
			platform.rotation_speed = 1.1
		elif platform.kind == Platform.Kind.SPIKED:
			platform.spike_damage = 15

		if altar:
			altar_count += 1
			if index not in HERB_INDICES:
				_spawn_altar_enemy(world, platform.position, altar_count)
		if index in MAGE_INDICES:
			_mage(world, "TempleRouteMage%d" % index, platform.position + Vector2(0.0, -54.0))
		if index == CHECKPOINT_INDEX:
			platform.kind = Platform.Kind.STATIC
			checkpoint_position = platform.position + Vector2(0.0, -60.0)
		if index in HERB_INDICES:
			_spawn(HERB_SCENE, world, platform.position + Vector2(0.0, -34.0))

	if checkpoint_position != Vector2.ZERO:
		_spawn(CHECKPOINT_SCENE, world, checkpoint_position)


static func _spawn_altar_enemy(world: Node2D, platform_position: Vector2, altar_number: int) -> void:
	## Altar 1: arquero y babosa; altar 2: bruto con su pila de rocas; altar 3:
	## arquero y babosa de doble salto.
	var top := platform_position.y - 12.0
	if altar_number == BRUTE_ALTAR_NUMBER:
		_brute_post(world, "TempleBrute%d" % altar_number, Vector2(platform_position.x - 70.0, top), Vector2(platform_position.x + 110.0, top - 32.0))
		return
	var archer := _spawn(SPREAD_SCENE, world, Vector2(platform_position.x + 60.0, top - 40.0))
	archer.name = "TempleArcher%d" % altar_number
	_slug(world, "TempleSlug%d" % altar_number, Vector2(platform_position.x - 100.0, top - 18.0), altar_number == 3)


static func _build_sky_steps(world: Node2D) -> void:
	## Plataformas altas (150 px) sobre el hueco que sigue a cada altar de la
	## cima, con un arquero en cada una.
	for index in SKY_STEP_INDICES:
		var step := _add_platform(world, Vector2(route_x(index) + SKY_STEP_DX, SKY_TIER), SKY_SIZE, Color("#9a7fb3"))
		step.name = "TempleSkyStep%d" % index
		var archer := _spawn(SPREAD_SCENE, world, step.position + Vector2(0.0, -52.0))
		archer.name = "TempleSkyArcher%d" % index


static func _build_end_island_guards(world: Node2D) -> void:
	# Guardián final: un bruto con su pila y dos babosas en la isla del portal.
	_brute_post(world, "TempleEndBrute", Vector2(END_PILE_X, GROUND_TOP), Vector2(END_BRUTE_X, GROUND_TOP - 32.0))
	_slug(world, "TempleEndSlug1", Vector2(END_SLUG_X[0], GROUND_TOP - 16.0), false)
	_slug(world, "TempleEndSlug2", Vector2(END_SLUG_X[1], GROUND_TOP - 16.0), true)


static func _brute_post(world: Node2D, node_name: String, pile_position: Vector2, brute_position: Vector2) -> void:
	var pile := RockPile.new()
	pile.name = "%sPile" % node_name
	pile.position = pile_position
	world.add_child(pile)
	var brute := _spawn(BRUTE_SCENE, world, brute_position)
	brute.name = node_name


static func _slug(world: Node2D, node_name: String, position: Vector2, double: bool) -> void:
	var slug := SLUG_SCENE.instantiate() as SlugEnemy
	slug.name = node_name
	slug.double_jump = double
	slug.position = position
	world.add_child(slug)


static func _mage(world: Node2D, node_name: String, position: Vector2) -> void:
	var mage := _spawn(RANGED_SCENE, world, position)
	mage.name = node_name
	mage.set("shoot_range", 520.0)


static func _build_air_saws(world: Node2D) -> void:
	for index in AIR_SAW_INDICES:
		var y := minf(route_y(index), route_y(index + 1)) - 85.0 - float(index % 2) * 10.0
		var saw := SAW_SCENE.instantiate()
		saw.position = Vector2((route_x(index) + route_x(index + 1)) * 0.5, y)
		saw.set("move_range", PLATFORM_SIZE.x)
		saw.set("move_speed", 1.2)
		saw.set("warmup_time", 0.6)
		world.add_child(saw)


static func _kind_for(index: int) -> Platform.Kind:
	return [
		Platform.Kind.STATIC,
		Platform.Kind.HORIZONTAL,
		Platform.Kind.SPIKED,
		Platform.Kind.STATIC,
		Platform.Kind.CIRCULAR,
		Platform.Kind.ROTATING,
	][index % 6]


static func _build_spawner(world: Node2D) -> void:
	var spawner := FlyingSpawner.new()
	spawner.name = "FlyingSpawner"
	spawner.spawn_interval = 4.0
	spawner.initial_delay = 3.0
	spawner.height_mode = FlyingSpawner.HeightMode.RANDOM
	spawner.min_height = 120.0
	spawner.max_height = 540.0
	spawner.side_margin = 40.0
	world.add_child(spawner)

	var rocks := RockfallSpawner.new()
	rocks.name = "RockfallSpawner"
	rocks.interval = ROCK_INTERVAL
	rocks.min_x = ROCKFALL_MIN_X
	rocks.max_x = ROCKFALL_MAX_X
	world.add_child(rocks)


static func _build_finish(level: Node2D) -> void:
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = PORTAL_POSITION
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
