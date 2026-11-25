class_name LevelTwentysixLayout
extends RefCounted
## Nivel 26 (2026-11-24): "FOSO" (6-1). Dos fosos cerrados por puentes
## levadizos que se bajan SALTANDO sobre un botón de suelo:
##  - Foso 1: el botón está antes del puente; un arquero con escudo (candado del
##    canal A) dispara desde la otra orilla y cae al pulsarlo.
##  - Foso 2: su botón (canal C) está arriba de un muro alto; hay que coger una
##    CAJA, dejarla junto al muro (peldaño) y trepar. Pulsarlo baja el puente y
##    elimina al mago guardián.
## Al cruzar, el puente sube tras 10 s; hay que cruzar sin entretenerse.

const WIDTH := 7400.0
const G := FortressKit.GROUND
const BRIDGE_A_X := 1500.0
const BRIDGE_C_X := 4300.0
const WALL_X := 2910.0
## Muro de 330 px: el doble salto llega a ~312 px; con la caja (38 px) a ~350.
const WALL_TOP := 310.0
const BRIDGE_LENGTH := 300.0
const PORTAL_POSITION := Vector2(7200.0, G - 60.0)


static func route() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(150.0, G - 24.0), Vector2(1100.0, G - 24.0), Vector2(BRIDGE_A_X + BRIDGE_LENGTH, G - 24.0),
		Vector2(2300.0, G - 24.0), Vector2(3200.0, WALL_TOP - 24.0), Vector2(4000.0, G - 24.0),
		Vector2(4300.0 + BRIDGE_LENGTH, G - 24.0), Vector2(PORTAL_POSITION.x, G - 24.0),
	])


static func build(level: Node2D) -> void:
	var world := FortressKit.start(level, "LevelTwentysixGenerated", WIDTH)
	# Orilla de salida y primer foso.
	DesertKit.ground(world, 0.0, BRIDGE_A_X, TowerKit.STONE_DARK)
	FortressKit.button(world, Vector2(1100.0, G), "A", "MoatButtonA")
	DesertKit.spearman(world, "MoatSpearman0", 820.0, G)
	FortressKit.bridge(world, Vector2(BRIDGE_A_X, G + 12.0), "A", "DrawbridgeA", BRIDGE_LENGTH)
	DesertKit.ground(world, BRIDGE_A_X + BRIDGE_LENGTH, BRIDGE_C_X, TowerKit.STONE_DARK)
	var guard := DesertKit.archer(world, "MoatGuardA", 2150.0, G)
	FortressKit.lock(world, guard, "A", "MoatLockA")
	# Muro con caja: el botón del segundo puente está arriba.
	FortressKit.item(world, GrabItem.Kind.CRATE, Vector2(2350.0, G - 19.0), "MoatCrate")
	FortressKit.wall(world, WALL_X, WALL_TOP, "MoatWall")
	FortressKit.ledge(world, WALL_X + 30.0, 3380.0, WALL_TOP, "MoatLedge")
	FortressKit.button(world, Vector2(3250.0, WALL_TOP), "C", "MoatButtonC")
	DesertKit.herb(world, 3100.0, WALL_TOP)
	DesertKit.checkpoint(world, 3700.0, G)
	DesertKit.spearman(world, "MoatSpearman1", 3900.0, G)
	# Segundo foso y tramo final.
	FortressKit.bridge(world, Vector2(BRIDGE_C_X, G + 12.0), "C", "DrawbridgeC", BRIDGE_LENGTH)
	DesertKit.ground(world, BRIDGE_C_X + BRIDGE_LENGTH, WIDTH, TowerKit.STONE_DARK)
	var mage := DesertKit.mage(world, "MoatGuardC", 4950.0, G)
	FortressKit.lock(world, mage, "C", "MoatLockC")
	DesertKit.herb(world, 5300.0, G)
	DesertKit.spearman(world, "MoatSpearman2", 5700.0, G)
	DesertKit.archer(world, "MoatArcher1", 6400.0, G)
	DesertKit.spearman(world, "MoatSpearman3", 6800.0, G)
	# Más enemigos (espaciados), plataformas altas con trampas y tiradores.
	DesertKit.spearman(world, "MoatSpearman4", 350.0, G)
	DesertKit.mage(world, "MoatMage0", 1350.0, G)
	DesertKit.spearman(world, "MoatSpearman5", 2600.0, G)
	DesertKit.archer(world, "MoatArcher2", 3500.0, G)
	DesertKit.slug(world, "MoatSlug0", 4100.0, G)
	DesertKit.mage(world, "MoatMage1", 6050.0, G)
	DesertKit.slug(world, "MoatSlug1", 7050.0, G)
	FortressKit.high_row(world, "Moat0", [[650.0, 480.0, 220.0, "archer", ""], [1000.0, 380.0, 200.0, "", "spike"], [1950.0, 470.0, 220.0, "mage", ""],
		[2300.0, 370.0, 200.0, "", "mine"], [3800.0, 470.0, 220.0, "archer", ""], [4150.0, 370.0, 200.0, "", "mine"]])
	FortressKit.high_row(world, "Moat1", [[5250.0, 480.0, 220.0, "mage", ""], [5700.0, 380.0, 200.0, "archer", ""], [6100.0, 480.0, 200.0, "", "spike"],
		[6500.0, 380.0, 200.0, "mage", ""]])
	FortressKit.aerial_saws(world, "Moat", [[1750.0, 520.0], [5200.0, 540.0], [6450.0, 540.0]])
	FortressKit.finish(level, world, WIDTH, Vector2(150.0, G - 30.0), PORTAL_POSITION, route())
