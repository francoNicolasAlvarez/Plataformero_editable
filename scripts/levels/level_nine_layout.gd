class_name LevelNineLayout
extends RefCounted
## Nivel 9 (2026-11-17): "RUINAS" (mundo 2, nivel 4). Un templo en ruinas al
## atardecer: tramos de suelo de arenisca separados por fosos de 280 px, con
## escalones de piedra y un puente sobre cada foso (fijo, de vaivén o
## circular según la sección). Cada sección mezcla caminantes, pinchos,
## sierras, un arquero sobre las ruinas o un mago en el suelo; hay un control
## en la sección central y hierbas en tres de ellas.
## 2026-11-17 (más difícil): plataformas altas por sección (alturas 330 y 220),
## más arqueros y magos, murciélagos cada 5 s y rocas que caen con aviso de
## 1,5 s (RockfallSpawner) mientras el jugador cruza las ruinas.
## 2026-11-17: rocas 3 veces más frecuentes y siempre por delante del jugador;
## nuevo enemigo, el bruto lanzarrocas (BruteEnemy), junto a una pila de rocas.

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const SPIKE_SCENE := preload("res://scenes/world/spike_trap.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker_enemy.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const BRUTE_SCENE := preload("res://scenes/enemies/brute_enemy.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")
const CLOUD_SCENE := preload("res://scenes/decor/cloud.tscn")

const LEVEL_WIDTH := 15800.0
const GROUND_TOP := 640.0
const PLAYER_START := Vector2(70.0, 600.0)
const START_WIDTH := 1400.0
const SECTION_START_X := 1680.0
const SECTION_STEP := 1400.0
const SECTION_WIDTH := 1120.0
const SECTION_COUNT := 9
const FINAL_START_X := 14280.0
const PORTAL_POSITION := Vector2(15300.0, 580.0)
const TIER_LOW := 548.0
const TIER_HIGH := 440.0
const TIER_TOP := 330.0
const TIER_PEAK := 220.0
const BAT_INTERVAL := 5.0
const ROCK_INTERVAL := 2.2 / 3.0
const BRUTE_SECTIONS := [1, 4, 7]
const BRUTE_OFFSET := 700.0
const PILE_OFFSET := 585.0
const ROCKFALL_MIN_X := 1500.0
const ROCKFALL_MAX_X := 14200.0
const CHECKPOINT_SECTION := 4
const HERB_SECTIONS := [2, 5, 7]
const STONE := Color("#b08d57")
const STONE_DARK := Color("#8a6b3f")


static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelNineGenerated"
	level.add_child(world)

	_build_sky(world)
	_build_ruins_decor(world)
	_build_terrain(world)
	_build_sections(world)
	_build_hazard_spawners(world)
	_place_player(level)
	_build_finish(level)


static func section_start(index: int) -> float:
	return SECTION_START_X + float(index) * SECTION_STEP


static func _place_player(level: Node2D) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.global_position = PLAYER_START


static func _build_sky(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#5a3a52"), Color("#d98a4c"), Color("#f6d38f")])
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
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
	sun.set("screen_offset", Vector2(-330.0, -190.0))
	sun.modulate = Color(1.0, 0.85, 0.55, 0.95)

	var cloud_parallax := Parallax2D.new()
	cloud_parallax.name = "CloudParallax"
	cloud_parallax.scroll_scale = Vector2(0.55, 1.0)
	cloud_parallax.z_index = -8
	world.add_child(cloud_parallax)
	for i in 8:
		var cloud := _spawn(CLOUD_SCENE, cloud_parallax, Vector2(200.0 + float(i) * 900.0, 90.0 + float(i % 3) * 70.0))
		cloud.modulate = Color(1.0, 0.86, 0.72, 0.85)

	var dunes := Parallax2D.new()
	dunes.name = "DuneParallax"
	dunes.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(dunes)
	var dune_ground := Polygon2D.new()
	dune_ground.color = Color("#a8794a")
	dune_ground.polygon = PackedVector2Array([
		Vector2(-400.0, 650.0), Vector2(LEVEL_WIDTH + 400.0, 650.0),
		Vector2(LEVEL_WIDTH + 400.0, 720.0), Vector2(-400.0, 720.0),
	])
	dune_ground.z_index = -23
	dunes.add_child(dune_ground)
	for i in 14:
		var dune := Polygon2D.new()
		dune.color = [Color("#c08a55"), Color("#b87f4c"), Color("#a8794a")][i % 3]
		dune.position = Vector2(200.0 + float(i) * 640.0, 650.0)
		dune.polygon = PackedVector2Array([Vector2(-520, 0), Vector2(-120, -170 - float(i % 3) * 30.0), Vector2(300, 0)])
		dune.z_index = -22
		dunes.add_child(dune)


static func _build_ruins_decor(world: Node2D) -> void:
	# Columnas rotas y arcos de fondo sin colisión.
	for i in 22:
		var x := 900.0 + float(i) * 700.0
		var broken := 90.0 + float((i * 37) % 120)
		var column := Polygon2D.new()
		column.color = Color("#7a5b38", 0.85)
		column.position = Vector2(x, GROUND_TOP)
		column.polygon = PackedVector2Array([
			Vector2(-26, 0), Vector2(-22, -broken), Vector2(-10, -broken - 14),
			Vector2(6, -broken + 4), Vector2(22, -broken), Vector2(26, 0),
		])
		column.z_index = -14
		world.add_child(column)
		if i % 4 == 1:
			var arch := Polygon2D.new()
			arch.color = Color("#7a5b38", 0.7)
			arch.position = Vector2(x + 160.0, GROUND_TOP)
			arch.polygon = PackedVector2Array([
				Vector2(-30, 0), Vector2(-30, -200), Vector2(-14, -240), Vector2(14, -240),
				Vector2(30, -200), Vector2(30, 0), Vector2(14, 0), Vector2(14, -180),
				Vector2(-14, -180), Vector2(-14, 0),
			])
			arch.z_index = -14
			world.add_child(arch)


static func _build_terrain(world: Node2D) -> void:
	_add_platform(world, Vector2(START_WIDTH * 0.5, 680.0), Vector2(START_WIDTH, 80.0), STONE)
	for index in SECTION_COUNT:
		_add_platform(
			world,
			Vector2(section_start(index) + SECTION_WIDTH * 0.5, 680.0),
			Vector2(SECTION_WIDTH, 80.0),
			STONE
		)
	var final_width := LEVEL_WIDTH - FINAL_START_X
	_add_platform(world, Vector2(FINAL_START_X + final_width * 0.5, 700.0), Vector2(final_width, 120.0), STONE)
	# Una sola zona de caída cubre todos los fosos.
	var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(LEVEL_WIDTH * 0.5, 780.0))
	fall_zone.name = "FallZoneRuins"
	var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
	fall_shape.size = Vector2(LEVEL_WIDTH + 800.0, 120.0)


static func _build_sections(world: Node2D) -> void:
	for index in SECTION_COUNT:
		var x0 := section_start(index)
		# Escalones de piedra y puente sobre el foso siguiente.
		_add_platform(world, Vector2(x0 + 380.0, TIER_LOW), Vector2(240.0, 24.0), STONE_DARK)
		var step_high := _add_platform(world, Vector2(x0 + 720.0, TIER_HIGH), Vector2(240.0, 24.0), STONE_DARK)
		_add_platform(world, Vector2(x0 + 980.0, TIER_LOW), Vector2(160.0, 24.0), STONE_DARK)
		# Plataformas altas: una a 330 px (cima de la escalera) y otra a 220.
		var step_top := _add_platform(world, Vector2(x0 + 1000.0, TIER_TOP), Vector2(200.0, 24.0), STONE_DARK)
		var step_peak := _add_platform(world, Vector2(x0 + 560.0, TIER_PEAK), Vector2(180.0, 24.0), STONE_DARK)
		_build_bridge(world, index, x0 + SECTION_WIDTH + 140.0)

		match index % 3:
			0:
				_walker(world, x0 + 200.0, 118.0)
				if index > 0:
					_walker(world, x0 + 640.0, 126.0)
					_archer(world, "RuinsTopArcher%d" % index, Vector2(x0 + 1000.0, TIER_TOP - 52.0))
					_mage(world, "RuinsGroundMage%d" % index, Vector2(x0 + 900.0, GROUND_TOP - 40.0))
				_spike(world, x0 + 1000.0)
			1:
				_walker(world, x0 + 300.0, 124.0)
				_archer(world, "RuinsArcher%d" % index, Vector2(x0 + 720.0, TIER_HIGH - 52.0))
				_mage(world, "RuinsPeakMage%d" % index, Vector2(x0 + 560.0, TIER_PEAK - 54.0))
				_saw(world, Vector2(x0 + 950.0, GROUND_TOP - 30.0), 80.0, 1.6)
			2:
				_walker(world, x0 + 250.0, 130.0)
				_mage(world, "RuinsMage%d" % index, Vector2(x0 + 900.0, GROUND_TOP - 40.0))
				_archer(world, "RuinsTopArcher%d" % index, Vector2(x0 + 1000.0, TIER_TOP - 52.0))
				_spike(world, x0 + 620.0)

		if index in BRUTE_SECTIONS:
			_build_brute_post(world, index, x0)
		if index in HERB_SECTIONS:
			_spawn(HERB_SCENE, world, step_high.position + Vector2(0.0, -34.0))
		step_top.name = "RuinsTopStep%d" % index
		step_peak.name = "RuinsPeakStep%d" % index
		if index == CHECKPOINT_SECTION:
			_spawn(CHECKPOINT_SCENE, world, Vector2(x0 + 80.0, GROUND_TOP - 48.0))


static func _build_bridge(world: Node2D, index: int, center_x: float) -> void:
	var bridge := _add_platform(world, Vector2(center_x, TIER_LOW), Vector2(120.0, 24.0), STONE_DARK)
	match index % 3:
		1:
			bridge.kind = Platform.Kind.HORIZONTAL
			bridge.travel = Vector2(50.0, 0.0)
			bridge.speed = 1.2
		2:
			bridge.kind = Platform.Kind.CIRCULAR
			bridge.circle_radius = 35.0
			bridge.circle_speed = 1.1


static func _build_brute_post(world: Node2D, index: int, x0: float) -> void:
	## Bruto lanzarrocas de pie junto a una pila de rocas sobre la que se puede saltar.
	var pile := RockPile.new()
	pile.name = "RockPile%d" % index
	pile.position = Vector2(x0 + PILE_OFFSET, GROUND_TOP)
	world.add_child(pile)
	var brute := _spawn(BRUTE_SCENE, world, Vector2(x0 + BRUTE_OFFSET, GROUND_TOP - 32.0))
	brute.name = "RuinsBrute%d" % index


static func _archer(world: Node2D, node_name: String, position: Vector2) -> void:
	var archer := _spawn(SPREAD_SCENE, world, position)
	archer.name = node_name


static func _mage(world: Node2D, node_name: String, position: Vector2) -> void:
	var mage := _spawn(RANGED_SCENE, world, position)
	mage.name = node_name
	mage.set("shoot_range", 520.0)


static func _build_hazard_spawners(world: Node2D) -> void:
	# Murciélagos (volador ya existente) y rocas con aviso de 1,5 s.
	var bats := FlyingSpawner.new()
	bats.name = "FlyingSpawner"
	bats.spawn_interval = BAT_INTERVAL
	bats.initial_delay = 4.0
	bats.height_mode = FlyingSpawner.HeightMode.RANDOM
	bats.min_height = 140.0
	bats.max_height = 520.0
	world.add_child(bats)

	var rocks := RockfallSpawner.new()
	rocks.name = "RockfallSpawner"
	rocks.interval = ROCK_INTERVAL
	rocks.min_x = ROCKFALL_MIN_X
	rocks.max_x = ROCKFALL_MAX_X
	world.add_child(rocks)


static func _walker(world: Node2D, x: float, speed: float) -> void:
	var walker := _spawn(WALKER_SCENE, world, Vector2(x, GROUND_TOP - 26.0))
	walker.set("patrol_speed", speed)


static func _spike(world: Node2D, x: float) -> void:
	_spawn(SPIKE_SCENE, world, Vector2(x, GROUND_TOP - 8.0))


static func _saw(world: Node2D, center: Vector2, move_range: float, speed: float) -> void:
	var saw := SAW_SCENE.instantiate()
	saw.position = center
	saw.set("move_range", move_range)
	saw.set("move_speed", speed)
	saw.set("warmup_time", 0.6)
	world.add_child(saw)


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
