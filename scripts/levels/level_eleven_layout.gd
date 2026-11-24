class_name LevelElevenLayout
extends RefCounted
## Nivel 11 (2026-11-17): "VIENTO" (mundo 3, nivel 1). Una travesía de 34
## plataformas pequeñas sobre un abismo, con viento a ráfagas que cambia de
## sentido en tres tramos (en contra, a favor y en contra más fuerte). Mezcla
## los cinco tipos de plataforma, pinchos en los bordes, sierras suspendidas,
## arqueros y magos (proyectiles) y los enemigos nuevos: lanceros de patrulla
## (dos en plataformas estrechas), orbes perseguidores (uno vertical) y
## saltadores explosivos (uno de salto largo). Un control en el fortín central.

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const SPEARMAN_SCENE := preload("res://scenes/enemies/spearman_enemy.tscn")
const ORB_SCENE := preload("res://scenes/enemies/orb_enemy.tscn")
const JUMPER_SCENE := preload("res://scenes/enemies/blast_jumper_enemy.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")
const CLOUD_SCENE := preload("res://scenes/decor/cloud.tscn")

const LEVEL_WIDTH := 17000.0
const GROUND_TOP := 640.0
const PLAYER_START := Vector2(70.0, 600.0)
const START_WIDTH := 1400.0
const END_START_X := 15200.0
const PORTAL_POSITION := Vector2(16500.0, 580.0)
const ROUTE_START_X := 1700.0
const ROUTE_STEP := 400.0
const ROUTE_COUNT := 34
const PLATFORM_SIZE := Vector2(220.0, 24.0)
const BASTION_SIZE := Vector2(360.0, 24.0)
const ROUTE_Y := [550.0, 450.0, 350.0, 250.0, 350.0, 450.0]
const BASTION_PERIOD := 7
const BASTION_PHASE := 3
const CHECKPOINT_INDEX := 17
const HERB_INDICES := [7, 15, 23]
const AIR_SAW_INDICES := [5, 14, 22, 30]
const ARCHER_INDICES := [3, 8, 19, 24]
const MAGE_INDICES := [10, 11, 27, 31]
const SPEARMAN_BASTION := 3
const NARROW_SPEARMAN_INDICES := [16, 32]
const JUMPER_INDICES := [10, 31]
const LONG_JUMPER_INDEX := 31
const ORB_GAPS := [12, 20, 28]
const VERTICAL_ORB_GAP := 20
## Tramos de viento: velocidad con signo en px/s (negativo = en contra).
const WIND_SEGMENTS := [
	{"from": 1500.0, "to": 6000.0, "speed": -115.0},
	{"from": 6000.0, "to": 10500.0, "speed": 110.0},
	{"from": 10500.0, "to": 14800.0, "speed": -130.0},
]


static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelElevenGenerated"
	level.add_child(world)

	_build_sky(world)
	_build_terrain(world)
	_build_route(world)
	_build_orbs(world)
	_build_air_saws(world)
	_build_wind(world)
	_place_player(level)
	_build_finish(level)


static func route_x(index: int) -> float:
	return ROUTE_START_X + float(index) * ROUTE_STEP


static func route_y(index: int) -> float:
	return ROUTE_Y[index % ROUTE_Y.size()]


static func is_bastion(index: int) -> bool:
	return index % BASTION_PERIOD == BASTION_PHASE


static func _place_player(level: Node2D) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.global_position = PLAYER_START


static func _build_sky(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#5f7fa3"), Color("#9dbbd3"), Color("#e3eef5")])
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
	sun.set("screen_offset", Vector2(-340.0, -190.0))
	sun.modulate = Color(1.0, 0.97, 0.85, 0.85)

	var clouds := Parallax2D.new()
	clouds.name = "CloudParallax"
	clouds.scroll_scale = Vector2(0.55, 1.0)
	clouds.z_index = -8
	world.add_child(clouds)
	for i in 14:
		var cloud := _spawn(CLOUD_SCENE, clouds, Vector2(120.0 + float(i) * 700.0, 70.0 + float((i * 53) % 220)))
		cloud.scale = Vector2(1.4, 0.8)
		cloud.modulate = Color(1.0, 1.0, 1.0, 0.8)

	var hills := Parallax2D.new()
	hills.name = "MountainParallax"
	hills.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(hills)
	var base := Polygon2D.new()
	base.color = Color("#6d8aa3")
	base.polygon = PackedVector2Array([
		Vector2(-400.0, 650.0), Vector2(LEVEL_WIDTH + 400.0, 650.0),
		Vector2(LEVEL_WIDTH + 400.0, 720.0), Vector2(-400.0, 720.0),
	])
	base.z_index = -23
	hills.add_child(base)
	for i in 14:
		var peak := Polygon2D.new()
		peak.color = [Color("#7f9bb3"), Color("#8aa5bb"), Color("#6d8aa3")][i % 3]
		peak.position = Vector2(200.0 + float(i) * 640.0, 650.0)
		peak.polygon = PackedVector2Array([
			Vector2(-420, 0), Vector2(-110, -240 - float(i % 3) * 40.0), Vector2(80, -190), Vector2(340, 0),
		])
		peak.z_index = -22
		hills.add_child(peak)


static func _build_terrain(world: Node2D) -> void:
	var stone := Color("#7e8a96")
	_add_platform(world, Vector2(START_WIDTH * 0.5, 680.0), Vector2(START_WIDTH, 80.0), stone)
	var end_width := LEVEL_WIDTH - END_START_X
	_add_platform(world, Vector2(END_START_X + end_width * 0.5, 700.0), Vector2(end_width, 120.0), stone)
	var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(LEVEL_WIDTH * 0.5, 780.0))
	fall_zone.name = "FallZoneWind"
	var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
	fall_shape.size = Vector2(LEVEL_WIDTH + 800.0, 120.0)


