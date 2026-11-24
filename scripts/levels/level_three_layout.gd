class_name LevelThreeLayout
extends RefCounted
## Nivel 3: granja nocturna bajo un cielo azul oscuro. Sin árboles ni
## arbustos; walkers rápidos, magos, decoración rural y enemigos ráfaga
## comunes (antiguo jefe, ya no bloquea el portal).

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker_enemy.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")

const GROUND_Y := 680.0
const GROUND_TOP := 640.0
const LEVEL_WIDTH := 12600.0

const EXTRA_PLATFORM_SPOTS := [
	[650.0, 556.0, 190.0],
	[950.0, 460.0, 190.0],
	[1250.0, 364.0, 180.0],
	[2630.0, 460.0, 180.0],
	[2900.0, 556.0, 170.0],
	[3150.0, 556.0, 190.0],
	[3450.0, 460.0, 190.0],
	[3750.0, 364.0, 180.0],
	[5600.0, 556.0, 180.0],
	[5900.0, 460.0, 190.0],
	[6200.0, 364.0, 180.0],
	[8150.0, 556.0, 180.0],
	[8390.0, 460.0, 190.0],
	[10600.0, 556.0, 180.0],
	[10900.0, 460.0, 190.0],
]


static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelThreeGenerated"
	level.add_child(world)

	_build_sky(world)
	_build_farm_decor(world)
	_build_terrain(world)
	_build_enemies(world)
	_build_pickups(world)
	_build_checkpoints(world)
	_build_finish(level)


static func _build_sky(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color("#050b1c"),
		Color("#0a1a38"),
		Color("#123055"),
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
	sky.size = Vector2(LEVEL_WIDTH, 720.0)
	sky.z_index = -30
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	world.add_child(sky)

	# Estrellas en capa de paralaje (2026-11-11): a 0.08x la cámara casi no se
	# mueven; solo necesitan cubrir la banda visible [0, ~2200] de la capa.
	var star_parallax := Parallax2D.new()
	star_parallax.name = "StarParallax"
	star_parallax.scroll_scale = Vector2(0.08, 1.0)
	world.add_child(star_parallax)

	var rng := RandomNumberGenerator.new()
	rng.seed = 31415
	for i in 180:
		var star := _add_circle(
			star_parallax,
			Vector2(rng.randf_range(0.0, 2200.0), rng.randf_range(20.0, 430.0)),
			rng.randf_range(0.8, 2.2),
			Color(0.78, 0.9, 1.0, rng.randf_range(0.35, 0.95)),
			-28
		)
		star.name = "Star%d" % i

	# La luna a 0.02x: acompaña al jugador sin salir nunca de pantalla.
	var moon_parallax := Parallax2D.new()
	moon_parallax.name = "MoonParallax"
	moon_parallax.scroll_scale = Vector2(0.02, 1.0)
	world.add_child(moon_parallax)
	_add_circle(moon_parallax, Vector2(600.0, 110.0), 52.0, Color(0.9, 0.95, 1.0, 0.95), -27)
	_add_circle(moon_parallax, Vector2(632.0, 92.0), 48.0, Color("#0a1a38"), -26)
	# Cráteres (2026-11-11) sobre el creciente visible de la luna.
	var crater_color := Color(0.72, 0.78, 0.88, 0.9)
	_add_circle(moon_parallax, Vector2(560.0, 130.0), 5.0, crater_color, -25)
	_add_circle(moon_parallax, Vector2(555.0, 100.0), 4.0, crater_color, -25)
	_add_circle(moon_parallax, Vector2(575.0, 150.0), 3.5, crater_color, -25)

	# Colinas lejanas de la granja a 0.3x la cámara.
	var hill_parallax := Parallax2D.new()
	hill_parallax.name = "HillParallax"
	hill_parallax.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(hill_parallax)

	for i in 7:
		var hill := Polygon2D.new()
		hill.color = [Color("#0b2038"), Color("#102b49"), Color("#163757")][i % 3]
		hill.position = Vector2(400.0 + float(i) * 750.0, 650.0)
		hill.polygon = PackedVector2Array([
			Vector2(-620, 0),
			Vector2(-150, -230),
			Vector2(260, 0),
		])
		hill.z_index = -22
		hill_parallax.add_child(hill)
		MountainBuilder.decorate(
			hill,
			Color("#2a4a75"),
			hill.color.lightened(0.15),
			hill.color.darkened(0.3),
			true
		)


static func _build_farm_decor(world: Node2D) -> void:
	_add_barn(world, Vector2(1080.0, GROUND_TOP), Color("#4a2020"))
	_add_silo(world, Vector2(2350.0, GROUND_TOP), Color("#37404f"))
	_add_windmill(world, Vector2(4350.0, GROUND_TOP), Color("#3c3540"))
	_add_barn(world, Vector2(7900.0, GROUND_TOP), Color("#3f2428"))
	_add_silo(world, Vector2(10150.0, GROUND_TOP), Color("#303a48"))

	var fence_starts := [350.0, 2500.0, 4700.0, 6900.0, 9200.0, 11300.0]
	for start_x in fence_starts:
		_add_fence(world, start_x, GROUND_TOP, 7)

	var crop_rows := [1500.0, 3200.0, 6100.0, 8500.0, 10700.0]
	for x in crop_rows:
		_add_crop_row(world, x, GROUND_TOP)

	for i in 14:
		var x := 600.0 + float(i) * 820.0
		_add_hay_bale(world, Vector2(x + 220.0, GROUND_TOP - 12.0))


static func _build_terrain(world: Node2D) -> void:
	var segments := [
		[900.0, 2300.0],
		[2550.0, 400.0],
		[3610.0, 1280.0],
		[5000.0, 400.0],
		[6010.0, 1180.0],
		[7525.0, 350.0],
		[8485.0, 1130.0],
		[9750.0, 500.0],
		[11285.0, 2130.0],
	]
	for segment in segments:
		_add_platform(world, Vector2(segment[0], GROUND_Y), Vector2(segment[1], 80.0), Color("#263a2f"))

	var pit_centers := [2200.0, 2860.0, 4525.0, 5310.0, 6975.0, 7810.0, 9275.0, 10110.0]
	for pit_x in pit_centers:
		var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(pit_x, 780.0))
		fall_zone.name = "FallZone%d" % int(pit_x)

	# Espaciado 2026-11-11: alturas en niveles fijos (556/460) para que los
	# huecos con el suelo sean de >= 72 px (1.5x la altura del jugador).
	_add_platform(world, Vector2(2400.0, 556.0), Vector2(170.0, 20.0), Color("#4b5f46"))
	_add_platform(world, Vector2(4800.0, 556.0), Vector2(180.0, 20.0), Color("#4b5f46"))
	_add_platform(world, Vector2(7300.0, 556.0), Vector2(170.0, 20.0), Color("#4b5f46"))
	_add_platform(world, Vector2(9800.0, 556.0), Vector2(190.0, 20.0), Color("#4b5f46"))

	_add_platform(world, Vector2(3850.0, 460.0), Vector2(220.0, 22.0), Color("#52664b"))
	_add_platform(world, Vector2(6250.0, 460.0), Vector2(230.0, 22.0), Color("#52664b"))
	_add_platform(world, Vector2(8650.0, 460.0), Vector2(220.0, 22.0), Color("#52664b"))

	for index in EXTRA_PLATFORM_SPOTS.size():
		var data: Array = EXTRA_PLATFORM_SPOTS[index]
		var color := Color("#52664b") if index % 2 == 0 else Color("#4b5f46")
		_add_platform(
			world,
			Vector2(data[0], data[1]),
			Vector2(data[2], 20.0),
			color
		)


