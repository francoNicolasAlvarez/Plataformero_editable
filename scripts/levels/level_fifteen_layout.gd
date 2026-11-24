class_name LevelFifteenLayout
extends RefCounted
## Nivel 15 (2026-11-17): "TORMENTA" (mundo 3, nivel 5, final del mundo). Un
## desafío en tres partes: cuatro tramos de suelo con fosos (lanceros,
## saltadores, orbes y un bruto), una ruta de 18 plataformas con viento,
## rocas por delante, murciélagos y un centinela, y una isla final custodiada
## por un bruto con su pila, una babosa de doble salto, un saltador de salto
## largo y dos lanceros. Mezcla todos los enemigos del mundo.

const LEVEL_WIDTH := 17000.0
const START_WIDTH := 1400.0
const SECTION_START_X := 1700.0
const SECTION_STEP := 1300.0
const SECTION_WIDTH := 1000.0
const SECTION_COUNT := 4
const ROUTE_START_X := 7050.0
const ROUTE_STEP := 400.0
const ROUTE_COUNT := 18
const PLATFORM_SIZE := Vector2(200.0, 24.0)
const WIDE_SIZE := Vector2(340.0, 24.0)
const ROUTE_Y := [548.0, 440.0, 332.0, 440.0]
const WIDE_INDICES := [5, 11]
const CHECKPOINT_INDEX := 11
const HERB_INDICES := [3, 8]
const ARCHER_INDICES := [5, 14]
const MAGE_INDICES := [2, 11, 16]
const ORB_GAPS := [6, 13]
const SAW_GAPS := [9, 15]
const END_START_X := 14150.0
const PORTAL_POSITION := Vector2(16500.0, 580.0)
const TIER_LOW := 548.0
const TIER_HIGH := 440.0
const WIND := [[1500.0, 6600.0, 110.0], [6800.0, 10400.0, -135.0], [10400.0, 13900.0, 125.0]]
const SLATE := Color("#6e7b8f")


static func section_start(index: int) -> float:
	return SECTION_START_X + float(index) * SECTION_STEP


static func route_x(index: int) -> float:
	return ROUTE_START_X + float(index) * ROUTE_STEP


static func route_y(index: int) -> float:
	return ROUTE_Y[index % ROUTE_Y.size()]


