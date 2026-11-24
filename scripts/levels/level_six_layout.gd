class_name LevelSixLayout
extends RefCounted
## Nivel 6 (2026-11-13): "FORTALEZA". Plataformas separadas por saltos largos
## que obligan a usar el doble salto. Los bordes de las plataformas tienen
## pinchos (el centro queda libre) y algunas plataformas estáticas llevan
## sierras patrullando. También hay plataformas giratorias del asset modular.
## 2026-11-16: recorrido ampliado, sierras suspendidas y centinela superior.

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const SKY_SENTRY_SCENE := preload("res://scenes/enemies/sky_sentry.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")

const LEVEL_WIDTH := 18000.0
const GROUND_Y := 680.0
const GROUND_TOP := 640.0
const START_CENTER := 600.0
const END_CENTER := 16900.0
const PLAYER_START := Vector2(70.0, 600.0)
const ROUTE_START_X := 1500.0
const ROUTE_STEP := 740.0
const ROUTE_COUNT := 20
const PLATFORM_SIZE := Vector2(260.0, 24.0)
const ROUTE_Y := [550.0, 450.0]
const CHECKPOINT_INDEX := 10
const SAW_INDICES := [1, 5, 9, 14, 18]
const AIR_SAW_INDICES := [2, 6, 10, 14, 17]
const HERB_INDICES := [5, 13, 19]


static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelSixGenerated"
	level.add_child(world)

	_build_sky(world)
	_build_terrain(world)
	_place_player(level)
	_build_route(world)
	_build_air_saws(world)
	_build_sentry(world)
	_build_finish(level)


static func _place_player(level: Node2D) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.global_position = PLAYER_START


