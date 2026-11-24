class_name LevelTwentyLayout
extends RefCounted
## Nivel 20 (2026-11-18): "DERRUMBE" (mundo 4, final). La cueva se viene
## abajo: cinco cadenas de seis plataformas que se derrumban separan cuatro
## islas de descanso (arquero, control con hierba, mago con bruto, saltador y
## babosa). Caen rocas sobre todo el recorrido, hay murciélagos, un centinela
## superior y el último tramo transcurre a oscuras. Una isla final custodiada
## por un bruto, una babosa de doble salto y lanceros lleva al portal.

const LEVEL_WIDTH := 16000.0
const START_WIDTH := 1300.0
const CHAIN_FIRST_X := 1600.0
const CRUMBLE_STEP := 280.0
const CHAIN_LENGTH := 6
const CHAIN_PERIOD := 2500.0
const ISLAND_WIDTH := 520.0
const ISLAND_COUNT := 4
const FINAL_START_X := 13300.0
const PORTAL_POSITION := Vector2(15400.0, 580.0)
const ISLAND_TOP := 560.0
const CRUMBLE_TIERS := [548.0, 500.0]
const CHECKPOINT_ISLAND := 1
const DARK_FROM := 9000.0
const DARK_TO := 13400.0
const RUBBLE := Color("#51485f")
const RUBBLE_STEP := Color("#7a6f8f")


## Centro de la plataforma `k` (0..5) de la cadena `chain` (0..4).
static func crumble_center(chain: int, k: int) -> Vector2:
	var x := chain_start(chain) + float(k) * CRUMBLE_STEP
	return Vector2(x, CRUMBLE_TIERS[(chain + k) % CRUMBLE_TIERS.size()])


## Cada cadena (1400 px de centros + 75 de borde) va seguida de un hueco de
## 215 px, una isla de 520 px y otro hueco de 215 px: periodo de 2500 px.
static func chain_start(chain: int) -> float:
	return CHAIN_FIRST_X + float(chain) * CHAIN_PERIOD


static func island_center_x(island: int) -> float:
	return chain_start(island) + 1950.0


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelTwentyGenerated")
	CaveKit.backdrop(world, LEVEL_WIDTH, {
		"top": Color("#1c0f16"), "mid": Color("#3a1d27"), "bottom": Color("#5a2a33"),
		"far": Color("#3d2029"), "ceiling": Color("#240f17"), "crystal": Color("#ff8a6a"),
	})
	DesertKit.ground(world, 0.0, START_WIDTH, RUBBLE)
	DesertKit.ground(world, FINAL_START_X, LEVEL_WIDTH, RUBBLE, 120.0)
	DesertKit.fall_zone(world, LEVEL_WIDTH, "FallZoneCollapse")
	for chain in ISLAND_COUNT + 1:
		for k in CHAIN_LENGTH:
			CaveKit.crumbling(world, crumble_center(chain, k), "Collapse%d_%d" % [chain, k])
	for island in ISLAND_COUNT:
		_build_island(world, island)
	CaveKit.dark_zone(world, DARK_FROM, DARK_TO, "DarkZoneCollapse", 270.0)
	DesertKit.rockfall(world, 1700.0, 13300.0)
	DesertKit.bats(world, 5.0, 5.0)
	DesertKit.sentry(world)
	_build_final_island(world)
	DesertKit.place_player(level)
	DesertKit.finish(level, PORTAL_POSITION, LEVEL_WIDTH)


static func _build_island(world: Node2D, island: int) -> void:
	var x := island_center_x(island)
	DesertKit.platform(world, Vector2(x, ISLAND_TOP + 40.0), Vector2(ISLAND_WIDTH, 80.0), RUBBLE_STEP, Platform.Kind.STATIC, "CollapseIsland%d" % island)
	match island:
		0:
			DesertKit.archer(world, "CollapseArcher0", x + 150.0, ISLAND_TOP)
			CaveKit.vent(world, x - 120.0, ISLAND_TOP, "CollapseVent0", 0.0)
		1:
			DesertKit.checkpoint(world, x - 140.0, ISLAND_TOP)
			DesertKit.herb(world, x + 120.0, ISLAND_TOP)
		2:
			DesertKit.mage(world, "CollapseMage2", x - 150.0, ISLAND_TOP)
			DesertKit.brute_post(world, "CollapseBrute2", x + 40.0, x + 150.0, ISLAND_TOP)
		3:
			DesertKit.jumper(world, "CollapseJumper3", x + 140.0, ISLAND_TOP)
			DesertKit.slug(world, "CollapseSlug3", x - 140.0, ISLAND_TOP)


static func _build_final_island(world: Node2D) -> void:
	var top := DesertKit.GROUND_TOP
	DesertKit.brute_post(world, "CollapseFinalBrute", FINAL_START_X + 520.0, FINAL_START_X + 640.0, top)
	DesertKit.slug(world, "CollapseFinalSlug", FINAL_START_X + 940.0, top, true)
	DesertKit.spearman(world, "CollapseGuardA", FINAL_START_X + 1250.0, top)
	DesertKit.spearman(world, "CollapseGuardB", FINAL_START_X + 1500.0, top, true)
