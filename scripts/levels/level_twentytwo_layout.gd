class_name LevelTwentytwoLayout
extends RefCounted
## Nivel 22 (2026-11-23): "CAMPANARIO" (mundo 5, nivel 2). Estructura de
## TORRE: cinco pisos de un campanario unidos por corrientes ascendentes
## (UpdraftZone). En cada piso se cruza el pasillo de un lado al otro, con
## prensas colgando del techo y enemigos, y se sube volando por el hueco de la
## losa; los huecos alternan derecha e izquierda. Idea nueva: la corriente
## ascendente (se sube sin plataformas y se sale hacia un lado). Cada corriente
## llega hasta el techo del piso siguiente (la cara inferior de la losa de
## arriba), que sigue siendo sólida: no se atraviesa. Dos balcones opcionales
## con hierba (escalones) aparecen fuera del camino principal. Obstáculos: prensas,
## sierras de suelo, techos con espinas (pegados a la losa de arriba, junto a
## la salida de cada corriente: sin vigas ni cadenas) y varios enemigos por piso.

const WIDTH := 2200.0
const FLOOR_PITCH := 420.0
const FLOOR0_TOP := 2300.0
const FLOOR_COUNT := 5
const SLAB_THICKNESS := 40.0
const HOLE_WIDTH := 280.0
const HOLE_RIGHT := [1800.0, 2080.0]
const HOLE_LEFT := [120.0, 400.0]
const LIMIT_BOTTOM := 2400
const CRUSHER_MOUNT := 340.0
const CRUSHER_DROP := 276.0
## Alto de la corriente del último piso (no hay losa encima).
const TOP_DRAFT_HEIGHT := 400.0
const SPIKE_HEIGHT := 50.0

## Sierras de suelo: [piso, x, recorrido].
const SAWS := [[0, 720.0, 60.0], [0, 1450.0, 60.0], [1, 780.0, 70.0], [1, 1250.0, 60.0], [2, 540.0, 60.0], [2, 760.0, 60.0], [3, 1000.0, 60.0], [4, 500.0, 80.0], [4, 1250.0, 60.0]]
## Techos con espinas pegados a la losa de arriba, junto a la salida de cada
## corriente: [corriente k, ancho, separación respecto a la anterior]. Quien
## sale volando pegado al techo se las encuentra: hay que salir más abajo.
const SPIKE_CEILINGS := [[1, 160.0, 20.0], [1, 120.0, 300.0], [2, 160.0, 20.0], [2, 120.0, 300.0], [3, 160.0, 20.0], [3, 120.0, 300.0]]

## Crusher x por piso (0..4).
const CRUSHERS := {
	0: [560.0, 1250.0],
	1: [900.0, 1500.0],
	2: [420.0, 880.0, 1550.0],
	3: [800.0, 1300.0],
	4: [700.0, 1500.0],
}


static func floor_top(floor_index: int) -> float:
	return FLOOR0_TOP - FLOOR_PITCH * float(floor_index)


## Altura (y) donde termina la corriente que sube al piso `floor_index`: la
## cara inferior de la losa del piso siguiente (su techo); en el último piso,
## `TOP_DRAFT_HEIGHT` px sobre el suelo.
static func draft_top(floor_index: int) -> float:
	if floor_index < FLOOR_COUNT - 1:
		return floor_top(floor_index + 1) + SLAB_THICKNESS
	return floor_top(floor_index) - TOP_DRAFT_HEIGHT


## Hueco de la losa del piso `floor_index` (1..4): impares a la derecha,
## pares a la izquierda.
static func hole(floor_index: int) -> Array:
	return HOLE_RIGHT if floor_index % 2 == 1 else HOLE_LEFT


## Centro x de la corriente que sube del piso `floor_index - 1` al piso `floor_index`.
static func shaft_center_x(floor_index: int) -> float:
	var span := hole(floor_index)
	return (float(span[0]) + float(span[1])) * 0.5


## Camino principal (centros de los pasillos y corrientes).
static func route() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(150.0, floor_top(0) - 24.0)])
	for k in range(1, FLOOR_COUNT):
		var shaft_x := shaft_center_x(k)
		points.append(Vector2(shaft_x, floor_top(k - 1) - 24.0))
		points.append(Vector2(shaft_x, floor_top(k) - 70.0))
	points.append(Vector2(WIDTH - 150.0, floor_top(FLOOR_COUNT - 1) - 24.0))
	return points


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelTwentytwoGenerated")
	TowerKit.sky(world, Rect2(-300.0, -200.0, WIDTH + 600.0, 2900.0))
	_build_structure(world)
	for k in range(1, FLOOR_COUNT):
		var below := floor_top(k - 1)
		var zone_top := draft_top(k)
		TowerKit.updraft(world, Vector2(shaft_center_x(k), (below + zone_top) * 0.5), Vector2(HOLE_WIDTH - 20.0, below - zone_top), "BellDraft%d" % k)
	for floor_index in CRUSHERS:
		for i in CRUSHERS[floor_index].size():
			var x: float = CRUSHERS[floor_index][i]
			var mount_y := floor_top(int(floor_index)) - CRUSHER_MOUNT
			TowerKit.crusher(world, Vector2(x, mount_y), "BellCrusher%d_%d" % [floor_index, i], CRUSHER_DROP)
	_build_enemies(world)
	_build_hazards(world)
	_build_balconies(world)
	DesertKit.checkpoint(world, WIDTH * 0.5, floor_top(2))
	DesertKit.herb(world, 1000.0, floor_top(3))
	DesertKit.place_player(level, Vector2(150.0, floor_top(0) - 30.0))
	TowerKit.portal(level, Vector2(WIDTH - 150.0, floor_top(FLOOR_COUNT - 1) - 60.0))
	TowerKit.camera(level, Rect2(0.0, 0.0, WIDTH, float(LIMIT_BOTTOM)), true)
	level.call("set_route", route())


