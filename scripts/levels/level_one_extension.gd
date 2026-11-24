extends Node2D
## Extiende el nivel 1 hasta convertirlo en un recorrido largo con varias
## alturas, enemigos sobre plataformas y decoración de día.
## Desde el cambio de 2026-11 incluye enemigos ráfaga (antiguo jefe)
## repartidos por el recorrido como enemigos comunes.

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker_enemy.tscn")
const RANGED_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const TREE_SCENE := preload("res://scenes/decor/tree.tscn")
const BUSH_SCENE := preload("res://scenes/decor/bush.tscn")
const CLOUD_SCENE := preload("res://scenes/decor/cloud.tscn")
const BIRD_SCENE := preload("res://scenes/decor/bird.tscn")
const SUN_SCENE := preload("res://scenes/decor/sun.tscn")

const SECTION_COUNT := 12
const SECTION_WIDTH := 1500.0
const START_X := 2800.0
const GROUND_Y := 680.0
const GROUND_TOP := 640.0


func _ready() -> void:
	var level := get_parent()
	if level != null and int(level.get("level_variant")) != 1:
		return
	_build()


func _build() -> void:
	_spawn(SUN_SCENE, Vector2.ZERO)
	_build_clouds()
	for i in SECTION_COUNT:
		var start_x := START_X + float(i) * SECTION_WIDTH
		_build_section(i, start_x)
	_build_final_stretch()
	_build_checkpoints()


func _build_checkpoints() -> void:
	## Un único control a mitad del recorrido (2026-11-12), sobre suelo firme.
	for x in [11500.0]:
		_spawn(CHECKPOINT_SCENE, Vector2(x, GROUND_TOP - 48.0))


func _build_clouds() -> void:
	## Nubes en capa de paralaje propia (2026-11-11): viajan a 0.55x la cámara,
	## por delante de las colinas y por detrás del terreno jugable.
	var clouds := Parallax2D.new()
	clouds.name = "CloudParallax"
	clouds.scroll_scale = Vector2(0.55, 1.0)
	clouds.z_index = -8
	add_child(clouds)
	for i in 11:
		var cloud := _spawn(CLOUD_SCENE, Vector2(200.0 + float(i) * 1300.0, 95.0 + float(i % 4) * 42.0))
		(cloud.get_node("Sprite2D") as Sprite2D).scale = Vector2.ONE * (0.75 + float(i % 3) * 0.16)
		cloud.reparent(clouds)


func _build_section(index: int, start_x: float) -> void:
	_add_hill(start_x + 420.0, 380.0, 150.0 + float(index % 3) * 20.0, Color("#173a34"))
	_add_hill(start_x + 1120.0, 320.0, 120.0 + float(index % 2) * 30.0, Color("#1d463c"))

	var pit_width := 240.0 + float(index % 3) * 24.0
	var side_width := (SECTION_WIDTH - pit_width) * 0.5
	var pit_x := start_x + SECTION_WIDTH * 0.5
	_spawn_platform(
		Vector2(start_x + side_width * 0.5, GROUND_Y),
		Vector2(side_width, 80.0),
		Color("#2d5543")
	)
	_spawn_platform(
		Vector2(start_x + SECTION_WIDTH - side_width * 0.5, GROUND_Y),
		Vector2(side_width, 80.0),
		Color("#2d5543")
	)
	var pit := _spawn(FALL_ZONE_SCENE, Vector2(pit_x, 800.0))
	pit.name = "FallZone%d" % index

	var low_y := 548.0
	var mid_y := 440.0
	var high_y := 330.0

	# Espaciado 2026-11-11: huecos de >= 45 px horizontales y >= 72 px
	# verticales (1.5x el tamano del jugador) o plataformas que se tocan.
	_spawn_platform(Vector2(start_x + 250.0, low_y), Vector2(200.0, 24.0), Color("#355070"))
	_spawn_platform(Vector2(start_x + 520.0, mid_y), Vector2(200.0, 24.0), Color("#3d5a80"))
	_spawn_platform(Vector2(start_x + 860.0, low_y), Vector2(200.0, 24.0), Color("#4a6b8f"))
	_spawn_platform(Vector2(start_x + 1180.0, mid_y), Vector2(200.0, 24.0), Color("#527b98"))
	_spawn_platform(Vector2(start_x + 1000.0, high_y), Vector2(180.0, 24.0), Color("#456c88"))
	_spawn_platform(Vector2(start_x + 1420.0, mid_y), Vector2(160.0, 24.0), Color("#3b607a"))

	if index % 2 == 0:
		var walker = _spawn(WALKER_SCENE, Vector2(start_x + 1060.0, GROUND_TOP - 26.0))
		walker.patrol_speed = 86.0
		walker.patrol_distance = 240.0
	elif index % 3 == 0:
		var ranged = _spawn(RANGED_SCENE, Vector2(start_x + 520.0, mid_y - 36.0))
		ranged.shoot_interval = 3.0
		ranged.shoot_range = 430.0

	# Enemigo ráfaga común (antiguo jefe) cada pocas secciones, en tierra firme.
	if index in [1, 4, 7, 10]:
		_spawn(SPREAD_SCENE, Vector2(start_x + 180.0, GROUND_TOP - 40.0))

	var low_walker := _spawn(WALKER_SCENE, Vector2(start_x + 250.0, low_y - 38.0))
	low_walker.patrol_speed = 72.0 + float(index % 3) * 8.0
	low_walker.patrol_distance = 78.0
	var high_walker := _spawn(WALKER_SCENE, Vector2(start_x + 1180.0, mid_y - 38.0))
	high_walker.patrol_speed = 78.0 + float(index % 2) * 10.0
	high_walker.patrol_distance = 72.0

	if index % 2 == 0:
		_spawn(HERB_SCENE, Vector2(start_x + 1350.0, GROUND_TOP - 22.0))

	_spawn(TREE_SCENE, Vector2(start_x + 120.0, GROUND_TOP), Color(0.92, 1.0, 0.92))
	_spawn(TREE_SCENE, Vector2(start_x + 1390.0, GROUND_TOP), Color(0.82, 0.95, 0.86))
	_spawn(BIRD_SCENE, Vector2(start_x + 152.0, GROUND_TOP - 148.0), Color(1.0, 1.0, 1.0))
	_spawn(BIRD_SCENE, Vector2(start_x + 1355.0, GROUND_TOP - 162.0), Color(1.0, 1.0, 1.0))
	_spawn(BUSH_SCENE, Vector2(start_x + 640.0, GROUND_TOP), Color(1.0, 1.0, 1.0))