static func kind_for(index: int) -> Platform.Kind:
	return [
		Platform.Kind.STATIC, Platform.Kind.HORIZONTAL, Platform.Kind.SPIKED,
		Platform.Kind.CIRCULAR, Platform.Kind.STATIC, Platform.Kind.ROTATING,
	][index % 6]


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelFifteenGenerated")
	DesertKit.sky(world, LEVEL_WIDTH, {
		"top": Color("#262a3d"), "mid": Color("#4a4f6b"), "bottom": Color("#9a8a8c"),
		"sun": Color(1.0, 0.6, 0.4, 0.8), "cloud": Color(0.55, 0.55, 0.65, 0.85),
		"far_style": "pyramids", "far_colors": [Color("#3b3f57"), Color("#444964"), Color("#34374d")],
		"base": Color("#2f3246"),
	})
	DesertKit.ground(world, 0.0, START_WIDTH, SLATE)
	for index in SECTION_COUNT:
		DesertKit.ground(world, section_start(index), section_start(index) + SECTION_WIDTH, SLATE)
	DesertKit.ground(world, END_START_X, LEVEL_WIDTH, SLATE, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneStorm")
	for index in SECTION_COUNT:
		_build_section(world, index)
	_build_route(world)
	_build_finale(world)
	DesertKit.rockfall(world, ROUTE_START_X - 200.0, END_START_X - 100.0)
	DesertKit.bats(world, 5.0, 4.0)
	DesertKit.sentry(world)
	DesertKit.wind(world, WIND, 6.0)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_section(world: Node2D, index: int) -> void:
	var x0 := section_start(index)
	var top := DesertKit.GROUND_TOP
	DesertKit.platform(world, Vector2(x0 + 330.0, TIER_LOW), Vector2(200.0, 24.0), Color("#8a97ab"), Platform.Kind.STATIC, "StormStepLow%d" % index)
	DesertKit.platform(world, Vector2(x0 + 640.0, TIER_HIGH), Vector2(200.0, 24.0), Color("#8a97ab"), Platform.Kind.STATIC, "StormStepHigh%d" % index)
	var bridge_kind: Platform.Kind = [Platform.Kind.STATIC, Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR, Platform.Kind.HORIZONTAL][index % 4]
	DesertKit.platform(world, Vector2(x0 + SECTION_WIDTH + 150.0, TIER_LOW), Vector2(110.0, 24.0), Color("#8a97ab"), bridge_kind, "StormBridge%d" % index)
	match index:
		0:
			DesertKit.spearman(world, "StormSpearman0", x0 + 250.0, top)
			DesertKit.slug(world, "StormSlug0", x0 + 800.0, top)
		1:
			DesertKit.jumper(world, "StormJumper1", x0 + 820.0, top)
			DesertKit.archer(world, "StormArcher1", x0 + 640.0, TIER_HIGH - 12.0)
		2:
			DesertKit.brute_post(world, "StormBrute2", x0 + 585.0, x0 + 700.0, top)
			DesertKit.orb(world, "StormOrb2", Vector2(x0 + SECTION_WIDTH + 150.0, 380.0))
			DesertKit.spearman(world, "StormNarrowSpearman2", x0 + 330.0, TIER_LOW - 12.0, true)
		3:
			DesertKit.jumper(world, "StormLongJumper3", x0 + 850.0, top, true)
			DesertKit.mage(world, "StormMage3", x0 + 640.0, TIER_HIGH - 12.0)
			DesertKit.spike(world, x0 + 400.0, top)


static func _build_route(world: Node2D) -> void:
	for index in ROUTE_COUNT:
		var wide := index in WIDE_INDICES
		var forced_static := wide or index in ARCHER_INDICES or index in MAGE_INDICES or index in HERB_INDICES
		var platform := DesertKit.platform(
			world,
			Vector2(route_x(index), route_y(index)),
			WIDE_SIZE if wide else PLATFORM_SIZE,
			[Color("#7a879c"), Color("#8f9bb0"), Color("#667389")][index % 3],
			Platform.Kind.STATIC if forced_static else kind_for(index),
			"StormPlatform%d" % index
		)
		var x := platform.position.x
		var top := platform.position.y - 12.0
		if index in HERB_INDICES:
			DesertKit.herb(world, x, top)
		if index == CHECKPOINT_INDEX:
			DesertKit.checkpoint(world, x - 90.0, top)
		if index in ARCHER_INDICES:
			DesertKit.archer(world, "StormRouteArcher%d" % index, x + (60.0 if wide else 0.0), top)
		if index in MAGE_INDICES:
			DesertKit.mage(world, "StormRouteMage%d" % index, x + (90.0 if wide else 0.0), top)
	for gap in ORB_GAPS:
		var mid_x := (route_x(gap) + route_x(gap + 1)) * 0.5
		DesertKit.orb(world, "StormRouteOrb%d" % gap, Vector2(mid_x, (route_y(gap) + route_y(gap + 1)) * 0.5 - 70.0), gap == 13)
	for gap in SAW_GAPS:
		var y := minf(route_y(gap), route_y(gap + 1)) - 85.0
		DesertKit.saw(world, Vector2((route_x(gap) + route_x(gap + 1)) * 0.5, y), 160.0, 1.2)


static func _build_finale(world: Node2D) -> void:
	var top := DesertKit.GROUND_TOP
	DesertKit.brute_post(world, "StormFinaleBrute", 14950.0, 15090.0, top)
	DesertKit.slug(world, "StormFinaleSlug", 14500.0, top, true)
	DesertKit.jumper(world, "StormFinaleJumper", 15700.0, top, true)
	DesertKit.spearman(world, "StormFinaleSpearmanA", 14350.0, top)
	DesertKit.spearman(world, "StormFinaleSpearmanB", 15450.0, top)
