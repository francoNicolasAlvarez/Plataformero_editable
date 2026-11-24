class_name LevelSixteenLayout
extends RefCounted
## Nivel 16 (2026-11-18): "GRUTA" (mundo 4, nivel 1). Presenta las plataformas
## que se derrumban: diez tramos de suelo separados por fosos de 300 px que se
## cruzan por una plataforma que cae al pisarla (aviso de 0,6 s). Enemigos
## suaves (lanceros, arqueros, babosas, orbes y algún mago). Un control en la
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


static func section_start(index: int) -> float:
	return SECTION_START_X + float(index) * SECTION_STEP


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelSixteenGenerated")
	CaveKit.backdrop(world, LEVEL_WIDTH, {
		"top": Color("#14122a"), "mid": Color("#262245"), "bottom": Color("#3a3560"),
		"far": Color("#2a2646"), "ceiling": Color("#1b1832"), "crystal": CaveKit.CRYSTAL,
	})
	_build_terrain(world)
	for index in SECTION_COUNT:
		_build_section(world, index)
	CaveKit.crumbling(world, Vector2(1550.0, TIER_LOW), "CrumblingStart")
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_terrain(world: Node2D) -> void:
	DesertKit.ground(world, 0.0, START_WIDTH, CaveKit.ROCK)
	for index in SECTION_COUNT:
		DesertKit.ground(world, section_start(index), section_start(index) + SECTION_WIDTH, CaveKit.ROCK)
	DesertKit.ground(world, FINAL_START_X, LEVEL_WIDTH, CaveKit.ROCK, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneGrotto")


static func _build_section(world: Node2D, index: int) -> void:
	var x0 := section_start(index)
	var top := DesertKit.GROUND_TOP
	DesertKit.platform(world, Vector2(x0 + 330.0, TIER_LOW), Vector2(200.0, 24.0), CaveKit.STEP, Platform.Kind.STATIC, "GrottoStepLow%d" % index)
	DesertKit.platform(world, Vector2(x0 + 640.0, TIER_HIGH), Vector2(200.0, 24.0), CaveKit.STEP, Platform.Kind.STATIC, "GrottoStepHigh%d" % index)
	CaveKit.crumbling(world, Vector2(x0 + SECTION_WIDTH + 150.0, TIER_LOW), "Crumbling%d" % index)

	match index % 3:
		0:
			DesertKit.spearman(world, "GrottoSpearman%d" % index, x0 + 250.0, top)
			if index > 0:
				DesertKit.spike(world, x0 + 900.0, top)
		1:
			DesertKit.archer(world, "GrottoArcher%d" % index, x0 + 640.0, TIER_HIGH - 12.0)
			DesertKit.slug(world, "GrottoSlug%d" % index, x0 + 820.0, top)
		2:
			DesertKit.orb(world, "GrottoOrb%d" % index, Vector2(x0 + SECTION_WIDTH + 150.0, 380.0), index == 5)
			DesertKit.spearman(world, "GrottoNarrow%d" % index, x0 + 330.0, TIER_LOW - 12.0, true)
	if index == 4 or index == 7:
		DesertKit.mage(world, "GrottoMage%d" % index, x0 + 900.0, top)

	if index in HERB_SECTIONS:
		DesertKit.herb(world, x0 + 640.0, TIER_HIGH - 12.0)
	if index == CHECKPOINT_SECTION:
		DesertKit.checkpoint(world, x0 + 80.0, top)
