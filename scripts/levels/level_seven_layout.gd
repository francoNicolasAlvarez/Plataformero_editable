class_name LevelSevenLayout
extends RefCounted

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

const SECTION_COUNT := 12
const SECTION_WIDTH := 1500.0
const START_X := 2800.0
const VIEW_HEIGHT := 720.0
const CEILING_Y := 40.0
const LEVEL_WIDTH := 22400.0
const PORTAL_X := 21850.0
const CHECKPOINT_X := 11500.0

static func build(level: Node2D) -> void:
	var world := Node2D.new()
	world.name = "LevelSevenGenerated"
	level.add_child(world)

	_build_background(world)
	_build_clouds(world)
	_build_start_area(world)
	for index in SECTION_COUNT:
		_build_section(world, index, START_X + float(index) * SECTION_WIDTH)
	_build_final_stretch(world)
	_build_checkpoint(world)
	_build_fall_zone(world)
	_place_player(level)
	_build_finish(level)
	_style_enemies(level)


static func _mirror(y: float) -> float:
	return VIEW_HEIGHT - y


static func _build_background(world: Node2D) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color("#101d3a"),
		Color("#25345e"),
		Color("#3d2b52"),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 16
	texture.height = 256
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	var sky := TextureRect.new()
	sky.name = "InvertedSky"
	sky.texture = texture
	sky.size = Vector2(LEVEL_WIDTH, VIEW_HEIGHT)
	sky.z_index = -30
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	world.add_child(sky)


static func _build_clouds(world: Node2D) -> void:
	var layer := Parallax2D.new()
	layer.name = "CloudParallax"
	layer.scroll_scale = Vector2(0.55, 1.0)
	layer.z_index = -8
	world.add_child(layer)
	for index in 11:
		var cloud := _spawn(CLOUD_SCENE, layer, Vector2(200.0 + float(index) * 1300.0, _mirror(100.0 + float(index % 4) * 42.0)))
		cloud.scale = Vector2.ONE * (0.75 + float(index % 3) * 0.16)
		cloud.scale.y *= -1.0

static func _build_start_area(world: Node2D) -> void:
	_add_platform(world, Vector2(1300.0, CEILING_Y), Vector2(2600.0, 80.0), "#2d5543")
	_add_platform(world, Vector2(850.0, _mirror(548.0)), Vector2(220.0, 24.0), "#355070")
	_add_platform(world, Vector2(1150.0, _mirror(440.0)), Vector2(180.0, 24.0), "#3d5a80")
	_add_platform(world, Vector2(1420.0, _mirror(548.0)), Vector2(200.0, 24.0), "#4a6b8f")
	_add_platform(world, Vector2(1720.0, _mirror(440.0)), Vector2(220.0, 24.0), "#527b98")
	_add_platform(world, Vector2(2020.0, _mirror(548.0)), Vector2(180.0, 24.0), "#456c88")
	_add_platform(world, Vector2(2300.0, _mirror(440.0)), Vector2(200.0, 24.0), "#3b607a")
	_add_platform(world, Vector2(2700.0, CEILING_Y), Vector2(200.0, 80.0), "#2d5543")
	_add_platform(world, Vector2(21980.0, _mirror(484.0)), Vector2(40.0, 392.0), "#263d51")

	_spawn_walker(world, Vector2(1600.0, _mirror(614.0)), 60.0, 120.0)
	_spawn_ranged(world, Vector2(1330.0, _mirror(610.0)))
	_spawn_spread(world, Vector2(2150.0, _mirror(600.0)))
	for herb_x in [500.0, 1900.0]:
		var herb := _spawn(HERB_SCENE, world, Vector2(herb_x, _mirror(600.0)))
		herb.scale.y = -1.0


