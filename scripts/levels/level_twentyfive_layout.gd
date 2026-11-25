class_name LevelTwentyfiveLayout
extends RefCounted
## Nivel 25 (2026-11-23): "CIUDADELA" (mundo 5, final). Estructura de HUB Y
## RADIOS, NO LINEAL: el jugador empieza en la plaza central. El portal está
## en una cámara elevada cerrada por una COMPUERTA que solo se abre con las
## TRES PALANCAS, que se activan en cualquier orden:
##  - Palanca C (fácil): en la propia cámara elevada, a la que se sube con una
##    corriente ascendente desde la plaza.
##  - Palanca A: al final del radio izquierdo (prensa, lancero, plataformas
##    temporizadas sobre el abismo, rueda de cuchillas y arquero).
##  - Palanca B: al final del radio derecho (mina, babosa, dos cintas sobre el
##    abismo, prensa, rueda de cuchillas y mago).
## Mezcla las ideas del mundo 5: corriente, temporizadas, cintas, prensas,
## palancas y compuerta.
## Ampliación (2026-11-24): cada radio mide el DOBLE (el nivel pasa de 6400 a
## 12800 px). El diseño original se desplazó `S` px a la derecha y se añadió un
## tramo nuevo de 3200 px a cada lado con más enemigos, trampas y plataformas
## altas; las palancas A y B están ahora en los extremos.

## Desplazamiento del diseño original (= longitud añadida a cada lado).
const S := 3200.0
const WIDTH := 12800.0
const GROUND_Y := 640.0
const HUB_FROM := S + 2700.0
const HUB_TO := S + 3700.0
const HUB_CENTER := S + 3200.0
const LEFT_GROUND_FROM := S + 1900.0
const RIGHT_GROUND_TO := S + 4500.0
const CHAMBER_Y := 300.0
const CHAMBER_THICKNESS := 30.0
const DRAFT_WIDTH := 200.0
const GATE_X := S + 3440.0
## Muro muy alto: no se puede saltar ni rodear volando.
const GATE_SIZE := Vector2(48.0, 900.0)
const PORTAL_POSITION := Vector2(S + 3620.0, CHAMBER_Y - 60.0)
const LEVER_C_X := S + 2850.0
const LEVER_A_X := 150.0
const LEVER_B_X := WIDTH - 150.0
const CHANNEL := "CITADEL"
const CRUSHER_MOUNT := 340.0
const CRUSHER_DROP := 276.0
const SKY := {"top": Color("#6aa5e6"), "mid": Color("#b4d4f1"), "bottom": Color("#e9f3fb")}


static func route() -> PackedVector2Array:
	var up := Vector2(HUB_CENTER, CHAMBER_Y - 24.0)
	var hub := Vector2(HUB_CENTER, GROUND_Y - 24.0)
	return PackedVector2Array([
		Vector2(HUB_CENTER - 300.0, GROUND_Y - 24.0), hub, up, Vector2(LEVER_C_X, CHAMBER_Y - 24.0),
		up, hub, Vector2(LEVER_A_X, GROUND_Y - 24.0), hub,
		Vector2(LEVER_B_X, GROUND_Y - 24.0), hub, up, Vector2(PORTAL_POSITION.x, CHAMBER_Y - 24.0),
	])


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelTwentyfiveGenerated")
	TowerKit.sky(world, Rect2(-300.0, -300.0, WIDTH + 600.0, 1400.0), SKY)
	_build_hub(world)
	_build_left_spoke(world)
	_build_right_spoke(world)
	TowerKit.fall_zone(world, 780.0, WIDTH, "FallZoneCitadel")
	DesertKit.place_player(level, Vector2(HUB_CENTER - 300.0, GROUND_Y - 30.0))
	TowerKit.portal(level, PORTAL_POSITION)
	TowerKit.camera(level, Rect2(0.0, 0.0, WIDTH, 720.0), false)
	level.call("set_route", route())


