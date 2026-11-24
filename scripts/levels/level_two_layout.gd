class_name LevelTwoLayout
extends RefCounted
## Nivel 2: atardecer, fosos con plataformas móviles, sierras, pinchos y
## enemigos móviles rápidos. Incluye enemigos ráfaga comunes (antiguo jefe)
## y ya no tiene jefes ni enemigos estáticos.

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/world/moving_platform.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const SPIKE_SCENE := preload("res://scenes/world/spike_trap.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker_enemy.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const TREE_SCENE := preload("res://scenes/decor/tree.tscn")
const BUSH_SCENE := preload("res://scenes/decor/bush.tscn")
const CLOUD_SCENE := preload("res://scenes/decor/cloud.tscn")
const BIRD_SCENE := preload("res://scenes/decor/bird.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")

const GROUND_Y := 680.0
const GROUND_TOP := 640.0
const DEFAULT_WIDTH := 13400.0


static func build(level: Node2D, mirror_width: float = -1.0) -> void:
	var world := Node2D.new()
	world.name = "LevelTwoGenerated"
	level.add_child(world)

	_build_background(level, world, mirror_width)
	_build_terrain(world, mirror_width)
	_build_enemies(world, mirror_width)
	_build_checkpoints(world, mirror_width)
	_build_finish(level, mirror_width)


static func _build_checkpoints(world: Node2D, mirror_width: float) -> void:
	## Un único control a mitad del nivel (2026-11-12), sobre suelo firme.
	for x in [6700.0]:
		_spawn(CHECKPOINT_SCENE, world, _mv(Vector2(x, GROUND_TOP - 48.0), mirror_width))


static func _build_background(level: Node2D, world: Node2D, mirror_width: float) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color("#ffb347"),
		Color("#ef6a58"),
		Color("#55204f"),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 16
	texture.height = 256
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)

	var sky := TextureRect.new()
	sky.texture = texture
	sky.position = Vector2.ZERO
	var level_width := mirror_width if mirror_width >= 0.0 else DEFAULT_WIDTH
	sky.size = Vector2(level_width, 720.0)
	sky.z_index = -20
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	world.add_child(sky)

	var sun := _spawn(SUN_SCENE, world, Vector2.ZERO)
	sun.set("screen_offset", Vector2(_mx(340.0, mirror_width), -120.0))
	sun.modulate = Color(1.0, 0.78, 0.5, 1.0)
	sun.scale = Vector2.ONE * 1.15

	# Colinas en capa de paralaje (2026-11-11): viajan a 0.3x la cámara. Con
	# scroll_scale 0.3 solo se ven en la banda [0, ~4900] del espacio de la
	# capa, así que se reparten compactas en lugar de a lo largo del nivel.
	var hill_parallax := Parallax2D.new()
	hill_parallax.name = "HillParallax"
	hill_parallax.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(hill_parallax)

	for i in 6:
		var hill := Polygon2D.new()
		hill.color = [Color("#6b2d5c"), Color("#8a3b4a"), Color("#b24a3c")][i % 3]
		hill.position = _mv(Vector2(400.0 + float(i) * 1050.0, 640.0), mirror_width)
		hill.polygon = PackedVector2Array([
			Vector2(-520, 0),
			Vector2(-120, -230),
			Vector2(210, 0),
		])
		hill.z_index = -14
		hill_parallax.add_child(hill)
		MountainBuilder.decorate(
			hill,
			Color("#f2c9a0"),
			hill.color.lightened(0.12),
			hill.color.darkened(0.25),
			true
		)

	# Nubes en su propia capa, a 0.55x la cámara y por detrás del terreno.
	var cloud_parallax := Parallax2D.new()
	cloud_parallax.name = "CloudParallax"
	cloud_parallax.scroll_scale = Vector2(0.55, 1.0)
	cloud_parallax.z_index = -8
	world.add_child(cloud_parallax)

	for i in 8:
		var cloud := _spawn(CLOUD_SCENE, cloud_parallax, _mv(Vector2(250.0 + float(i) * 1150.0, 90.0 + float(i % 3) * 45.0), mirror_width))
		cloud.modulate = Color(1.0, 0.68, 0.55, 0.42)
		(cloud.get_node("Sprite2D") as Sprite2D).scale = Vector2.ONE * (0.7 + float(i % 3) * 0.15)

	var trees := [900.0, 3900.0, 6300.0, 8600.0, 10800.0]
	for x in trees:
		var tree := _spawn(TREE_SCENE, world, _mv(Vector2(x, GROUND_TOP), mirror_width))
		tree.modulate = Color(0.48, 0.26, 0.3, 1.0)
		tree.scale = Vector2(0.8, 0.85)

		var bird := _spawn(BIRD_SCENE, world, _mv(Vector2(x + 24.0, GROUND_TOP - 146.0), mirror_width))
		bird.modulate = Color(0.62, 0.42, 0.46, 1.0)
		bird.scale = Vector2.ONE * 0.9

	for i in 12:
		var bush := _spawn(BUSH_SCENE, world, _mv(Vector2(300.0 + float(i) * 1050.0, GROUND_TOP), mirror_width))
		bush.modulate = Color(0.6, 0.34, 0.3, 1.0)
		bush.scale = Vector2(0.8, 0.7)


