class_name DesertKit
extends RefCounted
## Utilidades compartidas de los niveles del mundo 3 (2026-11-17): cielo con
## capas lejanas, suelo, plataformas del asset modular, enemigos, trampas,
## viento, rocas, murciélagos y centinela. Los niveles 12-15 solo describen
## su diseño y llaman a estas funciones, para no repetir el código base de
## los generadores anteriores (que no se tocan).

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const SPIKE_SCENE := preload("res://scenes/world/spike_trap.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const SPEARMAN_SCENE := preload("res://scenes/enemies/spearman_enemy.tscn")
const ORB_SCENE := preload("res://scenes/enemies/orb_enemy.tscn")
const JUMPER_SCENE := preload("res://scenes/enemies/blast_jumper_enemy.tscn")
const SLUG_SCENE := preload("res://scenes/enemies/slug_enemy.tscn")
const BRUTE_SCENE := preload("res://scenes/enemies/brute_enemy.tscn")
const SENTRY_SCENE := preload("res://scenes/enemies/sky_sentry.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")
const CLOUD_SCENE := preload("res://scenes/decor/cloud.tscn")

const GROUND_TOP := 640.0
const PLAYER_START := Vector2(70.0, 600.0)


static func begin(level: Node2D, node_name: String) -> Node2D:
	var world := Node2D.new()
	world.name = node_name
	level.add_child(world)
	return world


static func place_player(level: Node2D, position: Vector2 = PLAYER_START) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.global_position = position


static func finish(level: Node2D, portal_position: Vector2, width: float) -> void:
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = portal_position
	var camera := level.get_node_or_null("Camera") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(width)
		camera.limit_bottom = 720
		camera.snap_to_target()


# --- Escenario -------------------------------------------------------------

static func sky(world: Node2D, width: float, palette: Dictionary) -> void:
	## palette: top/mid/bottom (degradado), sun, cloud (Color), far_style
	## ("dunes", "pyramids" o "mesas"), far_colors (3 Color) y base (Color).
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([palette["top"], palette["mid"], palette["bottom"]])
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 16
	texture.height = 256
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.size = Vector2(width, 720.0)
	rect.z_index = -30
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	world.add_child(rect)

	var sun := spawn(SUN_SCENE, world, Vector2.ZERO)
	sun.set("screen_offset", Vector2(-340.0, -190.0))
	sun.modulate = palette["sun"]

	var clouds := Parallax2D.new()
	clouds.name = "CloudParallax"
	clouds.scroll_scale = Vector2(0.55, 1.0)
	clouds.z_index = -8
	world.add_child(clouds)
	for i in 12:
		var cloud := spawn(CLOUD_SCENE, clouds, Vector2(150.0 + float(i) * 800.0, 70.0 + float((i * 61) % 200)))
		cloud.modulate = palette["cloud"]

	var far := Parallax2D.new()
	far.name = "FarParallax"
	far.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(far)
	var base := Polygon2D.new()
	base.color = palette["base"]
	base.polygon = PackedVector2Array([
		Vector2(-400.0, 650.0), Vector2(width + 400.0, 650.0),
		Vector2(width + 400.0, 720.0), Vector2(-400.0, 720.0),
	])
	base.z_index = -23
	far.add_child(base)
	var colors: Array = palette["far_colors"]
	for i in 14:
		var shape := Polygon2D.new()
		shape.color = colors[i % colors.size()]
		shape.position = Vector2(200.0 + float(i) * 640.0, 650.0)
		shape.polygon = _far_polygon(String(palette["far_style"]), i)
		shape.z_index = -22
		far.add_child(shape)


static func _far_polygon(style: String, index: int) -> PackedVector2Array:
	match style:
		"pyramids":
			return PackedVector2Array([
				Vector2(-300, 0), Vector2(-300, -60), Vector2(-220, -60), Vector2(-220, -120),
				Vector2(-140, -120), Vector2(-140, -180), Vector2(-40, -180), Vector2(-40, -220),
				Vector2(40, -220), Vector2(40, -180), Vector2(140, -180), Vector2(140, -120),
				Vector2(220, -120), Vector2(220, -60), Vector2(300, -60), Vector2(300, 0),
			])
		"mesas":
			var height := 200.0 + float((index * 47) % 120)
			return PackedVector2Array([
				Vector2(-190, 0), Vector2(-170, -height), Vector2(-120, -height - 24.0),
				Vector2(120, -height - 24.0), Vector2(170, -height), Vector2(200, 0),
			])
	return PackedVector2Array([Vector2(-520, 0), Vector2(-120, -170.0 - float(index % 3) * 30.0), Vector2(300, 0)])


static func palms(world: Node2D, width: float, spacing: float, color: Color) -> void:
	## Palmeras decorativas de fondo (sin colisión).
	var x := 700.0
	var index := 0
	while x < width:
		var palm := Node2D.new()
		palm.position = Vector2(x, GROUND_TOP)
		palm.z_index = -14
		var height := 150.0 + float((index * 37) % 70)
		var trunk := Polygon2D.new()
		trunk.color = color.darkened(0.2)
		trunk.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(-4, -height), Vector2(4, -height), Vector2(6, 0)])
		palm.add_child(trunk)
		for leaf in 5:
			var angle := deg_to_rad(-160.0 + float(leaf) * 35.0)
			var tip := Vector2(cos(angle), sin(angle)) * 70.0 + Vector2(0.0, -height)
			var blade := Polygon2D.new()
			blade.color = color
			blade.polygon = PackedVector2Array([Vector2(0, -height), tip + Vector2(0, 10), tip + Vector2(0, -6)])
			palm.add_child(blade)
		world.add_child(palm)
		x += spacing + float((index * 131) % 300)
		index += 1