static func _build_hub(world: Node2D) -> void:
	DesertKit.ground(world, LEFT_GROUND_FROM, RIGHT_GROUND_TO, TowerKit.STONE_DARK)
	DesertKit.checkpoint(world, S + 3450.0, GROUND_Y)
	DesertKit.herb(world, S + 2780.0, GROUND_Y)
	# Cámara elevada: dos mitades con el hueco de la corriente en medio.
	var half_gap := DRAFT_WIDTH * 0.5
	TowerKit.block(world, Rect2(HUB_FROM, CHAMBER_Y, HUB_CENTER - half_gap - HUB_FROM, CHAMBER_THICKNESS), "CitadelChamberLeft", TowerKit.STONE)
	TowerKit.block(world, Rect2(HUB_CENTER + half_gap, CHAMBER_Y, HUB_TO - (HUB_CENTER + half_gap), CHAMBER_THICKNESS), "CitadelChamberRight", TowerKit.STONE)
	# La corriente llega al borde superior del nivel (y=0); salir por arriba mata.
	var draft_top := 0.0
	TowerKit.updraft(world, Vector2(HUB_CENTER, (GROUND_Y + draft_top) * 0.5), Vector2(DRAFT_WIDTH - 20.0, GROUND_Y - draft_top), "CitadelDraft")
	TowerKit.lever(world, Vector2(LEVER_C_X, CHAMBER_Y), CHANNEL, "CitadelLeverC")
	TowerKit.gate(world, Vector2(GATE_X, CHAMBER_Y - GATE_SIZE.y * 0.5), GATE_SIZE, CHANNEL, "CitadelGate")


static func _build_left_spoke(world: Node2D) -> void:
	TowerKit.crusher(world, Vector2(S + 2350.0, GROUND_Y - CRUSHER_MOUNT), "CitadelCrusherL", CRUSHER_DROP)
	DesertKit.spearman(world, "CitadelSpearmanL", S + 2100.0, GROUND_Y)
	# Abismo 1 (S+1100..S+1900) cubierto por plataformas temporizadas.
	for i in 3:
		TowerKit.timed(world, Vector2(S + 1740.0 - 280.0 * float(i), 600.0), 150.0, "CitadelTimedL%d" % i, 2.4, 1.5, 0.9 * float(i))
	# Tramo central del radio (original) y su ampliación.
	DesertKit.ground(world, 1500.0, S + 1150.0, TowerKit.STONE_DARK)
	TowerKit.wheel(world, Vector2(S + 700.0, GROUND_Y - 140.0), "CitadelWheelL", true, 110.0, 0.25)
	DesertKit.archer(world, "CitadelArcherL", S + 420.0, GROUND_Y)
	DesertKit.mage(world, "CitadelMageL", S + 1000.0, GROUND_Y)
	# Ampliación: segundo abismo (700..1500) con otras tres temporizadas.
	for i in 3:
		TowerKit.timed(world, Vector2(1340.0 - 280.0 * float(i), 600.0), 150.0, "CitadelTimedL%d" % (i + 3), 2.4, 1.5, 0.9 * float(i))
	DesertKit.ground(world, 0.0, 700.0, TowerKit.STONE_DARK)
	DesertKit.spearman(world, "CitadelSpearmanL2", 1850.0, GROUND_Y)
	DesertKit.archer(world, "CitadelArcherL2", 2250.0, GROUND_Y)
	DesertKit.mage(world, "CitadelMageL2", 2700.0, GROUND_Y)
	DesertKit.slug(world, "CitadelSlugL", 3000.0, GROUND_Y)
	TowerKit.crusher(world, Vector2(2050.0, GROUND_Y - CRUSHER_MOUNT), "CitadelCrusherL2", CRUSHER_DROP)
	TowerKit.wheel(world, Vector2(2500.0, GROUND_Y - 140.0), "CitadelWheelL2", false, 110.0, 0.25, 45.0)
	TowerKit.mine(world, Vector2(1650.0, GROUND_Y), "CitadelMineL")
	TowerKit.mine(world, Vector2(3350.0, GROUND_Y), "CitadelMineL2")
	DesertKit.spearman(world, "CitadelSpearmanL3", 450.0, GROUND_Y)
	FortressKit.high_row(world, "CitadelL", [[1900.0, 480.0, 220.0, "archer", ""], [2350.0, 380.0, 200.0, "", "spike"], [2800.0, 480.0, 220.0, "mage", ""],
		[S + 300.0, 470.0, 220.0, "archer", ""], [S + 850.0, 470.0, 200.0, "", "mine"]])
	FortressKit.aerial_saws(world, "CitadelL", [[2150.0, 540.0], [3100.0, 540.0]])
	TowerKit.lever(world, Vector2(LEVER_A_X, GROUND_Y), CHANNEL, "CitadelLeverA")