static func _build_terrain(world: Node2D, mirror_width: float) -> void:
	var ground_color := Color("#5a3a35")
	var segments := [
		[1100.0, 2200.0],
		[2750.0, 300.0],
		[3860.0, 1480.0],
		[5250.0, 300.0],
		[6310.0, 1380.0],
		[7650.0, 300.0],
		[8710.0, 1380.0],
		[10050.0, 300.0],
		[11010.0, 1180.0],
		[12400.0, 1600.0],
	]
	for segment in segments:
		_add_platform(world, _mv(Vector2(segment[0], GROUND_Y), mirror_width), Vector2(segment[1], 80.0), ground_color)

	var pit_centers := [2400.0, 4850.0, 7250.0, 9650.0]
	for pit_x in pit_centers:
		# Altura 2026-11-11: dejaba solo ~29 px de hueco respecto al suelo,
		# menos que el jugador; a 556 queda un hueco de ~73 px.
		var moving := _spawn(MOVING_PLATFORM_SCENE, world, _mv(Vector2(pit_x - 110.0, 556.0), mirror_width))
		var travel_x := 220.0 if mirror_width < 0.0 else -220.0
		moving.set("travel", Vector2(travel_x, 0.0))
		moving.set("speed", 0.9)

	for pit_x in [3010.0, 5510.0, 7910.0, 10310.0]:
		var fall_zone := _spawn(FALL_ZONE_SCENE, world, _mv(Vector2(pit_x, 780.0), mirror_width))
		fall_zone.name = "FallZone%d" % int(pit_x)

	var saw_positions := [1450.0, 3050.0, 4300.0, 5650.0, 6750.0, 7900.0, 8950.0, 10250.0, 11250.0, 12150.0]
	for x in saw_positions:
		var saw := _spawn(SAW_SCENE, world, _mv(Vector2(x, 608.0), mirror_width))
		saw.set("move_range", 120.0)
		saw.set("move_speed", 1.5 + float(int(x) % 3) * 0.15)

	# Los pinchos sueltos solo van sobre suelo firme (2026-11-16). 5450 caía
	# dentro de un pozo; se mueve a la isla de tierra que empieza en 5620.
	var spike_positions := [1750.0, 3300.0, 5800.0, 8050.0, 10500.0]
	for x in spike_positions:
		_spawn(SPIKE_SCENE, world, _mv(Vector2(x, GROUND_TOP - 8.0), mirror_width))

	var section_starts := [200.0, 2700.0, 5200.0, 7600.0, 10000.0]
	for index in section_starts.size():
		var start_x: float = section_starts[index]
		# Espaciado 2026-11-11: escalera de peldanos separados >= 45 px en
		# horizontal y >= 72 px en vertical (1.5x el tamano del jugador).
		var base_y := 510.0
		_add_platform(world, _mv(Vector2(start_x + 375.0, base_y), mirror_width), Vector2(230.0, 24.0), Color("#7a4a3c"))
		_add_platform(world, _mv(Vector2(start_x + 655.0, base_y - 96.0), mirror_width), Vector2(220.0, 24.0), Color("#8d5a42"))
		_add_platform(world, _mv(Vector2(start_x + 925.0, base_y - 192.0), mirror_width), Vector2(220.0, 24.0), Color("#a46648"))
		_add_platform(world, _mv(Vector2(start_x + 1195.0, base_y - 288.0), mirror_width), Vector2(200.0, 24.0), Color("#8a563f"))
		_add_platform(world, _mv(Vector2(start_x + 1465.0, base_y - 384.0), mirror_width), Vector2(180.0, 24.0), Color("#9c6447"))
		_add_platform(world, _mv(Vector2(start_x + 1735.0, base_y - 288.0), mirror_width), Vector2(180.0, 24.0), Color("#ad7450"))

	var fall_zone := _spawn(FALL_ZONE_SCENE, world, _mv(Vector2(6600.0, 780.0), mirror_width))
	fall_zone.name = "FallZone"


