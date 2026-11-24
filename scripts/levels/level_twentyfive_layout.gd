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

const WIDTH := 6400.0
const GROUND_Y := 640.0
const HUB_FROM := 2700.0
const HUB_TO := 3700.0
const HUB_CENTER := 3200.0
const LEFT_GROUND_FROM := 1900.0
const RIGHT_GROUND_TO := 4500.0
const CHAMBER_Y := 300.0
const CHAMBER_THICKNESS := 30.0
const DRAFT_WIDTH := 200.0
const GATE_X := 3440.0
## Muro muy alto: no se puede saltar ni rodear volando.
const GATE_SIZE := Vector2(48.0, 900.0)
const PORTAL_POSITION := Vector2(3620.0, CHAMBER_Y - 60.0)
const LEVER_C_X := 2850.0
const LEVER_A_X := 150.0
const LEVER_B_X := 6250.0
const CHANNEL := "CITADEL"
const CRUSHER_MOUNT := 340.0
const CRUSHER_DROP := 276.0
const SKY := {"top": Color("#6aa5e6"), "mid": Color("#b4d4f1"), "bottom": Color("#e9f3fb")}


static func route() -> PackedVector2Array:
	var up := Vector2(HUB_CENTER, CHAMBER_Y - 24.0)
	var hub := Vector2(HUB_CENTER, GROUND_Y - 24.0)
	return PackedVector2Array([
		Vector2(2900.0, GROUND_Y - 24.0), hub, up, Vector2(LEVER_C_X, CHAMBER_Y - 24.0),
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
	DesertKit.place_player(level, Vector2(2900.0, GROUND_Y - 30.0))
	TowerKit.portal(level, PORTAL_POSITION)
	TowerKit.camera(level, Rect2(0.0, 0.0, WIDTH, 720.0), false)
	level.call("set_route", route())


static func _build_hub(world: Node2D) -> void:
	DesertKit.ground(world, LEFT_GROUND_FROM, RIGHT_GROUND_TO, TowerKit.STONE_DARK)
	DesertKit.checkpoint(world, 3450.0, GROUND_Y)
	DesertKit.herb(world, 2780.0, GROUND_Y)
	# Cámara elevada: dos mitades con el hueco de la corriente en medio.
	var half_gap := DRAFT_WIDTH * 0.5
	TowerKit.block(world, Rect2(HUB_FROM, CHAMBER_Y, HUB_CENTER - half_gap - HUB_FROM, CHAMBER_THICKNESS), "CitadelChamberLeft", TowerKit.STONE)
	TowerKit.block(world, Rect2(HUB_CENTER + half_gap, CHAMBER_Y, HUB_TO - (HUB_CENTER + half_gap), CHAMBER_THICKNESS), "CitadelChamberRight", TowerKit.STONE)
	var draft_top := CHAMBER_Y - 160.0
	TowerKit.updraft(world, Vector2(HUB_CENTER, (GROUND_Y + draft_top) * 0.5), Vector2(DRAFT_WIDTH - 20.0, GROUND_Y - draft_top), "CitadelDraft")
	TowerKit.lever(world, Vector2(LEVER_C_X, CHAMBER_Y), CHANNEL, "CitadelLeverC")
	TowerKit.gate(world, Vector2(GATE_X, CHAMBER_Y - GATE_SIZE.y * 0.5), GATE_SIZE, CHANNEL, "CitadelGate")


static func _build_left_spoke(world: Node2D) -> void:
	TowerKit.crusher(world, Vector2(2350.0, GROUND_Y - CRUSHER_MOUNT), "CitadelCrusherL", CRUSHER_DROP)
	DesertKit.spearman(world, "CitadelSpearmanL", 2100.0, GROUND_Y)
	# Abismo 1100..1900 cubierto por plataformas temporizadas.
	for i in 3:
		TowerKit.timed(world, Vector2(1740.0 - 280.0 * float(i), 600.0), 150.0, "CitadelTimedL%d" % i, 2.4, 1.5, 0.9 * float(i))
	DesertKit.ground(world, 0.0, 1150.0, TowerKit.STONE_DARK)
	TowerKit.wheel(world, Vector2(700.0, GROUND_Y - 140.0), "CitadelWheelL", true, 110.0, 0.25)
	DesertKit.archer(world, "CitadelArcherL", 420.0, GROUND_Y)
	TowerKit.lever(world, Vector2(LEVER_A_X, GROUND_Y), CHANNEL, "CitadelLeverA")


static func _build_right_spoke(world: Node2D) -> void:
	TowerKit.mine(world, Vector2(3960.0, GROUND_Y), "CitadelMineR")
	DesertKit.slug(world, "CitadelSlugR", 4250.0, GROUND_Y)
	# Abismo 4500..5300 con dos cintas de sentidos opuestos.
	var belt_a := DesertKit.platform(world, Vector2(4700.0, GROUND_Y + 20.0), Vector2(400.0, 40.0), Color("#7e8aa8"), Platform.Kind.STATIC, "CitadelBeltR0")
	belt_a.conveyor_speed = -180.0
	var belt_b := DesertKit.platform(world, Vector2(5100.0, GROUND_Y + 20.0), Vector2(400.0, 40.0), Color("#7e8aa8"), Platform.Kind.STATIC, "CitadelBeltR1")
	belt_b.conveyor_speed = 180.0
	DesertKit.ground(world, 5300.0, WIDTH, TowerKit.STONE_DARK)
	TowerKit.crusher(world, Vector2(5600.0, GROUND_Y - CRUSHER_MOUNT), "CitadelCrusherR", CRUSHER_DROP)
	TowerKit.wheel(world, Vector2(5900.0, GROUND_Y - 140.0), "CitadelWheelR", false, 110.0, 0.25, 45.0)
	DesertKit.mage(world, "CitadelMageR", 6100.0, GROUND_Y)
	TowerKit.lever(world, Vector2(LEVER_B_X, GROUND_Y), CHANNEL, "CitadelLeverB")
