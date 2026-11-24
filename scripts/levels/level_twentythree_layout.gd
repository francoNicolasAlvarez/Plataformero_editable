class_name LevelTwentythreeLayout
extends RefCounted
## Nivel 23 (2026-11-23): "PUENTES" (mundo 5, nivel 3). Estructura de
## BIFURCACIÓN: tras la isla de salida el camino se parte en dos y vuelve a
## unirse en la isla del control.
##  - Ruta ALTA (más corta): una escalera de plataformas TEMPORIZADAS que
##    aparecen y desaparecen con fases desfasadas (hay que seguir el ritmo).
##    Si se cae, se aterriza en la ruta baja (no es mortal).
##  - Ruta BAJA (más larga y segura): puente de CINTAS TRANSPORTADORAS de
##    sentidos alternos, con una sierra y enemigos.
## Después del control, un tramo final mixto (cintas sobre un abismo) lleva
## al portal. Ideas nuevas: plataforma temporizada y cinta transportadora.

const WIDTH := 9800.0
const GROUND_Y := 640.0
const START_END := 1500.0
const MERGE_START := 5800.0
const MERGE_END := 6800.0
const FINAL_START := 6800.0
const PORTAL_POSITION := Vector2(9500.0, 580.0)
const BELT_LENGTH := 600.0
const BELT_THICKNESS := 40.0
const BELT_SPEED := 160.0
const CRUSHER_MOUNT := 170.0
const CRUSHER_DROP := 94.0
const UPPER_COUNT := 14
const UPPER_FIRST_X := 1750.0
const UPPER_STEP := 300.0
const UPPER_WIDTH := 150.0
const UPPER_SOLID := 2.4
const UPPER_GONE := 1.5
const FINAL_BELTS := 3
const FINAL_BELT_LENGTH := 420.0
const FINAL_GAP := 180.0
const FINAL_GROUND_START := 8700.0
const SKY := {"top": Color("#7fb4e8"), "mid": Color("#bfdcf4"), "bottom": Color("#eaf4fb")}


## Centro de la plataforma temporizada `i` de la ruta alta (la altura sube
## en los primeros pasos y baja en los últimos).
static func upper_center(i: int) -> Vector2:
	var x := UPPER_FIRST_X + UPPER_STEP * float(i)
	var levels := [540.0, 490.0, 440.0, 410.0, 440.0, 400.0, 380.0, 410.0, 380.0, 420.0, 460.0, 500.0, 540.0, 580.0]
	return Vector2(x, float(levels[i % levels.size()]))


## Fase (segundos) de la plataforma `i`: se desfasan para que la escalera
## "respire" y siempre haya una sólida próxima.
static func upper_phase(i: int) -> float:
	return float(i % 4) * 0.9


## Tramo de cinta `i` de la ruta baja (centro x), sentido alterno.
static func belt_center(i: int) -> Vector2:
	return Vector2(START_END + BELT_LENGTH * (float(i) + 0.5), GROUND_Y + BELT_THICKNESS * 0.5)


static func belt_count() -> int:
	return int((MERGE_START - START_END) / BELT_LENGTH)


static func belt_speed(i: int) -> float:
	return BELT_SPEED if i % 2 == 0 else -BELT_SPEED


static func final_belt_center(i: int) -> Vector2:
	var start := FINAL_START + 100.0 + (FINAL_BELT_LENGTH + FINAL_GAP) * float(i)
	return Vector2(start + FINAL_BELT_LENGTH * 0.5, GROUND_Y + BELT_THICKNESS * 0.5)