static func _build_enemies(world: Node2D, mirror_width: float) -> void:
	var section_starts := [200.0, 2700.0, 5200.0, 7600.0, 10000.0]
	for index in section_starts.size():
		var start_x: float = section_starts[index]
		var base_y := 510.0

		var walk_offsets := [560.0, 1420.0]
		if index == 0:
			# Sin walker junto a la salida (2026-11-12): el de 560 llegaba al
			# jugador antes de que pudiera reaccionar.
			walk_offsets = [1420.0]
		for offset in walk_offsets:
			var walker := _spawn(WALKER_SCENE, world, _mv(Vector2(start_x + offset, GROUND_TOP - 26.0), mirror_width))
			walker.set("patrol_speed", 132.0)
			walker.set("patrol_distance", 240.0)

		var ranged := _spawn(RANGED_SCENE, world, _mv(Vector2(start_x + 655.0, base_y - 132.0), mirror_width))
		ranged.set("shoot_range", 520.0)

		# Enemigo ráfaga común (antiguo jefe) al final de cada tramo, en tierra.
		_spawn(SPREAD_SCENE, world, _mv(Vector2(start_x + 1750.0, GROUND_TOP - 40.0), mirror_width))

		var low_walker := _spawn(WALKER_SCENE, world, _mv(Vector2(start_x + 375.0, base_y - 38.0), mirror_width))
		low_walker.set("patrol_speed", 116.0 + float(index % 3) * 8.0)
		low_walker.set("patrol_distance", 72.0)
		var high_walker := _spawn(WALKER_SCENE, world, _mv(Vector2(start_x + 1195.0, base_y - 326.0), mirror_width))
		high_walker.set("patrol_speed", 124.0 + float(index % 2) * 10.0)
		high_walker.set("patrol_distance", 62.0)

		_spawn(HERB_SCENE, world, _mv(Vector2(start_x + 1250.0, GROUND_TOP - 22.0), mirror_width))

	_spawn(HERB_SCENE, world, _mv(Vector2(12200.0, GROUND_TOP - 22.0), mirror_width))
	_add_platform(world, _mv(Vector2(12050.0, 520.0), mirror_width), Vector2(220.0, 24.0), Color("#8d5a42"))
	_add_platform(world, _mv(Vector2(12900.0, 520.0), mirror_width), Vector2(220.0, 24.0), Color("#a46648"))
	var final_walker := _spawn(WALKER_SCENE, world, _mv(Vector2(12600.0, GROUND_TOP - 26.0), mirror_width))
	final_walker.set("patrol_speed", 150.0)
	final_walker.set("patrol_distance", 380.0)


static func _build_finish(level: Node2D, mirror_width: float) -> void:
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = _mv(Vector2(12950.0, 580.0), mirror_width)

	var camera := level.get_node_or_null("Camera") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(mirror_width if mirror_width >= 0.0 else DEFAULT_WIDTH)
		camera.limit_bottom = 720

static func _mx(x: float, mirror_width: float) -> float:
	## Espejo horizontal (nivel 8): x' = ancho - x. Con ancho negativo se
	## conserva el comportamiento original del nivel 2.
	return x if mirror_width < 0.0 else mirror_width - x


static func _mv(position: Vector2, mirror_width: float) -> Vector2:
	return Vector2(_mx(position.x, mirror_width), position.y)


static func _add_platform(world: Node2D, center: Vector2, size: Vector2, color: Color) -> void:
	var platform: Platform = PLATFORM_SCENE.instantiate()
	platform.platform_size = size
	platform.platform_color = color
	platform.position = center
	world.add_child(platform)


static func _spawn(scene: PackedScene, parent: Node, position: Vector2) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.position = position
	parent.add_child(node)
	return node
