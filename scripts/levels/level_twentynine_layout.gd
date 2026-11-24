class_name LevelTwentynineLayout
extends RefCounted
## Nivel 29 (2026-11-24): "CATAPULTAS" (6-4). Tres catapultas marcan en el
## suelo, con un círculo rojo, dónde caerá su peñasco, siempre por delante del
## jugador. Tres muros de 330 px cortan el camino: cada uno se supera con un
## objeto sujetable (caja como peldaño o resorte para saltar más). Soldados
## sueltos se derriban lanzándoles rocas con Ctrl (hay reposición).

const WIDTH := 9000.0
const G := FortressKit.GROUND
## Muros de 330 px (ver nivel 26: el doble salto llega a ~312 px).
const WALL_TOP := 310.0
const PORTAL_POSITION := Vector2(8800.0, G - 60.0)
const CATAPULTS := [[1600.0, 800.0, 3000.0], [4500.0, 3400.0, 5900.0], [7400.0, 6300.0, 8700.0]]
const WALLS := [2500.0, 5200.0, 8000.0]


static func route() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(150.0, G - 24.0)])
	for x in WALLS:
		points.append(Vector2(float(x) - 80.0, G - 24.0))
		points.append(Vector2(float(x), WALL_TOP - 24.0))
	points.append(Vector2(PORTAL_POSITION.x, G - 24.0))
	return points


static func build(level: Node2D) -> void:
	var world := FortressKit.start(level, "LevelTwentynineGenerated", WIDTH)
	DesertKit.ground(world, 0.0, WIDTH, TowerKit.STONE_DARK)
	for i in CATAPULTS.size():
		var data: Array = CATAPULTS[i]
		FortressKit.catapult(world, float(data[0]), float(data[1]), float(data[2]), "Catapult%d" % i, 0.8 * float(i))
	# Muros con su objeto de paso (la caja y el resorte están 350-450 px antes).
	var wall_items := [GrabItem.Kind.CRATE, GrabItem.Kind.SPRING, GrabItem.Kind.CRATE]
	for i in WALLS.size():
		var x: float = WALLS[i]
		FortressKit.wall(world, x, WALL_TOP, "CatapultWall%d" % i)
		FortressKit.item(world, wall_items[i], Vector2(x - 420.0, G - 19.0), "CatapultItem%d" % i, 10.0 if wall_items[i] == GrabItem.Kind.SPRING else 0.0)
		# Un soldado detrás de cada muro (se derriba con una roca).
		DesertKit.spearman(world, "CatapultSpearman%d" % i, x + 500.0, G)
		DesertKit.archer(world, "CatapultArcher%d" % i, x + 900.0, G)
		FortressKit.item(world, GrabItem.Kind.ROCK, Vector2(x + 250.0, G - 14.0), "CatapultRock%d" % i, 8.0)
	DesertKit.checkpoint(world, 4700.0, G)
	DesertKit.herb(world, 3600.0, G)
	DesertKit.herb(world, 6600.0, G)
	FortressKit.finish(level, world, WIDTH, Vector2(150.0, G - 30.0), PORTAL_POSITION, route())