static func _build_route(world: Node2D) -> void:
	var checkpoint_position := Vector2.ZERO
	for index in ROUTE_COUNT:
		var bastion := is_bastion(index)
		var platform := _add_platform(
			world,
			Vector2(route_x(index), route_y(index)),
			BASTION_SIZE if bastion else PLATFORM_SIZE,
			[Color("#8c98a6"), Color("#a3aebb"), Color("#76828f")][index % 3]
		)
		platform.name = "WindPlatform%d" % index
		platform.kind = _kind_for(index)
		match platform.kind:
			Platform.Kind.HORIZONTAL:
				platform.travel = Vector2(60.0, 0.0)
				platform.speed = 1.1
			Platform.Kind.CIRCULAR:
				platform.circle_radius = 45.0
				platform.circle_speed = 1.0
			Platform.Kind.ROTATING:
				platform.rotation_speed = 1.1
			Platform.Kind.SPIKED:
				platform.spike_damage = 15
		if bastion or index in NARROW_SPEARMAN_INDICES or index in HERB_INDICES or index in ARCHER_INDICES or index in MAGE_INDICES:
			platform.kind = Platform.Kind.STATIC
		_populate(world, index, platform.position, bastion)
		if index == CHECKPOINT_INDEX:
			checkpoint_position = platform.position + Vector2(0.0, -60.0)

	if checkpoint_position != Vector2.ZERO:
		_spawn(CHECKPOINT_SCENE, world, checkpoint_position)


static func _populate(world: Node2D, index: int, position: Vector2, bastion: bool) -> void:
	var top := position.y - 12.0
	if index in HERB_INDICES:
		_spawn(HERB_SCENE, world, position + Vector2(0.0, -34.0))
	if index in ARCHER_INDICES:
		var offset := 90.0 if bastion else 0.0
		var archer := _spawn(SPREAD_SCENE, world, Vector2(position.x + offset, top - 52.0))
		archer.name = "WindArcher%d" % index
	if index in MAGE_INDICES:
		var offset := -90.0 if bastion else 0.0
		var mage := _spawn(RANGED_SCENE, world, Vector2(position.x + offset, top - 54.0))
		mage.name = "WindMage%d" % index
		mage.set("shoot_range", 520.0)
	if bastion and index == SPEARMAN_BASTION:
		_spearman(world, "WindSpearman%d" % index, Vector2(position.x - 90.0, top - 30.0), false)
	if index in NARROW_SPEARMAN_INDICES:
		_spearman(world, "WindNarrowSpearman%d" % index, Vector2(position.x, top - 30.0), true)
	if index in JUMPER_INDICES:
		var jumper := JUMPER_SCENE.instantiate() as BlastJumperEnemy
		jumper.name = "WindJumper%d" % index
		jumper.long_jump = index == LONG_JUMPER_INDEX
		jumper.position = Vector2(position.x + 100.0, top - 20.0)
		world.add_child(jumper)


static func _spearman(world: Node2D, node_name: String, position: Vector2, narrow: bool) -> void:
	var spearman := SPEARMAN_SCENE.instantiate() as SpearmanEnemy
	spearman.name = node_name
	spearman.narrow = narrow
	spearman.position = position
	world.add_child(spearman)


static func _build_orbs(world: Node2D) -> void:
	for gap in ORB_GAPS:
		var orb := ORB_SCENE.instantiate() as OrbEnemy
		orb.name = "WindOrb%d" % gap
		orb.axis = OrbEnemy.Axis.VERTICAL if gap == VERTICAL_ORB_GAP else OrbEnemy.Axis.FREE
		var mid_x := (route_x(gap) + route_x(gap + 1)) * 0.5
		var mid_y := (route_y(gap) + route_y(gap + 1)) * 0.5 - 70.0
		orb.position = Vector2(mid_x, mid_y)
		world.add_child(orb)


static func _build_air_saws(world: Node2D) -> void:
	for index in AIR_SAW_INDICES:
		var y := minf(route_y(index), route_y(index + 1)) - 85.0
		var saw := SAW_SCENE.instantiate()
		saw.position = Vector2((route_x(index) + route_x(index + 1)) * 0.5, y)
		saw.set("move_range", PLATFORM_SIZE.x * 0.8)
		saw.set("move_speed", 1.2)
		saw.set("warmup_time", 0.6)
		world.add_child(saw)


static func _build_wind(world: Node2D) -> void:
	var field := WindField.new()
	field.name = "WindField"
	var segments: Array[Dictionary] = []
	for segment in WIND_SEGMENTS:
		segments.append(segment.duplicate())
	field.segments = segments
	world.add_child(field)


static func _kind_for(index: int) -> Platform.Kind:
	return [
		Platform.Kind.STATIC,
		Platform.Kind.HORIZONTAL,
		Platform.Kind.SPIKED,
		Platform.Kind.STATIC,
		Platform.Kind.CIRCULAR,
		Platform.Kind.ROTATING,
		Platform.Kind.SPIKED,
		Platform.Kind.STATIC,
	][index % 8]


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