static func _build_enemies(world: Node2D) -> void:
	# Cambio 2026-11-11: 2150, 4450, 6850 y 9350 caian sobre pozos y los
	# walkers se precipitaban al vacio nada mas aparecer; se mueven a suelo.
	# 2026-11-13: densidad de walkers reducida (20 -> 14 en el suelo) para
	# dejar respirar al jugador sin vaciar la granja.
	var ground_spots := [
		1250.0, 1850.0, 2450.0,
		3550.0, 4150.0, 4000.0,
		6250.0, 6550.0, 7500.0,
		8450.0, 9050.0, 9700.0,
		10750.0, 11650.0,
	]
	for index in ground_spots.size():
		var walker := _spawn(WALKER_SCENE, world, Vector2(ground_spots[index], GROUND_TOP - 26.0))
		walker.set("patrol_speed", 158.0 + float(index % 4) * 14.0)
		walker.set("patrol_distance", 150.0 + float(index % 3) * 35.0)

	var platform_spots := [
		[2400.0, 556.0], [4800.0, 556.0], [7300.0, 556.0], [9800.0, 556.0],
		[3850.0, 460.0], [6250.0, 460.0], [8650.0, 460.0],
	]
	for index in platform_spots.size():
		var data: Array = platform_spots[index]
		var walker := _spawn(WALKER_SCENE, world, Vector2(data[0], data[1] - 38.0))
		walker.set("patrol_speed", 170.0 + float(index % 3) * 12.0)
		walker.set("patrol_distance", 92.0)

	for index in EXTRA_PLATFORM_SPOTS.size():
		var data: Array = EXTRA_PLATFORM_SPOTS[index]
		var walker := _spawn(WALKER_SCENE, world, Vector2(data[0], data[1] - 38.0))
		walker.set("patrol_speed", 152.0 + float(index % 4) * 9.0)
		walker.set("patrol_distance", 62.0)

	# Enemigos ráfaga comunes (antiguo jefe) repartidos entre las islas de tierra.
	for x in [2500.0, 5500.0, 8100.0, 10400.0]:
		_spawn(SPREAD_SCENE, world, Vector2(x, GROUND_TOP - 40.0))

	# Magos recuperados (2026-11-13): la granja vuelve a tener enemigos a
	# distancia clásicos, separados de los walkers y del control central.
	for x in [3300.0, 6400.0, 8800.0]:
		var ranged := _spawn(RANGED_SCENE, world, Vector2(x, GROUND_TOP - 28.0))
		ranged.set("shoot_range", 520.0)