static func _build_section(world: Node2D, index: int, start_x: float) -> void:
	_add_hill(world, start_x + 420.0, 380.0, 150.0 + float(index % 3) * 20.0, "#0e2a27")
	_add_hill(world, start_x + 1120.0, 320.0, 120.0 + float(index % 2) * 30.0, "#12332d")

	var pit_width := 240.0 + float(index % 3) * 24.0
	var side_width := (SECTION_WIDTH - pit_width) * 0.5
	_add_platform(world, Vector2(start_x + side_width * 0.5, CEILING_Y), Vector2(side_width, 80.0), "#2d5543")
	_add_platform(world, Vector2(start_x + SECTION_WIDTH - side_width * 0.5, CEILING_Y), Vector2(side_width, 80.0), "#2d5543")

	var tiers := [_mirror(548.0), _mirror(440.0), _mirror(330.0)]
	_add_platform(world, Vector2(start_x + 250.0, tiers[0]), Vector2(200.0, 24.0), "#355070")
	_add_platform(world, Vector2(start_x + 520.0, tiers[1]), Vector2(200.0, 24.0), "#3d5a80")
	_add_platform(world, Vector2(start_x + 860.0, tiers[0]), Vector2(200.0, 24.0), "#4a6b8f")
	_add_platform(world, Vector2(start_x + 1180.0, tiers[1]), Vector2(200.0, 24.0), "#527b98")
	_add_platform(world, Vector2(start_x + 1000.0, tiers[2]), Vector2(180.0, 24.0), "#456c88")
	_add_platform(world, Vector2(start_x + 1420.0, tiers[1]), Vector2(160.0, 24.0), "#3b607a")

	if index % 2 == 0:
		_spawn_walker(world, Vector2(start_x + 1060.0, _mirror(614.0)), 86.0, 240.0)
	elif index % 3 == 0:
		_spawn_ranged(world, Vector2(start_x + 520.0, _mirror(404.0)))
	if index in [1, 4, 7, 10]:
		_spawn_spread(world, Vector2(start_x + 180.0, _mirror(600.0)))
	_spawn_walker(world, Vector2(start_x + 250.0, _mirror(510.0)), 72.0 + float(index % 3) * 8.0, 78.0)
	_spawn_walker(world, Vector2(start_x + 1180.0, _mirror(402.0)), 78.0 + float(index % 2) * 10.0, 72.0)

	if index % 2 == 0:
		var herb := _spawn(HERB_SCENE, world, Vector2(start_x + 1350.0, _mirror(618.0)))
		herb.scale.y = -1.0

	_spawn(TREE_SCENE, world, Vector2(start_x + 120.0, _mirror(640.0))).scale.y = -1.0
	_spawn(TREE_SCENE, world, Vector2(start_x + 1390.0, _mirror(640.0))).scale.y = -1.0
	_spawn(BUSH_SCENE, world, Vector2(start_x + 640.0, _mirror(640.0))).scale.y = -1.0


static func _build_final_stretch(world: Node2D) -> void:
	var arena_x := START_X + SECTION_WIDTH * float(SECTION_COUNT)
	_add_hill(world, arena_x + 220.0, 380.0, 150.0, "#0e2a27")
	_add_hill(world, arena_x + 980.0, 320.0, 120.0, "#12332d")
	_add_platform(world, Vector2(arena_x + 140.0, CEILING_Y), Vector2(280.0, 80.0), "#2d5543")
	_add_platform(world, Vector2(arena_x + 600.0, CEILING_Y), Vector2(240.0, 80.0), "#2d5543")
	_add_platform(world, Vector2(arena_x + 1060.0, CEILING_Y), Vector2(280.0, 80.0), "#2d5543")
	_add_platform(world, Vector2(arena_x + 380.0, _mirror(548.0)), Vector2(200.0, 24.0), "#355070")
	_add_platform(world, Vector2(arena_x + 640.0, _mirror(428.0)), Vector2(200.0, 24.0), "#3d5a80")
	_add_platform(world, Vector2(arena_x + 900.0, _mirror(548.0)), Vector2(200.0, 24.0), "#4a6b8f")
	_add_platform(world, Vector2(arena_x + 620.0, _mirror(310.0)), Vector2(180.0, 24.0), "#456c88")

	_spawn_walker(world, Vector2(arena_x + 600.0, _mirror(614.0)), 86.0, 420.0)
	_spawn_spread(world, Vector2(arena_x + 140.0, _mirror(600.0)))
	_spawn_walker(world, Vector2(arena_x + 380.0, _mirror(510.0)), 72.0, 78.0)
	_spawn_walker(world, Vector2(arena_x + 900.0, _mirror(510.0)), 72.0, 78.0)

	var herb := _spawn(HERB_SCENE, world, Vector2(arena_x + 1020.0, _mirror(618.0)))
	herb.scale.y = -1.0
	_spawn(TREE_SCENE, world, Vector2(arena_x + 80.0, _mirror(640.0))).scale.y = -1.0
	_spawn(TREE_SCENE, world, Vector2(arena_x + 1120.0, _mirror(640.0))).scale.y = -1.0