func _build_final_stretch() -> void:
	var arena_x := START_X + SECTION_WIDTH * float(SECTION_COUNT)
	_add_hill(arena_x + 220.0, 390.0, 175.0, Color("#173a34"))
	_add_hill(arena_x + 980.0, 330.0, 135.0, Color("#1d463c"))
	_spawn_platform(
		Vector2(arena_x + 140.0, GROUND_Y),
		Vector2(280.0, 80.0),
		Color("#2a4d3d")
	)
	_spawn_platform(
		Vector2(arena_x + 600.0, GROUND_Y),
		Vector2(240.0, 80.0),
		Color("#2a4d3d")
	)
	_spawn_platform(
		Vector2(arena_x + 1060.0, GROUND_Y),
		Vector2(280.0, 80.0),
		Color("#2a4d3d")
	)
	var final_pit_left := _spawn(FALL_ZONE_SCENE, Vector2(arena_x + 400.0, 800.0))
	final_pit_left.name = "FallZoneFinalLeft"
	var final_pit_right := _spawn(FALL_ZONE_SCENE, Vector2(arena_x + 820.0, 800.0))
	final_pit_right.name = "FallZoneFinalRight"
	_spawn_platform(Vector2(arena_x + 380.0, 548.0), Vector2(200.0, 24.0), Color("#4a6b8f"))
	_spawn_platform(Vector2(arena_x + 640.0, 428.0), Vector2(220.0, 24.0), Color("#3d5a80"))
	_spawn_platform(Vector2(arena_x + 900.0, 548.0), Vector2(200.0, 24.0), Color("#4a6b8f"))
	_spawn_platform(Vector2(arena_x + 620.0, 310.0), Vector2(180.0, 24.0), Color("#527b98"))
	_spawn(TREE_SCENE, Vector2(arena_x + 80.0, GROUND_TOP), Color(0.9, 1.0, 0.9))
	_spawn(TREE_SCENE, Vector2(arena_x + 1120.0, GROUND_TOP), Color(0.8, 0.95, 0.86))
	_spawn(BIRD_SCENE, Vector2(arena_x + 112.0, GROUND_TOP - 150.0), Color(1.0, 1.0, 1.0))
	_spawn(BIRD_SCENE, Vector2(arena_x + 1090.0, GROUND_TOP - 160.0), Color(1.0, 1.0, 1.0))
	var walker: WalkerEnemy = _spawn(WALKER_SCENE, Vector2(arena_x + 600.0, GROUND_TOP - 26.0))
	walker.patrol_speed = 100.0
	walker.patrol_distance = 420.0
	_spawn(SPREAD_SCENE, Vector2(arena_x + 140.0, GROUND_TOP - 40.0))
	var left_walker := _spawn(WALKER_SCENE, Vector2(arena_x + 380.0, 548.0 - 38.0))
	left_walker.patrol_speed = 84.0
	left_walker.patrol_distance = 76.0
	var right_walker := _spawn(WALKER_SCENE, Vector2(arena_x + 900.0, 548.0 - 38.0))
	right_walker.patrol_speed = 90.0
	right_walker.patrol_distance = 76.0
	_spawn(HERB_SCENE, Vector2(arena_x + 1020.0, GROUND_TOP - 22.0))


func _add_hill(center_x: float, width: float, height: float, color: Color) -> void:
	var hill := Polygon2D.new()
	hill.color = color
	hill.position = Vector2(center_x, GROUND_TOP)
	hill.polygon = PackedVector2Array([
		Vector2(-width * 0.5, 0.0),
		Vector2(-width * 0.18, -height),
		Vector2(width * 0.5, 0.0),
	])
	hill.z_index = -14
	add_child(hill)
	MountainBuilder.decorate(
		hill,
		Color("#cfe3dc"),
		color.lightened(0.10),
		color.darkened(0.22),
		true
	)


func _spawn_platform(center: Vector2, size: Vector2, color: Color) -> Platform:
	var platform: Platform = PLATFORM_SCENE.instantiate()
	platform.platform_size = size
	platform.platform_color = color
	platform.position = center
	add_child(platform)
	return platform


func _spawn(scene: PackedScene, position: Vector2, modulate: Color = Color.WHITE) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.position = position
	node.modulate = modulate
	add_child(node)
	return node