static func _build_pickups(world: Node2D) -> void:
	for x in [3150.0, 8050.0, 11250.0]:
		_spawn(HERB_SCENE, world, Vector2(x, GROUND_TOP - 22.0))


static func _build_checkpoints(world: Node2D) -> void:
	## Un único control a mitad de la granja (2026-11-12), lejos de las patrullas.
	for x in [6000.0]:
		_spawn(CHECKPOINT_SCENE, world, Vector2(x, GROUND_TOP - 48.0))


static func _build_finish(level: Node2D) -> void:
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = Vector2(12150.0, 580.0)

	var camera := level.get_node_or_null("Camera") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(LEVEL_WIDTH)
		camera.limit_bottom = 720


static func _add_barn(world: Node2D, base: Vector2, color: Color) -> void:
	_add_rect(world, base + Vector2(-80.0, -90.0), Vector2(320.0, 180.0), color, -8)
	_add_rect(world, base + Vector2(-80.0, -198.0), Vector2(340.0, 22.0), color.lightened(0.12), -8)
	var roof := Polygon2D.new()
	roof.color = color.darkened(0.25)
	roof.position = base + Vector2(-80.0, -200.0)
	roof.polygon = PackedVector2Array([
		Vector2(-190, 0), Vector2(0, -95), Vector2(190, 0),
	])
	roof.z_index = -8
	world.add_child(roof)
	# Puerta con tablones y cruces (2026-11-11).
	_add_rect(world, base + Vector2(-80.0, -60.0), Vector2(78.0, 120.0), color.darkened(0.35), -7)
	for i in 3:
		_add_rect(
			world,
			base + Vector2(-80.0, -25.0 - float(i) * 35.0),
			Vector2(74.0, 4.0),
			color.darkened(0.5),
			-7
		)
	for angle_deg in [-38.0, 38.0]:
		var brace := _add_rect(
			world,
			base + Vector2(-80.0, -60.0),
			Vector2(126.0, 5.0),
			color.darkened(0.5),
			-7
		)
		brace.rotation = deg_to_rad(angle_deg)
	# Ventana con marco en cruz y ventanita del desván en el frontón.
	_add_rect(world, base + Vector2(20.0, -92.0), Vector2(58.0, 58.0), Color("#a8824f"), -7)
	_add_rect(world, base + Vector2(20.0, -92.0), Vector2(58.0, 5.0), Color("#5f4527"), -6)
	_add_rect(world, base + Vector2(20.0, -92.0), Vector2(5.0, 58.0), Color("#5f4527"), -6)
	_add_rect(world, base + Vector2(-80.0, -238.0), Vector2(30.0, 30.0), Color("#a8824f"), -7)
	_add_rect(world, base + Vector2(-80.0, -238.0), Vector2(30.0, 4.0), Color("#5f4527"), -6)


static func _add_silo(world: Node2D, base: Vector2, color: Color) -> void:
	_add_rect(world, base + Vector2(0.0, -110.0), Vector2(120.0, 220.0), color, -8)
	_add_circle(world, base + Vector2(0.0, -222.0), 60.0, color.lightened(0.12), -8)
	for i in 4:
		_add_rect(
			world,
			base + Vector2(0.0, -48.0 - float(i) * 46.0),
			Vector2(124.0, 5.0),
			color.lightened(0.18),
			-7
		)
	# Remate del domo, franja de luz lateral y puertita (2026-11-11).
	_add_circle(world, base + Vector2(0.0, -290.0), 7.0, color.lightened(0.2), -7)
	_add_rect(world, base + Vector2(-42.0, -110.0), Vector2(14.0, 214.0), color.lightened(0.1), -7)
	_add_rect(world, base + Vector2(0.0, -26.0), Vector2(30.0, 48.0), color.darkened(0.35), -7)