static func _build_structure(world: Node2D) -> void:
	# Suelo continuo del piso 0 y losas con hueco para los pisos 1-4.
	TowerKit.slab(world, 0.0, WIDTH, floor_top(0), 100.0, [], "BellFloor0", TowerKit.STONE_DARK)
	for k in range(1, FLOOR_COUNT):
		TowerKit.slab(world, 0.0, WIDTH, floor_top(k), SLAB_THICKNESS, [hole(k)], "BellFloor%d" % k)
	var top_y := floor_top(FLOOR_COUNT - 1) - 600.0
	var bottom_y := floor_top(0) + 100.0
	TowerKit.block(world, Rect2(-40.0, top_y, 40.0, bottom_y - top_y), "BellWallLeft")
	TowerKit.block(world, Rect2(WIDTH, top_y, 40.0, bottom_y - top_y), "BellWallRight")


static func _build_enemies(world: Node2D) -> void:
	DesertKit.slug(world, "BellSlug0", 420.0, floor_top(0))
	DesertKit.spearman(world, "BellSpearman0", 880.0, floor_top(0))
	DesertKit.mage(world, "BellMage0", 1650.0, floor_top(0))
	DesertKit.archer(world, "BellArcher1", 640.0, floor_top(1))
	DesertKit.mage(world, "BellMage1", 1150.0, floor_top(1))
	DesertKit.spearman(world, "BellSpearman1", 1500.0, floor_top(1))
	DesertKit.slug(world, "BellSlug2", 700.0, floor_top(2))
	DesertKit.mage(world, "BellMage2", 1250.0, floor_top(2))
	DesertKit.mage(world, "BellMage3", 520.0, floor_top(3))
	DesertKit.spearman(world, "BellSpearman3", 1300.0, floor_top(3))
	DesertKit.archer(world, "BellArcher3", 1700.0, floor_top(3))
	DesertKit.spearman(world, "BellSpearman4", 950.0, floor_top(4))
	DesertKit.archer(world, "BellArcher4", 1100.0, floor_top(4))
	DesertKit.mage(world, "BellMage4", 1650.0, floor_top(4))


## Sierras de suelo y techos con espinas.
static func _build_hazards(world: Node2D) -> void:
	for i in SAWS.size():
		var entry: Array = SAWS[i]
		var saw := DesertKit.saw(world, Vector2(float(entry[1]), floor_top(int(entry[0])) - 30.0), float(entry[2]), 1.5)
		saw.name = "BellSaw%d" % i
	for i in SPIKE_CEILINGS.size():
		var entry: Array = SPIKE_CEILINGS[i]
		var k := int(entry[0])
		var width := float(entry[1])
		# Hacia el interior del pasillo desde el borde de la corriente; las
		# espinas sobrantes de la primera ya están en `previous`.
		var direction := -1.0 if k % 2 == 1 else 1.0
		var edge := shaft_center_x(k) + direction * (HOLE_WIDTH * 0.5 + float(entry[2]))
		var previous := 0.0
		if i > 0 and int(SPIKE_CEILINGS[i - 1][0]) == k:
			previous = float(SPIKE_CEILINGS[i - 1][1])
			edge += direction * (previous + 20.0)
		var underside := floor_top(k + 1) + SLAB_THICKNESS
		TowerKit.spike_ceiling(world, edge + direction * width * 0.5, underside + SPIKE_HEIGHT * 0.5, width, SPIKE_HEIGHT, "BellCeiling%d" % i)


## Dos balcones opcionales: un escalón bajo y una repisa alta con hierba.
static func _build_balconies(world: Node2D) -> void:
	# Lejos de las aberturas (a media planta) para que no sirvan de trampolín.
	var floor_a := floor_top(0)
	TowerKit.block(world, Rect2(820.0, floor_a - 110.0, 150.0, 24.0), "BellBalconyA_Step", TowerKit.STONE_LIGHT)
	TowerKit.block(world, Rect2(1010.0, floor_a - 230.0, 170.0, 24.0), "BellBalconyA_Ledge", TowerKit.STONE_LIGHT)
	DesertKit.herb(world, 1095.0, floor_a - 230.0)
	var floor_b := floor_top(2)
	TowerKit.block(world, Rect2(1000.0, floor_b - 110.0, 150.0, 24.0), "BellBalconyB_Step", TowerKit.STONE_LIGHT)
	TowerKit.block(world, Rect2(1170.0, floor_b - 230.0, 170.0, 24.0), "BellBalconyB_Ledge", TowerKit.STONE_LIGHT)
	DesertKit.herb(world, 1255.0, floor_b - 230.0)
