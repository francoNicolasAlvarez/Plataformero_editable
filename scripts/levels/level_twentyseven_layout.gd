class_name LevelTwentysevenLayout
extends RefCounted
## Nivel 27 (2026-11-24): "MURALLAS" (6-2). Cañones de pared y gravedad
## invertida:
##  - Tramo 1: tres bloques bajos con cañones que disparan a la altura del
##    jugador; se esquivan saltando o con el impulso.
##  - Pasillo del techo: un foso de 1900 px sin suelo. Una zona de gravedad
##    invertida hace "caer" al jugador hacia un techo de piedra y se camina por
##    debajo, entre dos cañones que disparan a lo largo del pasillo. Al salir de
##    la zona la gravedad vuelve y se aterriza en el suelo.
##  - Tramo final: almenas con arqueros y más cañones.

const WIDTH := 8600.0
const G := FortressKit.GROUND
const PIT_FROM := 2800.0
const PIT_TO := 4700.0
const CEILING_Y := 170.0
const CEILING_THICKNESS := 30.0
const ZONE_FROM := 2750.0
const ZONE_TO := 4750.0
const PORTAL_POSITION := Vector2(8400.0, G - 60.0)


static func route() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(150.0, G - 24.0), Vector2(2400.0, G - 24.0), Vector2(ZONE_FROM + 100.0, CEILING_Y + CEILING_THICKNESS + 24.0),
		Vector2(ZONE_TO - 100.0, CEILING_Y + CEILING_THICKNESS + 24.0), Vector2(5200.0, G - 24.0),
		Vector2(PORTAL_POSITION.x, G - 24.0),
	])


static func build(level: Node2D) -> void:
	var world := FortressKit.start(level, "LevelTwentysevenGenerated", WIDTH)
	DesertKit.ground(world, 0.0, PIT_FROM, TowerKit.STONE_DARK)
	# Tramo 1: bloques bajos con cañón en su cara izquierda (disparan a la altura del pecho).
	for i in 3:
		var x := 1000.0 + 500.0 * float(i)
		FortressKit.wall(world, x, G - 100.0, "BattlementBlock%d" % i, 50.0)
		FortressKit.cannon(world, Vector2(x - 25.0, G - 48.0), -1.0, "BattlementCannon%d" % i, 0.8 * float(i))
	DesertKit.spearman(world, "BattlementSpearman0", 600.0, G)
	DesertKit.herb(world, 2100.0, G)
	DesertKit.checkpoint(world, 2400.0, G)
	# Pasillo del techo sobre el foso.
	DesertKit.ground(world, PIT_TO - 100.0, WIDTH, TowerKit.STONE_DARK)
	TowerKit.block(world, Rect2(PIT_FROM - 100.0, CEILING_Y, PIT_TO - PIT_FROM + 300.0, CEILING_THICKNESS), "CorridorCeiling", FortressKit.BRICK_DARK)
	FortressKit.gravity_zone(world, Rect2(ZONE_FROM, CEILING_Y + CEILING_THICKNESS, ZONE_TO - ZONE_FROM, G - CEILING_Y - CEILING_THICKNESS), "CorridorGravity")
	# Torres colgantes con cañones que disparan a lo largo del pasillo.
	TowerKit.block(world, Rect2(PIT_FROM - 150.0, CEILING_Y + CEILING_THICKNESS, 50.0, 230.0), "CorridorTowerLeft", FortressKit.BRICK_DARK)
	TowerKit.block(world, Rect2(PIT_TO + 150.0, CEILING_Y + CEILING_THICKNESS, 50.0, 230.0), "CorridorTowerRight", FortressKit.BRICK_DARK)
	FortressKit.cannon(world, Vector2(PIT_FROM - 100.0, CEILING_Y + CEILING_THICKNESS + 24.0), 1.0, "CorridorCannonL", 0.0, 3.0)
	FortressKit.cannon(world, Vector2(PIT_TO + 150.0, CEILING_Y + CEILING_THICKNESS + 24.0), -1.0, "CorridorCannonR", 1.5, 3.0)
	# Tramo final con almenas.
	for i in 3:
		var x := 5300.0 + 900.0 * float(i)
		FortressKit.wall(world, x, G - 100.0, "FinalBlock%d" % i, 50.0)
		FortressKit.cannon(world, Vector2(x - 25.0, G - 48.0), -1.0, "FinalCannon%d" % i, 0.6 * float(i))
		DesertKit.archer(world, "FinalArcher%d" % i, x + 300.0, G)
	DesertKit.herb(world, 6200.0, G)
	DesertKit.spearman(world, "FinalSpearman", 7900.0, G)
	# Más enemigos (espaciados), plataformas altas con trampas y tiradores.
	DesertKit.mage(world, "BattlementMage0", 1250.0, G)
	DesertKit.archer(world, "BattlementArcher0", 2250.0, G)
	DesertKit.mage(world, "FinalMage0", 5000.0, G)
	DesertKit.spearman(world, "FinalSpearman1", 5900.0, G)
	DesertKit.spearman(world, "FinalSpearman2", 6800.0, G)
	DesertKit.mage(world, "FinalMage1", 7650.0, G)
	FortressKit.high_row(world, "Battlement", [[850.0, 480.0, 200.0, "archer", ""], [1300.0, 420.0, 220.0, "mage", ""], [1750.0, 340.0, 200.0, "", "spike"], [2050.0, 470.0, 200.0, "archer", ""]])
	FortressKit.high_row(world, "Final", [[5400.0, 480.0, 220.0, "mage", ""], [5750.0, 430.0, 220.0, "", "mine"], [6050.0, 340.0, 200.0, "archer", ""],
		[6450.0, 450.0, 220.0, "", "spike"], [6850.0, 340.0, 200.0, "mage", ""], [7300.0, 450.0, 220.0, "", "mine"], [7750.0, 340.0, 200.0, "archer", ""]])
	FortressKit.aerial_saws(world, "Battlement", [[5750.0, 540.0], [6650.0, 540.0], [7550.0, 540.0]])
	FortressKit.finish(level, world, WIDTH, Vector2(150.0, G - 30.0), PORTAL_POSITION, route())
