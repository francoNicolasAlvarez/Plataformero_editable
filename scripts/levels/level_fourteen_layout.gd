class_name LevelFourteenLayout
extends RefCounted
## Nivel 14 (2026-11-17): "CAÑÓN" (mundo 3, nivel 4). Un ascenso y descenso en
## zigzag por las repisas de un cañón (cinco alturas, de 550 a 150 px), con
## rocas que caen de las paredes por delante del jugador, un centinela en la
## esquina, viento fuerte, sierras suspendidas y orbes. Repisas anchas con
## saltadores explosivos y un bruto con su pila; lanceros estrechos, arqueros
## y magos en las plataformas normales.

const LEVEL_WIDTH := 16000.0
const START_WIDTH := 1400.0
const END_START_X := 14500.0
const PORTAL_POSITION := Vector2(15400.0, 580.0)
const ROUTE_START_X := 1700.0
const ROUTE_STEP := 380.0
const ROUTE_COUNT := 34
const PLATFORM_SIZE := Vector2(200.0, 24.0)
const LEDGE_SIZE := Vector2(360.0, 24.0)
const ROUTE_Y := [550.0, 450.0, 350.0, 250.0, 150.0, 250.0, 350.0, 450.0]
const LEDGE_INDICES := [4, 12, 16, 20, 28]
const CHECKPOINT_INDEX := 16
const HERB_INDICES := [4, 28]
const JUMPER_INDICES := [12, 28]
const LONG_JUMPER_INDEX := 28
const BRUTE_INDEX := 20
const NARROW_SPEARMAN_INDICES := [7, 19, 31]
const ARCHER_INDICES := [10, 18, 26]
const MAGE_INDICES := [14, 22, 30]
const ORB_GAPS := [6, 16, 24]
const VERTICAL_ORB_GAP := 16
const SAW_GAPS := [9, 17, 25]
const ROCK_MIN_X := 1700.0
const ROCK_MAX_X := 14300.0
const WIND := [[1500.0, 6500.0, 120.0], [6500.0, 10800.0, -130.0], [10800.0, 14300.0, 125.0]]
const ROCK := Color("#a8664a")


static func route_x(index: int) -> float:
	return ROUTE_START_X + float(index) * ROUTE_STEP


static func route_y(index: int) -> float:
	return ROUTE_Y[index % ROUTE_Y.size()]


static func kind_for(index: int) -> Platform.Kind:
	return [
		Platform.Kind.STATIC, Platform.Kind.STATIC, Platform.Kind.SPIKED,
		Platform.Kind.HORIZONTAL, Platform.Kind.STATIC, Platform.Kind.ROTATING,
	][index % 6]


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelFourteenGenerated")
	DesertKit.sky(world, LEVEL_WIDTH, {
		"top": Color("#7a3b2e"), "mid": Color("#c4704a"), "bottom": Color("#f0c48a"),
		"sun": Color(1.0, 0.7, 0.4, 0.9), "cloud": Color(0.95, 0.75, 0.6, 0.7),
		"far_style": "mesas", "far_colors": [Color("#9a5a41"), Color("#8c4f38"), Color("#a46448")],
		"base": Color("#7e4632"),
	})
	DesertKit.ground(world, 0.0, START_WIDTH, ROCK)
	DesertKit.ground(world, END_START_X, LEVEL_WIDTH, ROCK, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneCanyon")
	_build_route(world)
	for gap in ORB_GAPS:
		var mid_x := (route_x(gap) + route_x(gap + 1)) * 0.5
		DesertKit.orb(world, "CanyonOrb%d" % gap, Vector2(mid_x, (route_y(gap) + route_y(gap + 1)) * 0.5 - 70.0), gap == VERTICAL_ORB_GAP)
	for gap in SAW_GAPS:
		var y := minf(route_y(gap), route_y(gap + 1)) - 85.0
		DesertKit.saw(world, Vector2((route_x(gap) + route_x(gap + 1)) * 0.5, y), 160.0, 1.2)
	DesertKit.rockfall(world, ROCK_MIN_X, ROCK_MAX_X)
	DesertKit.sentry(world)
	DesertKit.wind(world, WIND, 6.5)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_route(world: Node2D) -> void:
	for index in ROUTE_COUNT:
		var ledge := index in LEDGE_INDICES
		var forced_static := ledge or index in NARROW_SPEARMAN_INDICES or index in ARCHER_INDICES or index in MAGE_INDICES
		var platform := DesertKit.platform(
			world,
			Vector2(route_x(index), route_y(index)),
			LEDGE_SIZE if ledge else PLATFORM_SIZE,
			[Color("#b9774f"), Color("#c98a5e"), Color("#a56a46")][index % 3],
			Platform.Kind.STATIC if forced_static else kind_for(index),
			"CanyonPlatform%d" % index
		)
		var x := platform.position.x
		var top := platform.position.y - 12.0
		if index in HERB_INDICES:
			DesertKit.herb(world, x, top)
		if index == CHECKPOINT_INDEX:
			DesertKit.checkpoint(world, x, top)
		if index in ARCHER_INDICES:
			DesertKit.archer(world, "CanyonArcher%d" % index, x, top)
		if index in MAGE_INDICES:
			DesertKit.mage(world, "CanyonMage%d" % index, x, top)
		if index in NARROW_SPEARMAN_INDICES:
			DesertKit.spearman(world, "CanyonNarrowSpearman%d" % index, x, top, true)
		if index in JUMPER_INDICES:
			DesertKit.jumper(world, "CanyonJumper%d" % index, x + 100.0, top, index == LONG_JUMPER_INDEX)
		if index == BRUTE_INDEX:
			DesertKit.brute_post(world, "CanyonBrute%d" % index, x - 80.0, x + 110.0, top)