static func _build_sky(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color("#2b1024"),
		Color("#4a1828"),
		Color("#160d1d"),
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

	var moon := _spawn(SUN_SCENE, world, Vector2.ZERO)
	moon.set("screen_offset", Vector2(-360.0, -170.0))
	moon.modulate = Color(1.0, 0.55, 0.5, 0.9)
	moon.scale = Vector2.ONE * 0.75

	# Capa lejana: criatura gigante monocromática con ojo-linterna (2026-11-16).
	_build_giant_creature(world)

	var hill_parallax := Parallax2D.new()
	hill_parallax.name = "HillParallax"
	hill_parallax.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(hill_parallax)

	# Suelo de la capa de montañas: rellena hasta el borde inferior de la pantalla.
	var mountain_ground := Polygon2D.new()
	mountain_ground.color = Color("#241326")
	mountain_ground.polygon = PackedVector2Array([
		Vector2(-400.0, 650.0),
		Vector2(LEVEL_WIDTH + 400.0, 650.0),
		Vector2(LEVEL_WIDTH + 400.0, 720.0),
		Vector2(-400.0, 720.0),
	])
	mountain_ground.z_index = -23
	hill_parallax.add_child(mountain_ground)

	for i in 13:
		var hill := Polygon2D.new()
		hill.color = [Color("#321528"), Color("#431a2c"), Color("#241326")][i % 3]
		hill.position = Vector2(320.0 + float(i) * 760.0, 650.0)
		hill.polygon = PackedVector2Array([
			Vector2(-540, 0),
			Vector2(-120, -230),
			Vector2(240, 0),
		])
		hill.z_index = -22
		hill_parallax.add_child(hill)

	# Torres y columnas decorativas del fuerte.
	for i in 10:
		var tower := Polygon2D.new()
		tower.color = Color("#1d1424", 0.9)
		tower.position = Vector2(700.0 + float(i) * 1800.0, 640.0)
		tower.polygon = PackedVector2Array([
			Vector2(-44, 0), Vector2(-36, -250), Vector2(-20, -270),
			Vector2(-12, -250), Vector2(12, -250), Vector2(20, -270),
			Vector2(36, -250), Vector2(44, 0),
		])
		tower.z_index = -15
		world.add_child(tower)


static func _build_giant_creature(world: Node2D) -> void:
	var far := Parallax2D.new()
	far.name = "GiantCreatureParallax"
	far.scroll_scale = Vector2(0.05, 1.0)
	far.z_index = -28
	world.add_child(far)

	var creature := Node2D.new()
	creature.name = "GiantCreature"
	creature.position = Vector2(420.0, 80.0)
	far.add_child(creature)

	var ink := Color(0.0, 0.0, 0.0, 1.0)

	var body := Polygon2D.new()
	body.color = ink
	body.polygon = PackedVector2Array([
		Vector2(-180, 520), Vector2(-120, 260), Vector2(-40, 120),
		Vector2(40, 90), Vector2(120, 120), Vector2(180, 260), Vector2(220, 520),
	])
	creature.add_child(body)

	var arm_left := Polygon2D.new()
	arm_left.color = ink
	arm_left.polygon = PackedVector2Array([
		Vector2(-120, 220), Vector2(-80, 200), Vector2(-260, 420),
		Vector2(-520, 620), Vector2(-560, 700), Vector2(-500, 720), Vector2(-220, 470),
	])
	creature.add_child(arm_left)

	var arm_right := Polygon2D.new()
	arm_right.color = ink
	arm_right.polygon = PackedVector2Array([
		Vector2(120, 220), Vector2(80, 200), Vector2(320, 430),
		Vector2(620, 640), Vector2(660, 720), Vector2(590, 740), Vector2(270, 480),
	])
	creature.add_child(arm_right)

	var hand_left := Polygon2D.new()
	hand_left.color = ink
	hand_left.polygon = PackedVector2Array([
		Vector2(-560, 690), Vector2(-640, 760), Vector2(-700, 820),
		Vector2(-670, 860), Vector2(-600, 800), Vector2(-520, 740),
	])
	creature.add_child(hand_left)

	var hand_right := Polygon2D.new()
	hand_right.color = ink
	hand_right.polygon = PackedVector2Array([
		Vector2(660, 710), Vector2(760, 780), Vector2(820, 840),
		Vector2(780, 880), Vector2(700, 810), Vector2(600, 760),
	])
	creature.add_child(hand_right)

	var beam_outer := Polygon2D.new()
	beam_outer.color = Color(0.35, 0.75, 1.0, 0.12)
	beam_outer.polygon = PackedVector2Array([
		Vector2(30, 170), Vector2(90, 170), Vector2(320, 640), Vector2(-80, 640),
	])
	creature.add_child(beam_outer)

	var beam_inner := Polygon2D.new()
	beam_inner.color = Color(0.55, 0.9, 1.0, 0.22)
	beam_inner.polygon = PackedVector2Array([
		Vector2(42, 170), Vector2(78, 170), Vector2(220, 640), Vector2(20, 640),
	])
	creature.add_child(beam_inner)

	var eye_glow := Polygon2D.new()
	eye_glow.color = Color(0.45, 0.85, 1.0, 0.55)
	eye_glow.polygon = PackedVector2Array([
		Vector2(62, 132), Vector2(86, 146), Vector2(96, 168),
		Vector2(86, 190), Vector2(62, 204), Vector2(74, 186),
		Vector2(80, 168), Vector2(74, 150),
	])
	creature.add_child(eye_glow)

	var eye := Polygon2D.new()
	eye.color = Color(0.6, 0.95, 1.0, 0.95)
	eye.polygon = PackedVector2Array([
		Vector2(64, 140), Vector2(82, 151), Vector2(90, 168),
		Vector2(82, 185), Vector2(64, 196), Vector2(73, 182),
		Vector2(78, 168), Vector2(73, 154),
	])
	creature.add_child(eye)


static func _build_terrain(world: Node2D) -> void:
	# La superficie queda en GROUND_TOP (640) y el suelo inicial baja hasta el borde inferior.
	_add_platform(
		world,
		Vector2(START_CENTER, 680.0),
		Vector2(1200.0, 80.0),
		Color("#4a2a36")
	)
	_add_platform(
		world,
		Vector2(END_CENTER, 720.0),
		Vector2(1800.0, 160.0),
		Color("#4a2a36")
	)
	# La zona de caída cubre TODO el ancho del nivel: cualquier hueco mata.
	var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(LEVEL_WIDTH * 0.5, 780.0))
	fall_zone.name = "FallZoneFortress"
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
			[Color("#56323e"), Color("#6b3c46"), Color("#40262f")][index % 3]
		)
		platform.kind = _kind_for(index)
		if platform.kind == Platform.Kind.SPIKED:
			platform.spike_damage = 15
		elif platform.kind == Platform.Kind.ROTATING:
			platform.rotation_speed = 0.9

		if index == CHECKPOINT_INDEX:
			platform.kind = Platform.Kind.STATIC
			checkpoint_position = platform.position + Vector2(0.0, -60.0)
		if index in SAW_INDICES:
			platform.kind = Platform.Kind.STATIC
			_spawn_saw(world, platform.position + Vector2(0.0, -39.0), 70.0, 1.8)
		if index in HERB_INDICES:
			_spawn(HERB_SCENE, world, platform.position + Vector2(0.0, -34.0))

	if checkpoint_position != Vector2.ZERO:
		_spawn(CHECKPOINT_SCENE, world, checkpoint_position)


## Sierras suspendidas (2026-11-16): cruzan el hueco entre dos plataformas.
## Su trayecto completo mide el doble del ancho de una plataforma normal.
static func _build_air_saws(world: Node2D) -> void:
	for index in AIR_SAW_INDICES:
		var left_x := ROUTE_START_X + float(index) * ROUTE_STEP
		var right_x := ROUTE_START_X + float(index + 1) * ROUTE_STEP
		var left_y: float = ROUTE_Y[index % ROUTE_Y.size()]
		var right_y: float = ROUTE_Y[(index + 1) % ROUTE_Y.size()]
		var y := minf(left_y, right_y) - 90.0 - float(index % 2) * 12.0
		_spawn_saw(
			world,
			Vector2((left_x + right_x) * 0.5, y),
			PLATFORM_SIZE.x,
			1.25
		)


static func _build_sentry(world: Node2D) -> void:
	var sentry := SKY_SENTRY_SCENE.instantiate() as SkySentry
	sentry.name = "SkySentry"
	world.add_child(sentry)


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
		Platform.Kind.SPIKED,
		Platform.Kind.STATIC,
		Platform.Kind.SPIKED,
		Platform.Kind.ROTATING,
		Platform.Kind.SPIKED,
		Platform.Kind.STATIC,
	][index % 6]


static func _build_finish(level: Node2D) -> void:
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = Vector2(17400.0, 580.0)

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