static func route() -> PackedVector2Array:
	# Ruta más corta: la escalera temporizada.
	var points := PackedVector2Array([Vector2(150.0, GROUND_Y - 24.0), Vector2(START_END - 40.0, GROUND_Y - 24.0)])
	for i in UPPER_COUNT:
		var center := upper_center(i)
		points.append(Vector2(center.x, center.y - 24.0))
	points.append(Vector2(MERGE_START + 200.0, GROUND_Y - 24.0))
	points.append(Vector2((MERGE_START + MERGE_END) * 0.5, GROUND_Y - 24.0))
	for i in FINAL_BELTS:
		var center := final_belt_center(i)
		points.append(Vector2(center.x, GROUND_Y - 24.0))
	points.append(Vector2(PORTAL_POSITION.x, GROUND_Y - 24.0))
	return points


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelTwentythreeGenerated")
	TowerKit.sky(world, Rect2(-300.0, -200.0, WIDTH + 600.0, 1300.0), SKY)
	_build_ground(world)
	_build_upper_route(world)
	_build_lower_route(world)
	_build_merge(world)
	_build_final(world)
	TowerKit.fall_zone(world, 780.0, WIDTH, "FallZoneBridges")
	DesertKit.place_player(level, Vector2(150.0, GROUND_Y - 30.0))
	TowerKit.portal(level, PORTAL_POSITION)
	TowerKit.camera(level, Rect2(0.0, 0.0, WIDTH, 720.0), false)
	level.call("set_route", route())


static func _build_ground(world: Node2D) -> void:
	DesertKit.ground(world, 0.0, START_END, TowerKit.STONE_DARK)
	DesertKit.ground(world, MERGE_START, MERGE_END, TowerKit.STONE_DARK)
	DesertKit.ground(world, FINAL_GROUND_START, WIDTH, TowerKit.STONE_DARK)
	DesertKit.archer(world, "BridgeArcher0", 1150.0, GROUND_Y)
	DesertKit.herb(world, 700.0, GROUND_Y)


static func _build_upper_route(world: Node2D) -> void:
	for i in UPPER_COUNT:
		TowerKit.timed(world, upper_center(i), UPPER_WIDTH, "BridgeTimed%d" % i, UPPER_SOLID, UPPER_GONE, upper_phase(i))
	# Un arquero vigila el tramo alto desde un saliente fijo a mitad.
	var perch := upper_center(6) + Vector2(0.0, -230.0)
	DesertKit.platform(world, perch, Vector2(170.0, 24.0), TowerKit.STONE_LIGHT, Platform.Kind.STATIC, "BridgePerch")
	DesertKit.archer(world, "BridgeArcherUpper", perch.x, perch.y - 12.0)


static func _build_lower_route(world: Node2D) -> void:
	for i in belt_count():
		var belt := DesertKit.platform(world, belt_center(i), Vector2(BELT_LENGTH, BELT_THICKNESS), Color("#7e8aa8"), Platform.Kind.STATIC, "BridgeBelt%d" % i)
		belt.conveyor_speed = belt_speed(i)
	DesertKit.spearman(world, "BridgeSpearman", 3100.0, GROUND_Y)
	DesertKit.slug(world, "BridgeSlug", 4500.0, GROUND_Y)
	DesertKit.saw(world, Vector2(3900.0, GROUND_Y - 30.0), 160.0, 1.4)
	# Prensas bajas: no llegan a la escalera alta (el bloque cuelga desde y=470).
	TowerKit.crusher(world, Vector2(2500.0, GROUND_Y - CRUSHER_MOUNT), "BridgeCrusher0", CRUSHER_DROP)
	TowerKit.crusher(world, Vector2(5200.0, GROUND_Y - CRUSHER_MOUNT), "BridgeCrusher1", CRUSHER_DROP)


static func _build_merge(world: Node2D) -> void:
	var middle := (MERGE_START + MERGE_END) * 0.5
	DesertKit.checkpoint(world, middle - 120.0, GROUND_Y)
	DesertKit.herb(world, middle + 140.0, GROUND_Y)
	DesertKit.mage(world, "BridgeMage", MERGE_END - 120.0, GROUND_Y)


static func _build_final(world: Node2D) -> void:
	for i in FINAL_BELTS:
		var belt := DesertKit.platform(world, final_belt_center(i), Vector2(FINAL_BELT_LENGTH, BELT_THICKNESS), Color("#7e8aa8"), Platform.Kind.STATIC, "BridgeFinalBelt%d" % i)
		belt.conveyor_speed = -BELT_SPEED if i % 2 == 0 else BELT_SPEED * 1.5
	DesertKit.saw(world, Vector2(final_belt_center(1).x, GROUND_Y - 110.0), 140.0, 1.7)
	DesertKit.spearman(world, "BridgeGuard", 8950.0, GROUND_Y)
	DesertKit.spearman(world, "BridgeGuard2", 9200.0, GROUND_Y, true)
