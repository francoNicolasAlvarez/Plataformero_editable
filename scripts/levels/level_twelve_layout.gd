class_name LevelTwelveLayout
extends RefCounted
## Nivel 12 (2026-11-17): "DUNAS" (mundo 3, nivel 2). Tormenta de arena sobre
## diez tramos de suelo separados por fosos de 300 px, con escalones y un
## puente sobre cada foso (fijo, de vaivén o circular). El viento cambia de
## sentido en tres tramos. Enemigos cuerpo a cuerpo y de salto: lanceros de
## patrulla, saltadores explosivos y orbes sobre los fosos, más arqueros y
## magos. Un control en la sección 5 y hierbas en las secciones 2, 5 y 8.

const LEVEL_WIDTH := 16600.0
const START_WIDTH := 1400.0
const SECTION_START_X := 1700.0
const SECTION_STEP := 1300.0
const SECTION_WIDTH := 1000.0
const SECTION_COUNT := 10
const FINAL_START_X := 14700.0
const PORTAL_POSITION := Vector2(16000.0, 580.0)
const TIER_LOW := 548.0
const TIER_HIGH := 440.0
const CHECKPOINT_SECTION := 5
const HERB_SECTIONS := [2, 5, 8]
const SAND := Color("#d6b36a")
const SAND_DARK := Color("#a98445")
const WIND := [[1500.0, 6000.0, 100.0], [6000.0, 10200.0, -125.0], [10200.0, 14400.0, 110.0]]


static func section_start(index: int) -> float:
	return SECTION_START_X + float(index) * SECTION_STEP


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelTwelveGenerated")
	DesertKit.sky(world, LEVEL_WIDTH, {
		"top": Color("#b9783f"), "mid": Color("#e3a965"), "bottom": Color("#f3dba5"),
		"sun": Color(1.0, 0.82, 0.5, 0.9), "cloud": Color(0.95, 0.8, 0.6, 0.75),
		"far_style": "dunes", "far_colors": [Color("#c89a58"), Color("#bd8d4d"), Color("#b38244")],
		"base": Color("#b38244"),
	})
	_build_terrain(world)
	for index in SECTION_COUNT:
		_build_section(world, index)
	DesertKit.wind(world, WIND, 6.0)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_terrain(world: Node2D) -> void:
	DesertKit.ground(world, 0.0, START_WIDTH, SAND)
	for index in SECTION_COUNT:
		DesertKit.ground(world, section_start(index), section_start(index) + SECTION_WIDTH, SAND)
	DesertKit.ground(world, FINAL_START_X, LEVEL_WIDTH, SAND, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneDunes")


static func _build_section(world: Node2D, index: int) -> void:
	var x0 := section_start(index)
	var top := DesertKit.GROUND_TOP
	DesertKit.platform(world, Vector2(x0 + 330.0, TIER_LOW), Vector2(200.0, 24.0), SAND_DARK, Platform.Kind.STATIC, "DuneStepLow%d" % index)
	DesertKit.platform(world, Vector2(x0 + 640.0, TIER_HIGH), Vector2(200.0, 24.0), SAND_DARK, Platform.Kind.STATIC, "DuneStepHigh%d" % index)
	var bridge_kind: Platform.Kind = [Platform.Kind.STATIC, Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR][index % 3]
	DesertKit.platform(world, Vector2(x0 + SECTION_WIDTH + 150.0, TIER_LOW), Vector2(110.0, 24.0), SAND_DARK, bridge_kind, "DuneBridge%d" % index)

	match index % 4:
		0:
			DesertKit.spearman(world, "DuneSpearman%da" % index, x0 + 200.0, top)
			if index > 0:
				DesertKit.spearman(world, "DuneSpearman%db" % index, x0 + 750.0, top)
				DesertKit.spike(world, x0 + 930.0, top)
		1:
			DesertKit.jumper(world, "DuneJumper%d" % index, x0 + 820.0, top)
			DesertKit.archer(world, "DuneArcher%d" % index, x0 + 640.0, TIER_HIGH - 12.0)
		2:
			DesertKit.orb(world, "DuneOrb%d" % index, Vector2(x0 + SECTION_WIDTH + 150.0, 380.0), index == 6)
			DesertKit.saw(world, Vector2(x0 + 880.0, top - 30.0), 80.0, 1.6)
			DesertKit.spearman(world, "DuneNarrowSpearman%d" % index, x0 + 330.0, TIER_LOW - 12.0, true)
		3:
			DesertKit.jumper(world, "DuneLongJumper%d" % index, x0 + 850.0, top, true)
			DesertKit.mage(world, "DuneMage%d" % index, x0 + 640.0, TIER_HIGH - 12.0)

	if index in HERB_SECTIONS:
		DesertKit.herb(world, x0 + 640.0, TIER_HIGH - 12.0)
	if index == CHECKPOINT_SECTION:
		DesertKit.checkpoint(world, x0 + 80.0, top)
