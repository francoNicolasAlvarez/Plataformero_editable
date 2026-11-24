class_name LevelTwentyfourLayout
extends RefCounted
## Nivel 24 (2026-11-23): "NUBES" (mundo 5, nivel 4). CAMBIO DE REGLAS: baja
## gravedad (LevelRules.low_gravity): los saltos son más altos y largos, así
## que los huecos entre islas de nubes miden ~460 px. Estructura de franja con
## dos alturas: la ruta BAJA salta de nube en nube (con ruedas de cuchillas y
## enemigos) y la ruta ALTA, opcional, se alcanza con un trampolín
## (lanzador con dirección fija) en la segunda isla; tiene cuatro nubes y una
## hierba, y se baja de ella cayendo a la isla del control. Murciélagos
## vuelan por todo el nivel. REGLA DE DENSIDAD: cada plataforma (isla baja o
## nube alta) lleva al menos un obstáculo o enemigo. La ruta alta es el nivel
## superior de magos (uno por nube). En la esquina inferior izquierda de la
## pantalla vive un centinela aspirador azul (VacuumSentry) que dispara conos de
## proyectiles y periódicamente aspira objetos voladores (decorado).

const WIDTH := 9400.0
const GROUND_Y := 640.0
const START_END := 1000.0
const FINAL_START := 8500.0
const PORTAL_POSITION := Vector2(9150.0, 580.0)
const GRAVITY_FACTOR := 0.55
const JUMP_FACTOR := 1.3
const CLOUD_THICKNESS := 26.0
const PAD_SPEED := 850.0
const PAD_DIRECTION := Vector2(0.35, -1.0)
const CHECKPOINT_ISLAND := 4

## Islas de la ruta baja: [x, y (centro), ancho].
const LOW_ISLANDS := [
	[1500.0, 600.0, 340.0], [2300.0, 560.0, 340.0], [3100.0, 610.0, 340.0],
	[3900.0, 540.0, 340.0], [4700.0, 600.0, 520.0], [5500.0, 570.0, 340.0],
	[6300.0, 520.0, 340.0], [7100.0, 580.0, 340.0], [7900.0, 600.0, 340.0],
]
## Nubes de la ruta alta: [x, y (centro), ancho].
const HIGH_CLOUDS := [[2820.0, 220.0, 320.0], [3560.0, 180.0, 320.0], [4300.0, 200.0, 320.0], [5040.0, 230.0, 320.0]]
const SKY := {"top": Color("#5f9be0"), "mid": Color("#a9cdf0"), "bottom": Color("#e6f1fb")}


static func island_top(i: int) -> float:
	return float(LOW_ISLANDS[i][1]) - CLOUD_THICKNESS * 0.5


static func route() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(150.0, GROUND_Y - 24.0), Vector2(START_END - 80.0, GROUND_Y - 24.0)])
	for i in LOW_ISLANDS.size():
		points.append(Vector2(float(LOW_ISLANDS[i][0]), island_top(i) - 24.0))
	points.append(Vector2(FINAL_START + 150.0, GROUND_Y - 24.0))
	points.append(Vector2(PORTAL_POSITION.x, GROUND_Y - 24.0))
	return points


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelTwentyfourGenerated")
	TowerKit.sky(world, Rect2(-300.0, -400.0, WIDTH + 600.0, 1500.0), SKY)
	DesertKit.ground(world, 0.0, START_END, TowerKit.STONE_DARK)
	DesertKit.ground(world, FINAL_START, WIDTH, TowerKit.STONE_DARK)
	for i in LOW_ISLANDS.size():
		var island: Array = LOW_ISLANDS[i]
		TowerKit.cloud_platform(world, Vector2(float(island[0]), float(island[1])), float(island[2]), "CloudLow%d" % i)
	for i in HIGH_CLOUDS.size():
		var cloud: Array = HIGH_CLOUDS[i]
		TowerKit.cloud_platform(world, Vector2(float(cloud[0]), float(cloud[1])), float(cloud[2]), "CloudHigh%d" % i)
	TowerKit.fall_zone(world, 780.0, WIDTH, "FallZoneClouds")
	_build_traps(world)
	_build_enemies(world)
	_build_pickups(world)
	DesertKit.bats(world, 6.0, 5.0)
	TowerKit.vacuum_sentry(world)
	var player := level.get_node_or_null("Player") as Player
	LevelRules.low_gravity(player, GRAVITY_FACTOR, JUMP_FACTOR)
	DesertKit.place_player(level, Vector2(150.0, GROUND_Y - 30.0))
	TowerKit.portal(level, PORTAL_POSITION)
	TowerKit.camera(level, Rect2(0.0, 0.0, WIDTH, 720.0), false)
	level.call("set_route", route())


static func _build_traps(world: Node2D) -> void:
	# Trampolín de la isla 1: lanza a la ruta alta.
	TowerKit.bounce_pad(world, Vector2(2300.0 - 110.0, island_top(1) - 12.0), "CloudBouncePad", PAD_SPEED, PAD_DIRECTION)
	# Ruedas de cuchillas sobre las islas 2 y 6 (compuertas de tiempo).
	TowerKit.wheel(world, Vector2(3100.0, island_top(2) - 120.0), "CloudWheel0", true, 90.0, 0.3)
	TowerKit.wheel(world, Vector2(6300.0, island_top(6) - 120.0), "CloudWheel1", false, 90.0, 0.3, 45.0)
	# Minas en las islas 3 y 7.
	TowerKit.mine(world, Vector2(3900.0 + 90.0, island_top(3)), "CloudMine0")
	TowerKit.mine(world, Vector2(7100.0 - 90.0, island_top(7)), "CloudMine1")
	# Isla 1 (la del trampolín): una mina en el extremo opuesto.
	TowerKit.mine(world, Vector2(2300.0 + 105.0, island_top(1)), "CloudMine2")


static func _build_enemies(world: Node2D) -> void:
	DesertKit.archer(world, "CloudArcher0", 1500.0 + 70.0, island_top(0))
	DesertKit.mage(world, "CloudMage0", 5500.0 + 60.0, island_top(5))
	DesertKit.slug(world, "CloudSlug0", 4700.0 - 160.0, island_top(CHECKPOINT_ISLAND))
	DesertKit.archer(world, "CloudArcher1", 7900.0 + 90.0, island_top(8))
	# Nivel superior: un mago en cada nube alta, en el extremo derecho.
	for i in HIGH_CLOUDS.size():
		var cloud: Array = HIGH_CLOUDS[i]
		var top := float(cloud[1]) - CLOUD_THICKNESS * 0.5
		DesertKit.mage(world, "CloudHighMage%d" % i, float(cloud[0]) + float(cloud[2]) * 0.5 - 70.0, top)
	DesertKit.spearman(world, "CloudGuard0", FINAL_START + 480.0, GROUND_Y)
	DesertKit.spearman(world, "CloudGuard1", FINAL_START + 640.0, GROUND_Y, true)


static func _build_pickups(world: Node2D) -> void:
	DesertKit.checkpoint(world, 4700.0 + 160.0, island_top(CHECKPOINT_ISLAND))
	DesertKit.herb(world, 4000.0, float(HIGH_CLOUDS[1][1]) - CLOUD_THICKNESS * 0.5)
	DesertKit.herb(world, 7900.0, island_top(8))