static func _build_checkpoint(world: Node2D) -> void:
	var checkpoint := _spawn(CHECKPOINT_SCENE, world, Vector2(CHECKPOINT_X, _mirror(592.0)))
	checkpoint.name = "CheckpointInverted"
	checkpoint.scale.y = -1.0


static func _build_fall_zone(world: Node2D) -> void:
	var fall_zone := _spawn(FALL_ZONE_SCENE, world, Vector2(LEVEL_WIDTH * 0.5, -80.0))
	fall_zone.name = "FallZoneInverted"
	var shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
	shape.size = Vector2(LEVEL_WIDTH + 800.0, 120.0)


static func _place_player(level: Node2D) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player == null:
		return
	player.inverted_gravity = true
	player.configure_gravity()
	player.global_position = Vector2(620.0, _mirror(600.0))


static func _build_finish(level: Node2D) -> void:
	var portal := level.get_node_or_null("ExitPortal") as ExitPortal
	if portal != null:
		portal.position = Vector2(PORTAL_X, _mirror(580.0))
		portal.scale.y = -1.0

	var camera := level.get_node_or_null("Camera") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(LEVEL_WIDTH)
		camera.limit_bottom = int(VIEW_HEIGHT)
		camera.snap_to_target()


static func _style_enemies(level: Node2D) -> void:
	for enemy in level.get_tree().get_nodes_in_group("enemies"):
		EnemyVisualVariant.apply_inverted_style(enemy as Node2D)


static func _spawn_walker(world: Node2D, position: Vector2, speed: float, distance: float) -> Node2D:
	var enemy := WALKER_SCENE.instantiate() as WalkerEnemy
	enemy.inverted_gravity = true
	enemy.patrol_speed = speed
	enemy.patrol_distance = distance
	enemy.position = position
	world.add_child(enemy)
	return enemy


static func _spawn_ranged(world: Node2D, position: Vector2) -> Node2D:
	var enemy := RANGED_SCENE.instantiate() as RangedEnemy
	enemy.inverted_gravity = true
	enemy.position = position
	world.add_child(enemy)
	return enemy


static func _spawn_spread(world: Node2D, position: Vector2) -> Node2D:
	var enemy := SPREAD_SCENE.instantiate() as SpreadEnemy
	enemy.inverted_gravity = true
	enemy.position = position
	world.add_child(enemy)
	return enemy


static func _add_hill(world: Node2D, center_x: float, height: float, width: float, color: String) -> void:
	var hill := Polygon2D.new()
	hill.name = "InvertedHill"
	hill.color = Color(color)
	hill.polygon = PackedVector2Array([
		Vector2(-width * 0.5, 0.0),
		Vector2(-width * 0.18, -height),
		Vector2(width * 0.5, 0.0),
	])
	hill.position = Vector2(center_x, _mirror(640.0))
	hill.scale.y = -1.0
	hill.z_index = -14
	world.add_child(hill)


static func _add_platform(world: Node2D, center: Vector2, size: Vector2, color: String) -> Platform:
	var platform := PLATFORM_SCENE.instantiate() as Platform
	platform.platform_size = size
	platform.platform_color = Color(color)
	platform.position = center
	platform.scale.y = -1.0
	world.add_child(platform)
	return platform


static func _spawn(scene: PackedScene, parent: Node, position: Vector2) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.position = position
	parent.add_child(node)
	return node