static func _add_windmill(world: Node2D, base: Vector2, color: Color) -> void:
	_add_rect(world, base + Vector2(0.0, -120.0), Vector2(96.0, 240.0), color, -8)
	var roof := Polygon2D.new()
	roof.color = color.darkened(0.25)
	roof.position = base + Vector2(0.0, -240.0)
	roof.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(0, -58), Vector2(60, 0),
	])
	roof.z_index = -8
	world.add_child(roof)
	# Puerta, ventanita y buje central (2026-11-11).
	_add_rect(world, base + Vector2(0.0, -26.0), Vector2(26.0, 48.0), color.darkened(0.35), -7)
	_add_circle(world, base + Vector2(0.0, -180.0), 9.0, Color("#a8824f"), -7)
	_add_circle(world, base + Vector2(0.0, -260.0), 10.0, color.darkened(0.4), -7)
	for i in 4:
		var blade := _add_rect(
			world,
			base + Vector2(0.0, -260.0),
			Vector2(18.0, 150.0),
			Color("#8e8069", 0.85),
			-7
		)
		blade.rotation = float(i) * PI * 0.5
		# Vela del molino: franja clara en la mitad exterior de cada aspa.
		var sail := _add_rect(
			world,
			base + Vector2(0.0, -260.0) + Vector2(0.0, -37.0).rotated(blade.rotation),
			Vector2(10.0, 72.0),
			Color("#c4b49a", 0.9),
			-6
		)
		sail.rotation = blade.rotation


static func _add_fence(world: Node2D, start_x: float, base_y: float, posts: int) -> void:
	for i in posts:
		var x := start_x + float(i) * 72.0
		_add_rect(world, Vector2(x, base_y - 28.0), Vector2(10.0, 56.0), Color("#6f5a43"), -6)
		# Remate puntiagudo del poste (2026-11-11).
		var cap := Polygon2D.new()
		cap.color = Color("#5d4a36")
		cap.position = Vector2(x, base_y - 56.0)
		cap.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -7), Vector2(6, 0),
		])
		cap.z_index = -6
		world.add_child(cap)
	for i in posts - 1:
		var x := start_x + 36.0 + float(i) * 72.0
		_add_rect(world, Vector2(x, base_y - 42.0), Vector2(72.0, 7.0), Color("#7d684d"), -6)
		_add_rect(world, Vector2(x, base_y - 20.0), Vector2(72.0, 7.0), Color("#7d684d"), -6)


static func _add_crop_row(world: Node2D, start_x: float, base_y: float) -> void:
	for i in 9:
		var x := start_x + float(i) * 46.0
		var stem := _add_rect(
			world,
			Vector2(x, base_y - 20.0),
			Vector2(5.0, 40.0),
			Color("#557341"),
			-6
		)
		stem.rotation = deg_to_rad(-6.0 + float(i % 3) * 6.0)
		_add_circle(world, Vector2(x, base_y - 43.0), 9.0, Color("#6f8f4e"), -6)
		# Espigas doradas (2026-11-11) sobre la cabeza de cada planta.
		for ear_x in [x - 4.0, x + 4.0]:
			var ear := _add_rect(
				world,
				Vector2(ear_x, base_y - 52.0),
				Vector2(3.5, 14.0),
				Color("#d8b556"),
				-6
			)
			ear.rotation = deg_to_rad(-14.0 if ear_x < x else 14.0)


static func _add_hay_bale(world: Node2D, center: Vector2) -> void:
	_add_rect(world, center, Vector2(54.0, 34.0), Color("#b08a42"), -6)
	for i in 3:
		_add_rect(
			world,
			center + Vector2(-16.0 + float(i) * 16.0, 0.0),
			Vector2(3.0, 30.0),
			Color("#8f6c31"),
			-5
		)
	# Bandas horizontales del rollo (2026-11-11).
	_add_rect(world, center + Vector2(0.0, -9.0), Vector2(50.0, 4.0), Color("#8f6c31"), -5)
	_add_rect(world, center + Vector2(0.0, 9.0), Vector2(50.0, 4.0), Color("#8f6c31"), -5)


static func _add_rect(world: Node2D, center: Vector2, size: Vector2, color: Color, z: int) -> Polygon2D:
	var rect := Polygon2D.new()
	rect.color = color
	rect.position = center
	rect.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5),
	])
	rect.z_index = z
	world.add_child(rect)
	return rect


static func _add_circle(world: Node2D, center: Vector2, radius: float, color: Color, z: int) -> Polygon2D:
	var polygon := PackedVector2Array()
	for i in 20:
		var angle := TAU * float(i) / 20.0
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	var circle := Polygon2D.new()
	circle.color = color
	circle.position = center
	circle.polygon = polygon
	circle.z_index = z
	world.add_child(circle)
	return circle


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