static func _build_right_spoke(world: Node2D) -> void:
	TowerKit.mine(world, Vector2(S + 3960.0, GROUND_Y), "CitadelMineR")
	DesertKit.slug(world, "CitadelSlugR", S + 4250.0, GROUND_Y)
	# Abismo 1 (S+4500..S+5300) con dos cintas de sentidos opuestos.
	var belt_a := DesertKit.platform(world, Vector2(S + 4700.0, GROUND_Y + 20.0), Vector2(400.0, 40.0), Color("#7e8aa8"), Platform.Kind.STATIC, "CitadelBeltR0")
	belt_a.conveyor_speed = -360.0
	var belt_b := DesertKit.platform(world, Vector2(S + 5100.0, GROUND_Y + 20.0), Vector2(400.0, 40.0), Color("#7e8aa8"), Platform.Kind.STATIC, "CitadelBeltR1")
	belt_b.conveyor_speed = 360.0
	DesertKit.ground(world, S + 5300.0, WIDTH - 2400.0, TowerKit.STONE_DARK)
	TowerKit.crusher(world, Vector2(S + 5600.0, GROUND_Y - CRUSHER_MOUNT), "CitadelCrusherR", CRUSHER_DROP)
	TowerKit.wheel(world, Vector2(S + 5900.0, GROUND_Y - 140.0), "CitadelWheelR", false, 110.0, 0.25, 45.0)
	DesertKit.mage(world, "CitadelMageR", S + 6100.0, GROUND_Y)
	DesertKit.spearman(world, "CitadelSpearmanR", S + 5450.0, GROUND_Y)
	DesertKit.archer(world, "CitadelArcherR", S + 6300.0, GROUND_Y)
	# Ampliación: segundo abismo (WIDTH-2400..WIDTH-1600) con dos cintas y tramo final.
	var base := WIDTH - 2400.0
	var belt_c := DesertKit.platform(world, Vector2(base + 200.0, GROUND_Y + 20.0), Vector2(400.0, 40.0), Color("#7e8aa8"), Platform.Kind.STATIC, "CitadelBeltR2")
	belt_c.conveyor_speed = 360.0
	var belt_d := DesertKit.platform(world, Vector2(base + 600.0, GROUND_Y + 20.0), Vector2(400.0, 40.0), Color("#7e8aa8"), Platform.Kind.STATIC, "CitadelBeltR3")
	belt_d.conveyor_speed = -360.0
	DesertKit.ground(world, base + 800.0, WIDTH, TowerKit.STONE_DARK)
	DesertKit.spearman(world, "CitadelSpearmanR2", base - 300.0, GROUND_Y)
	DesertKit.archer(world, "CitadelArcherR2", base + 1150.0, GROUND_Y)
	DesertKit.mage(world, "CitadelMageR2", base + 1500.0, GROUND_Y)
	DesertKit.slug(world, "CitadelSlugR2", base + 1800.0, GROUND_Y)
	TowerKit.crusher(world, Vector2(base + 1300.0, GROUND_Y - CRUSHER_MOUNT), "CitadelCrusherR2", CRUSHER_DROP)
	TowerKit.wheel(world, Vector2(base + 1650.0, GROUND_Y - 140.0), "CitadelWheelR2", true, 110.0, 0.25)
	TowerKit.mine(world, Vector2(base + 1000.0, GROUND_Y), "CitadelMineR2")
	DesertKit.spearman(world, "CitadelSpearmanR3", WIDTH - 450.0, GROUND_Y)
	FortressKit.high_row(world, "CitadelR", [[S + 5600.0, 480.0, 220.0, "archer", ""], [S + 6050.0, 380.0, 200.0, "mage", ""],
		[base - 650.0, 470.0, 200.0, "", "mine"], [base + 1000.0, 480.0, 220.0, "archer", ""], [base + 1450.0, 380.0, 200.0, "", "spike"], [base + 1900.0, 480.0, 220.0, "mage", ""]])
	FortressKit.aerial_saws(world, "CitadelR", [[base + 1250.0, 540.0], [base + 1700.0, 540.0]])
	TowerKit.lever(world, Vector2(LEVER_B_X, GROUND_Y), CHANNEL, "CitadelLeverB")
