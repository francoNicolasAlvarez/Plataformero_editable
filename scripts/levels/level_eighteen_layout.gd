class_name LevelEighteenLayout
extends RefCounted
## Nivel 18 (2026-11-18): "CRISTALES" (mundo 4, nivel 3). Tramos a oscuras:
## las secciones 1-3 y 5-7 están dentro de zonas oscuras donde solo se ve el
## círculo de luz del jugador. Puentes circulares, murciélagos, babosas,
## orbes y saltadores explosivos; algún respiradero entre las zonas. Control
## en la sección 4 (iluminada) y hierbas en las secciones 2, 5 y 7.

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
const DARK_SPANS := [[1, 3], [5, 7]]
const SHARD_ROCK := Color("#3f4e6b")
const SHARD_STEP := Color("#6c8bb3")


static func section_start(index: int) -> float:
	return SECTION_START_X + float(index) * SECTION_STEP


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelEighteenGenerated")
	CaveKit.backdrop(world, LEVEL_WIDTH, {
		"top": Color("#0d1426"), "mid": Color("#162a45"), "bottom": Color("#24456a"),
		"far": Color("#1d3552"), "ceiling": Color("#101c33"), "crystal": Color("#9ff0ff"),
	})
	_build_terrain(world)
	for index in SECTION_COUNT:
		_build_section(world, index)
	for span in DARK_SPANS:
		var from_x := section_start(int(span[0])) - 150.0
		var to_x := section_start(int(span[1])) + SECTION_WIDTH + 150.0
		CaveKit.dark_zone(world, from_x, to_x, "DarkZone%d" % int(span[0]))
	DesertKit.platform(world, Vector2(1550.0, TIER_LOW), Vector2(110.0, 24.0), SHARD_STEP, Platform.Kind.CIRCULAR, "ShardBridgeStart")
	DesertKit.bats(world, 5.0, 5.0)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_terrain(world: Node2D) -> void:
	DesertKit.ground(world, 0.0, START_WIDTH, SHARD_ROCK)
	for index in SECTION_COUNT:
		DesertKit.ground(world, section_start(index), section_start(index) + SECTION_WIDTH, SHARD_ROCK)
	DesertKit.ground(world, FINAL_START_X, LEVEL_WIDTH, SHARD_ROCK, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneCrystals")


static func _build_section(world: Node2D, index: int) -> void:
	var x0 := section_start(index)
	var top := DesertKit.GROUND_TOP
	DesertKit.platform(world, Vector2(x0 + 330.0, TIER_LOW), Vector2(200.0, 24.0), SHARD_STEP, Platform.Kind.STATIC, "ShardStepLow%d" % index)
	DesertKit.platform(world, Vector2(x0 + 640.0, TIER_HIGH), Vector2(200.0, 24.0), SHARD_STEP, Platform.Kind.STATIC, "ShardStepHigh%d" % index)
	DesertKit.platform(world, Vector2(x0 + SECTION_WIDTH + 150.0, TIER_LOW), Vector2(110.0, 24.0), SHARD_STEP, Platform.Kind.CIRCULAR, "ShardBridge%d" % index)

	match index % 3:
		0:
			DesertKit.slug(world, "ShardSlug%d" % index, x0 + 600.0, top)
			DesertKit.spearman(world, "ShardSpearman%d" % index, x0 + 200.0, top)
		1:
			DesertKit.jumper(world, "ShardJumper%d" % index, x0 + 820.0, top)
			DesertKit.orb(world, "ShardOrb%d" % index, Vector2(x0 + SECTION_WIDTH + 150.0, 400.0), false)
		2:
			DesertKit.archer(world, "ShardArcher%d" % index, x0 + 640.0, TIER_HIGH - 12.0)
			DesertKit.slug(world, "ShardSlugB%d" % index, x0 + 880.0, top, index == 5)
	if index == 3 or index == 7:
		CaveKit.vent(world, x0 + 520.0, top, "ShardVent%d" % index, 0.0)

	if index in HERB_SECTIONS:
		DesertKit.herb(world, x0 + 640.0, TIER_HIGH - 12.0)
	if index == CHECKPOINT_SECTION:
		DesertKit.checkpoint(world, x0 + 80.0, top)
