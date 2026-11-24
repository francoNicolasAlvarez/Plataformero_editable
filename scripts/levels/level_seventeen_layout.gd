class_name LevelSeventeenLayout
extends RefCounted
## Nivel 17 (2026-11-18): "MINA" (mundo 4, nivel 2). Galería minera con
## respiraderos de vapor en el suelo (dos por sección, desfasados: aviso
## luminoso de 1 s antes de cada chorro), puentes móviles sobre los fosos,
## desprendimientos de rocas y arqueros, magos y lanceros. Control en la
## sección 4 y hierbas en las secciones 2, 5 y 7.

const LEVEL_WIDTH := 15000.0
const START_WIDTH := 1400.0
const SECTION_START_X := 1700.0
const SECTION_STEP := 1300.0
const SECTION_WIDTH := 1000.0
const SECTION_COUNT := 9
const FINAL_START_X := 13400.0
const PORTAL_POSITION := Vector2(14500.0, 580.0)
const TIER_LOW := 548.0
const TIER_HIGH := 440.0
const CHECKPOINT_SECTION := 4
const HERB_SECTIONS := [2, 5, 7]
const MINE_ROCK := Color("#5b4f45")
const MINE_STEP := Color("#7a6a58")


static func section_start(index: int) -> float:
	return SECTION_START_X + float(index) * SECTION_STEP


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelSeventeenGenerated")
	CaveKit.backdrop(world, LEVEL_WIDTH, {
		"top": Color("#1d1512"), "mid": Color("#33251d"), "bottom": Color("#4d3a2b"),
		"far": Color("#3a2c22"), "ceiling": Color("#251a14"), "crystal": Color("#ffb45a"),
	})
	_build_terrain(world)
	for index in SECTION_COUNT:
		_build_section(world, index)
	DesertKit.platform(world, Vector2(1550.0, TIER_LOW), Vector2(110.0, 24.0), MINE_STEP, Platform.Kind.HORIZONTAL, "MineBridgeStart")
	DesertKit.rockfall(world, 1700.0, 13300.0)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_terrain(world: Node2D) -> void:
	DesertKit.ground(world, 0.0, START_WIDTH, MINE_ROCK)
	for index in SECTION_COUNT:
		DesertKit.ground(world, section_start(index), section_start(index) + SECTION_WIDTH, MINE_ROCK)
	DesertKit.ground(world, FINAL_START_X, LEVEL_WIDTH, MINE_ROCK, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneMine")


static func _build_section(world: Node2D, index: int) -> void:
	var x0 := section_start(index)
	var top := DesertKit.GROUND_TOP
	DesertKit.platform(world, Vector2(x0 + 330.0, TIER_LOW), Vector2(200.0, 24.0), MINE_STEP, Platform.Kind.STATIC, "MineStepLow%d" % index)
	DesertKit.platform(world, Vector2(x0 + 640.0, TIER_HIGH), Vector2(200.0, 24.0), MINE_STEP, Platform.Kind.STATIC, "MineStepHigh%d" % index)
	var bridge_kind: Platform.Kind = [Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR, Platform.Kind.STATIC][index % 3]
	DesertKit.platform(world, Vector2(x0 + SECTION_WIDTH + 150.0, TIER_LOW), Vector2(110.0, 24.0), MINE_STEP, bridge_kind, "MineBridge%d" % index)

	# Dos respiraderos desfasados por sección (el segundo arranca 1,6 s después).
	CaveKit.vent(world, x0 + 520.0, top, "MineVentA%d" % index, 0.0)
	CaveKit.vent(world, x0 + 880.0, top, "MineVentB%d" % index, 1.6)

	match index % 3:
		0:
			DesertKit.spearman(world, "MineSpearman%d" % index, x0 + 170.0, top)
			DesertKit.archer(world, "MineArcher%d" % index, x0 + 640.0, TIER_HIGH - 12.0)
		1:
			DesertKit.mage(world, "MineMage%d" % index, x0 + 640.0, TIER_HIGH - 12.0)
		2:
			DesertKit.spearman(world, "MineNarrow%d" % index, x0 + 330.0, TIER_LOW - 12.0, true)
			DesertKit.archer(world, "MineArcherB%d" % index, x0 + 930.0, top)

	if index in HERB_SECTIONS:
		DesertKit.herb(world, x0 + 640.0, TIER_HIGH - 12.0)
	if index == CHECKPOINT_SECTION:
		DesertKit.checkpoint(world, x0 + 80.0, top)