static func ground(world: Node2D, from_x: float, to_x: float, color: Color, thickness: float = 80.0) -> Platform:
	var width := to_x - from_x
	return platform(world, Vector2(from_x + width * 0.5, GROUND_TOP + thickness * 0.5), Vector2(width, thickness), color)


static func fall_zone(world: Node2D, width: float, node_name: String) -> void:
	var zone := spawn(FALL_ZONE_SCENE, world, Vector2(width * 0.5, 780.0))
	zone.name = node_name
	var shape := zone.get_node("CollisionShape2D").shape as RectangleShape2D
	shape.size = Vector2(width + 800.0, 120.0)


static func platform(world: Node2D, center: Vector2, size: Vector2, color: Color, kind: Platform.Kind = Platform.Kind.STATIC, node_name: String = "") -> Platform:
	var node: Platform = PLATFORM_SCENE.instantiate()
	node.platform_size = size
	node.platform_color = color
	node.position = center
	world.add_child(node)
	if not node_name.is_empty():
		node.name = node_name
	node.kind = kind
	match kind:
		Platform.Kind.HORIZONTAL:
			node.travel = Vector2(60.0, 0.0)
			node.speed = 1.1
		Platform.Kind.CIRCULAR:
			node.circle_radius = 45.0
			node.circle_speed = 1.0
		Platform.Kind.ROTATING:
			node.rotation_speed = 1.1
		Platform.Kind.SPIKED:
			node.spike_damage = 15
	return node


# --- Enemigos y objetos (x = centro, top = superficie donde se apoyan) -----

static func archer(world: Node2D, node_name: String, x: float, top: float) -> Node2D:
	var node := spawn(SPREAD_SCENE, world, Vector2(x, top - 52.0))
	node.name = node_name
	return node


static func mage(world: Node2D, node_name: String, x: float, top: float) -> Node2D:
	var node := spawn(RANGED_SCENE, world, Vector2(x, top - 54.0))
	node.name = node_name
	node.set("shoot_range", 520.0)
	return node


static func spearman(world: Node2D, node_name: String, x: float, top: float, narrow: bool = false) -> SpearmanEnemy:
	var node := SPEARMAN_SCENE.instantiate() as SpearmanEnemy
	node.name = node_name
	node.narrow = narrow
	node.position = Vector2(x, top - 30.0)
	world.add_child(node)
	return node


