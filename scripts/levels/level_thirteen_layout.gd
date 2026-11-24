class_name LevelThirteenLayout
extends RefCounted
## Nivel 13 (2026-11-17): "OASIS" (mundo 3, nivel 3). Un lago de abismo cruzado
## por 32 plataformas, casi todas móviles (vaivén, órbita y giro), con islas
## anchas cada cinco plataformas que alojan arqueros, magos, el control, hierbas
## y dos brutos con su pila de rocas. Murciélagos cada 4,5 s, orbes sobre el
## agua, sierras suspendidas y un viento suave que cambia de sentido.

const LEVEL_WIDTH := 15400.0
const START_WIDTH := 1400.0
const END_START_X := 13800.0
const PORTAL_POSITION := Vector2(14900.0, 580.0)
const ROUTE_START_X := 1700.0
const ROUTE_STEP := 380.0
const ROUTE_COUNT := 32
const PLATFORM_SIZE := Vector2(200.0, 24.0)
const ISLAND_SIZE := Vector2(340.0, 24.0)
const ROUTE_Y := [550.0, 450.0, 350.0, 450.0]
const ISLAND_PERIOD := 5
const ISLAND_PHASE := 2
const CHECKPOINT_INDEX := 17
const HERB_INDICES := [7, 22]
const BRUTE_INDICES := [12, 27]
const ARCHER_INDICES := [2, 22]
const MAGE_INDICES := [7, 27]
const ORB_GAPS := [5, 14, 24]
const SAW_GAPS := [9, 19, 29]
const WIND := [[1500.0, 6500.0, -60.0], [6500.0, 10500.0, 65.0], [10500.0, 13600.0, -75.0]]
const STONE := Color("#b9a982")
const WATER_STONE := Color("#8fb9a3")


static func route_x(index: int) -> float:
	return ROUTE_START_X + float(index) * ROUTE_STEP


static func route_y(index: int) -> float:
	return ROUTE_Y[index % ROUTE_Y.size()]


static func is_island(index: int) -> bool:
	return index % ISLAND_PERIOD == ISLAND_PHASE


static func kind_for(index: int) -> Platform.Kind:
	return [
		Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR, Platform.Kind.STATIC,
		Platform.Kind.ROTATING, Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR,
	][index % 6]


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelThirteenGenerated")
	DesertKit.sky(world, LEVEL_WIDTH, {
		"top": Color("#3f8fb0"), "mid": Color("#79c3cf"), "bottom": Color("#e8e2b8"),
		"sun": Color(1.0, 0.95, 0.7, 0.9), "cloud": Color(1.0, 1.0, 1.0, 0.8),
		"far_style": "dunes", "far_colors": [Color("#8fb78f"), Color("#7ba67f"), Color("#6c9a74")],
		"base": Color("#5f8f6f"),
	})
	DesertKit.palms(world, LEVEL_WIDTH, 900.0, Color("#3f7a4a"))
	DesertKit.ground(world, 0.0, START_WIDTH, STONE)
	DesertKit.ground(world, END_START_X, LEVEL_WIDTH, STONE, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneOasis")
	_build_route(world)
	for gap in ORB_GAPS:
		var mid_x := (route_x(gap) + route_x(gap + 1)) * 0.5
		DesertKit.orb(world, "OasisOrb%d" % gap, Vector2(mid_x, (route_y(gap) + route_y(gap + 1)) * 0.5 - 75.0))
	for gap in SAW_GAPS:
		var y := minf(route_y(gap), route_y(gap + 1)) - 90.0
		DesertKit.saw(world, Vector2((route_x(gap) + route_x(gap + 1)) * 0.5, y), 160.0, 1.2)
	DesertKit.bats(world, 4.5, 3.0)
	DesertKit.wind(world, WIND, 8.0)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_route(world: Node2D) -> void:
	for index in ROUTE_COUNT:
		var island := is_island(index)
		var platform := DesertKit.platform(
			world,
			Vector2(route_x(index), route_y(index)),
			ISLAND_SIZE if island else PLATFORM_SIZE,
			WATER_STONE if index % 2 == 0 else Color("#a6cdb6"),
			Platform.Kind.STATIC if island else kind_for(index),
			"OasisPlatform%d" % index
		)
		if not island:
			continue
		var top := platform.position.y - 12.0
		if index in HERB_INDICES:
			DesertKit.herb(world, platform.position.x, top)
		if index in ARCHER_INDICES:
			DesertKit.archer(world, "OasisArcher%d" % index, platform.position.x + 80.0, top)
		if index in MAGE_INDICES and index not in BRUTE_INDICES:
			DesertKit.mage(world, "OasisMage%d" % index, platform.position.x - 80.0, top)
		if index in BRUTE_INDICES:
			DesertKit.brute_post(world, "OasisBrute%d" % index, platform.position.x - 80.0, platform.position.x + 100.0, top)
		if index == CHECKPOINT_INDEX:
			DesertKit.checkpoint(world, platform.position.x, top)
