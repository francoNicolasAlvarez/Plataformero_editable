class_name LevelThirtyLayout
extends RefCounted
## Nivel 30 (2026-11-24): "SALA DEL TRONO" (6-5), arena final del mundo con
## con el impulso disponible (Ctrl; con una roca en la mano, Ctrl la lanza).
## Victoria alternativa: el portal se abre al pisar los DOS BOTONES (canal T);
## uno está en una repisa alta (resorte) y el otro en el TECHO (zona de
## gravedad). Al pisarlos también caen los dos lanceros de élite con escudo.
## Los soldados sueltos (rocas con Ctrl, con reposición) son opcionales.

const WIDTH := 1800.0
const G := FortressKit.GROUND
const CEILING_Y := 90.0
const CEILING_THICKNESS := 30.0
## 370 px de alto: solo con el resorte.
const HIGH_LEDGE_TOP := 270.0
const PORTAL_POSITION := Vector2(1700.0, G - 60.0)


static func route() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(150.0, G - 24.0), Vector2(900.0, G - 24.0), Vector2(900.0, CEILING_Y + CEILING_THICKNESS + 24.0),
		Vector2(1500.0, HIGH_LEDGE_TOP - 24.0), Vector2(PORTAL_POSITION.x, G - 24.0),
	])


static func build(level: Node2D) -> void:
	var world := FortressKit.start(level, "LevelThirtyGenerated", WIDTH)
	DesertKit.ground(world, 0.0, WIDTH, TowerKit.STONE_DARK)
	TowerKit.block(world, Rect2(0.0, CEILING_Y, WIDTH, CEILING_THICKNESS), "ThroneCeiling", FortressKit.BRICK_DARK)
	# Suministro de rocas.
	FortressKit.item(world, GrabItem.Kind.ROCK, Vector2(250.0, G - 14.0), "ThroneRock0", 6.0)
	FortressKit.item(world, GrabItem.Kind.ROCK, Vector2(1000.0, G - 14.0), "ThroneRock1", 6.0)
	FortressKit.item(world, GrabItem.Kind.ROCK, Vector2(1600.0, G - 14.0), "ThroneRock2", 6.0)
	# Botón alto (resorte) en la repisa derecha y botón del techo (zona de gravedad).
	FortressKit.item(world, GrabItem.Kind.SPRING, Vector2(1250.0, G - 14.0), "ThroneSpring", 10.0)
	FortressKit.ledge(world, 1400.0, 1650.0, HIGH_LEDGE_TOP, "ThroneHighLedge")
	FortressKit.button(world, Vector2(1525.0, HIGH_LEDGE_TOP), "T", "ThroneButtonHigh")
	FortressKit.gravity_zone(world, Rect2(550.0, CEILING_Y + CEILING_THICKNESS, 600.0, G - CEILING_Y - CEILING_THICKNESS), "ThroneGravity")
	var ceiling_button := FortressKit.button(world, Vector2(850.0, CEILING_Y + CEILING_THICKNESS), "T", "ThroneButtonCeiling")
	ceiling_button.scale = Vector2(1.0, -1.0)
	# Soldados de la arena (cuentan para la victoria).
	# R1 (2026-11-27): ningún enemigo en la primera mitad de la pantalla inicial
	# (x < ~930): el mago sube a la cornisa alta y la babosa y la élite A se
	# mueven a la mitad derecha de la arena.
	var mage := DesertKit.mage(world, "ThroneMage", 1440.0, HIGH_LEDGE_TOP)
	var archer := DesertKit.archer(world, "ThroneArcher", 1500.0, G)
	var slug := DesertKit.slug(world, "ThroneSlug", 1000.0, G)
	var spear := DesertKit.spearman(world, "ThroneSpearman", 1200.0, G)
	FortressKit.ledge(world, 200.0, 460.0, 480.0, "ThroneLedgeLeft")
	# Élite con escudo: dos lanceros que caen con los dos botones (canal T).
	var elite_a := DesertKit.spearman(world, "ThroneEliteA", 1350.0, G)
	var elite_b := DesertKit.spearman(world, "ThroneEliteB", 1650.0, G)
	FortressKit.lock(world, elite_a, "T", "ThroneLockA")
	FortressKit.lock(world, elite_b, "T", "ThroneLockB")
	for enemy in [mage, archer, slug, spear, elite_a, elite_b]:
		FortressKit.arena(enemy)
	DesertKit.checkpoint(world, 900.0, G)
	DesertKit.herb(world, 1100.0, G)
	FortressKit.victory(world, VictoryCondition.Mode.CHANNEL, "Victory", "T")
	FortressKit.finish(level, world, WIDTH, Vector2(150.0, G - 30.0), PORTAL_POSITION, route())
