class_name LevelTwentyeightLayout
extends RefCounted
## Nivel 28 (2026-11-24): "MAZMORRA" (6-3), hub no lineal con VICTORIA
## ALTERNATIVA: el portal solo se abre al reunir las TRES LLAVES, una por celda:
##  - Celda izquierda: rastrillo (compuerta) abierto por una palanca en el patio;
##    su guardián lleva escudo y cae al abrirla.
##  - Celda derecha: rastrillo abierto por un botón que hay que SALTAR desde una
##    repisa; su mago guardián también cae al abrirlo.
##  - Celda alta: una repisa a 400 px que solo se alcanza con el RESORTE del
##    patio (saltos un 55 % más altos, 3 cargas).
## Rocas con reposición para derribar a los arqueros del patio (Ctrl las lanza).

const WIDTH := 6400.0
const G := FortressKit.GROUND
const HUB := 3200.0
const LEFT_GATE_X := 1900.0
const RIGHT_GATE_X := 4500.0
## 400 px de alto: solo se llega con el resorte (sin él ~312 px).
const HIGH_LEDGE_TOP := 240.0
const PORTAL_POSITION := Vector2(3600.0, G - 60.0)
const GATE_SIZE := Vector2(40.0, 300.0)


static func route() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(HUB, G - 24.0), Vector2(2400.0, G - 24.0), Vector2(1300.0, G - 24.0), Vector2(2400.0, G - 24.0),
		Vector2(2800.0, G - 24.0), Vector2(3250.0, HIGH_LEDGE_TOP - 24.0), Vector2(3600.0, G - 24.0),
		Vector2(3900.0, G - 24.0), Vector2(5100.0, G - 24.0), Vector2(3900.0, G - 24.0), Vector2(PORTAL_POSITION.x, G - 24.0),
	])


static func build(level: Node2D) -> void:
	var world := FortressKit.start(level, "LevelTwentyeightGenerated", WIDTH)
	DesertKit.ground(world, 900.0, 5500.0, TowerKit.STONE_DARK)
	# Muros de fondo de las celdas.
	FortressKit.wall(world, 960.0, 340.0, "CellBackLeft", 40.0)
	FortressKit.wall(world, 5440.0, 340.0, "CellBackRight", 40.0)
	# Celda izquierda: palanca + rastrillo + guardián con escudo + llave.
	FortressKit.item(world, GrabItem.Kind.ROCK, Vector2(2250.0, G - 14.0), "DungeonRockL", 8.0)
	TowerKit.lever(world, Vector2(2500.0, G), "L", "DungeonLeverL")
	TowerKit.gate(world, Vector2(LEFT_GATE_X, G - GATE_SIZE.y * 0.5), GATE_SIZE, "L", "DungeonGateL")
	var spear := DesertKit.spearman(world, "DungeonGuardL", 1500.0, G)
	FortressKit.lock(world, spear, "L", "DungeonLockL")
	FortressKit.key(world, Vector2(1200.0, G - 40.0), "DungeonKeyL")
	# Celda derecha: botón en una repisa + rastrillo + mago con escudo + llave.
	FortressKit.ledge(world, 3850.0, 4000.0, 480.0, "DungeonButtonLedge")
	FortressKit.button(world, Vector2(3925.0, 480.0), "R", "DungeonButtonR")
	TowerKit.gate(world, Vector2(RIGHT_GATE_X, G - GATE_SIZE.y * 0.5), GATE_SIZE, "R", "DungeonGateR")
	var mage := DesertKit.mage(world, "DungeonGuardR", 4950.0, G)
	FortressKit.lock(world, mage, "R", "DungeonLockR")
	FortressKit.key(world, Vector2(5200.0, G - 40.0), "DungeonKeyR")
	# Celda alta: solo con el resorte.
	FortressKit.item(world, GrabItem.Kind.SPRING, Vector2(2800.0, G - 14.0), "DungeonSpring", 10.0)
	FortressKit.ledge(world, 3100.0, 3400.0, HIGH_LEDGE_TOP, "DungeonHighLedge")
	FortressKit.key(world, Vector2(3250.0, HIGH_LEDGE_TOP - 40.0), "DungeonKeyHigh")
	# Patio: arqueros que se derriban con rocas, control y hierba.
	DesertKit.archer(world, "DungeonArcher0", 2100.0, G)
	DesertKit.archer(world, "DungeonArcher1", 4200.0, G)
	FortressKit.item(world, GrabItem.Kind.ROCK, Vector2(3000.0, G - 14.0), "DungeonRockC0", 8.0)
	FortressKit.item(world, GrabItem.Kind.ROCK, Vector2(3500.0, G - 14.0), "DungeonRockC1", 8.0)
	DesertKit.checkpoint(world, HUB, G)
	DesertKit.herb(world, 2650.0, G)
	DesertKit.herb(world, 3800.0, G)
	FortressKit.victory(world, VictoryCondition.Mode.KEYS)
	FortressKit.finish(level, world, WIDTH, Vector2(HUB, G - 30.0), PORTAL_POSITION, route())