static func jumper(world: Node2D, node_name: String, x: float, top: float, long_jump: bool = false) -> BlastJumperEnemy:
	var node := JUMPER_SCENE.instantiate() as BlastJumperEnemy
	node.name = node_name
	node.long_jump = long_jump
	node.position = Vector2(x, top - 20.0)
	world.add_child(node)
	return node


static func slug(world: Node2D, node_name: String, x: float, top: float, double_jump: bool = false) -> SlugEnemy:
	var node := SLUG_SCENE.instantiate() as SlugEnemy
	node.name = node_name
	node.double_jump = double_jump
	node.position = Vector2(x, top - 18.0)
	world.add_child(node)
	return node


static func orb(world: Node2D, node_name: String, position: Vector2, vertical: bool = false) -> OrbEnemy:
	var node := ORB_SCENE.instantiate() as OrbEnemy
	node.name = node_name
	node.axis = OrbEnemy.Axis.VERTICAL if vertical else OrbEnemy.Axis.FREE
	node.position = position
	world.add_child(node)
	return node


static func brute_post(world: Node2D, node_name: String, pile_x: float, brute_x: float, top: float) -> void:
	var pile := RockPile.new()
	pile.name = "%sPile" % node_name
	pile.position = Vector2(pile_x, top)
	world.add_child(pile)
	var brute := spawn(BRUTE_SCENE, world, Vector2(brute_x, top - 32.0))
	brute.name = node_name


static func saw(world: Node2D, center: Vector2, move_range: float, speed: float) -> Node2D:
	var node := SAW_SCENE.instantiate() as Node2D
	node.position = center
	node.set("move_range", move_range)
	node.set("move_speed", speed)
	node.set("warmup_time", 0.6)
	world.add_child(node)
	return node


static func spike(world: Node2D, x: float, top: float) -> Node2D:
	return spawn(SPIKE_SCENE, world, Vector2(x, top - 8.0))


static func herb(world: Node2D, x: float, top: float) -> Node2D:
	return spawn(HERB_SCENE, world, Vector2(x, top - 34.0))


static func checkpoint(world: Node2D, x: float, top: float) -> Node2D:
	return spawn(CHECKPOINT_SCENE, world, Vector2(x, top - 48.0))


# --- Generadores del nivel -------------------------------------------------

static func wind(world: Node2D, segments_data: Array, gust_period: float = 7.0) -> WindField:
	## segments_data: [[desde_x, hasta_x, velocidad con signo], ...]
	var field := WindField.new()
	field.name = "WindField"
	field.gust_period = gust_period
	var segments: Array[Dictionary] = []
	for entry in segments_data:
		segments.append({"from": float(entry[0]), "to": float(entry[1]), "speed": float(entry[2])})
	field.segments = segments
	world.add_child(field)
	return field


static func rockfall(world: Node2D, min_x: float, max_x: float, interval: float = 2.2 / 3.0) -> RockfallSpawner:
	var spawner := RockfallSpawner.new()
	spawner.name = "RockfallSpawner"
	spawner.interval = interval
	spawner.min_x = min_x
	spawner.max_x = max_x
	world.add_child(spawner)
	return spawner


static func bats(world: Node2D, interval: float = 5.0, delay: float = 4.0) -> FlyingSpawner:
	var spawner := FlyingSpawner.new()
	spawner.name = "FlyingSpawner"
	spawner.spawn_interval = interval
	spawner.initial_delay = delay
	spawner.height_mode = FlyingSpawner.HeightMode.RANDOM
	spawner.min_height = 130.0
	spawner.max_height = 520.0
	spawner.side_margin = 40.0
	world.add_child(spawner)
	return spawner


static func sentry(world: Node2D) -> SkySentry:
	var node := SENTRY_SCENE.instantiate() as SkySentry
	node.name = "SkySentry"
	world.add_child(node)
	return node


static func spawn(scene: PackedScene, parent: Node, position: Vector2) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.position = position
	parent.add_child(node)
	return node
