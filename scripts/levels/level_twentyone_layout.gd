class_name LevelTwentyoneLayout
extends RefCounted
## Nivel 21 (2026-11-18): "LABERINTO" (mundo 5, nivel 1). No es una franja que
## avanza hacia la derecha: es un edificio de cinco pisos con la cámara
## siguiendo también en vertical. Los corredores serpentean entre muros: se
## sube por la torre izquierda (escalones dentro de los pozos de las losas),
## se cruza por el piso superior y se baja por la torre derecha (cayendo por
## los huecos, a solo un piso de altura) hasta la salida. Hay un único
## camino (la dificultad no es encontrar la salida sino recorrerlo), no hay
## pozos mortales, no hay enemigos voladores y pocos enemigos terrestres.
## Obstáculos de los corredores: muros bajos que hay que saltar y muros que
## cuelgan del techo.

const TOWER_WIDTH := 1800.0
const WIDTH := 3600.0
const SHAFT_WIDTH := 420.0
const SLAB := 48.0
const ROW_PITCH := 336.0
const ROW_HEIGHT := 288.0
const FLOOR0_TOP := 1700.0
const ROW_COUNT := 5
const DIVIDER_HALF := 24.0
const LIMIT_BOTTOM := 1760
const HURDLE_SIZE := Vector2(60.0, 96.0)
const HANGING_SIZE := Vector2(48.0, 150.0)
const STEP_HEIGHT := 84.0
const LEDGE_WIDTH := 180.0
const STONE := Color("#5b5670")
const STONE_DARK := Color("#413d55")
const STONE_STEP := Color("#7a7494")
const WALKABLE_MARGIN := 80.0
const ENEMY_FRACTION := 0.82
const HERB_FRACTION := 0.5
const OBSTACLE_FRACTIONS := [0.2, 0.4, 0.6]
const MINE_SCENE := preload("res://scenes/world/proximity_mine.tscn")
const TELEPORT_SCENE := preload("res://scenes/world/teleport_trap.tscn")
const LAUNCH_PAD_SCENE := preload("res://scenes/world/launch_pad.tscn")
const BLADE_WHEEL_SCENE := preload("res://scenes/world/blade_wheel.tscn")


## Altura de la superficie del piso `row` (0 = el de abajo).
static func floor_top(row: int) -> float:
	return FLOOR0_TOP - ROW_PITCH * float(row)


## Huecos (x desde, x hasta) de la losa que sostiene el piso `row`.
static func holes(row: int) -> Array:
	if row == 1 or row == 3:
		return [
			[TOWER_WIDTH - DIVIDER_HALF - SHAFT_WIDTH, TOWER_WIDTH - DIVIDER_HALF],
			[TOWER_WIDTH + DIVIDER_HALF, TOWER_WIDTH + DIVIDER_HALF + SHAFT_WIDTH],
		]
	if row == 2 or row == 4:
		return [[0.0, SHAFT_WIDTH], [WIDTH - SHAFT_WIDTH, WIDTH]]
	return []


## Tramo caminable (x desde, x hasta) de cada corredor, sin zonas de pozo.
static func walkable(row: int, tower: String) -> Vector2:
	var margin := WALKABLE_MARGIN
	if row == 4:
		return Vector2(SHAFT_WIDTH + margin, WIDTH - SHAFT_WIDTH - margin)
	if tower == "A":
		if row == 0:
			return Vector2(300.0, TOWER_WIDTH - DIVIDER_HALF - SHAFT_WIDTH - margin)
		return Vector2(SHAFT_WIDTH + margin, TOWER_WIDTH - DIVIDER_HALF - SHAFT_WIDTH - margin)
	if row == 0:
		return Vector2(TOWER_WIDTH + DIVIDER_HALF + SHAFT_WIDTH + margin, WIDTH - 500.0)
	return Vector2(TOWER_WIDTH + DIVIDER_HALF + SHAFT_WIDTH + margin, WIDTH - SHAFT_WIDTH - margin)


## Centro (x) y superficie (y) de la repisa `step` (1..3) del pozo de subida
## que parte del piso `row`.
static func ledge_position(row: int, step: int) -> Vector2:
	var hole: Array = holes(row + 1)[0]
	var from_x: float = float(hole[0])
	var to_x: float = float(hole[1])
	# La primera repisa va en el lado lejano (si no, se pasaría por debajo de
	# ella); la última, también lejana, se salta hasta la losa del lado cercano.
	var far_right := row % 2 == 0
	var on_far_side := step % 2 == 1
	var at_right := far_right if on_far_side else not far_right
	var x := to_x - LEDGE_WIDTH * 0.5 if at_right else from_x + LEDGE_WIDTH * 0.5
	return Vector2(x, floor_top(row) - STEP_HEIGHT * float(step))


## Camino de la salida (centros de los corredores, repisas y pozos), del
## inicio al portal. Alimenta la barra de progreso y las medallas.
static func route() -> PackedVector2Array:
	var a_right := TOWER_WIDTH - DIVIDER_HALF - SHAFT_WIDTH * 0.5
	var a_left := SHAFT_WIDTH * 0.5
	var points := PackedVector2Array([Vector2(150.0, floor_top(0) - 24.0)])
	# Subida por la torre izquierda: corredor hasta el pozo y tres repisas.
	for row in range(0, 4):
		var shaft_x := a_right if row % 2 == 0 else a_left
		points.append(Vector2(shaft_x, floor_top(row) - 24.0))
		for step in range(1, 4):
			var ledge := ledge_position(row, step)
			points.append(Vector2(ledge.x, ledge.y - 24.0))
		# Llegada al piso siguiente: junto al borde del pozo, sobre la losa.
		var hole: Array = holes(row + 1)[0]
		var arrival_x: float = float(hole[0]) - 60.0 if row % 2 == 0 else float(hole[1]) + 60.0
		points.append(Vector2(arrival_x, floor_top(row + 1) - 24.0))
	# Cruce por el piso superior y descenso cayendo por los pozos de la torre derecha.
	# Se cae por el borde cercano de cada hueco (no hace falta llegar al centro).
	var drop_right := WIDTH - SHAFT_WIDTH + 40.0
	var drop_left := TOWER_WIDTH + DIVIDER_HALF + SHAFT_WIDTH - 40.0
	points.append(Vector2(drop_right, floor_top(4) - 24.0))
	var drop_xs := [drop_right, drop_left, drop_right, drop_left]
	for i in 4:
		var row := 3 - i
		if i > 0:
			points.append(Vector2(drop_xs[i], floor_top(row + 1) - 24.0))
		points.append(Vector2(drop_xs[i], floor_top(row) - 24.0))
	points.append(Vector2(WIDTH - 250.0, floor_top(0) - 24.0))
	return points


static func build(level: Node2D) -> void:
	var world := DesertKit.begin(level, "LevelTwentyoneGenerated")
	_backdrop(world)
	_build_structure(world)
	for row in ROW_COUNT:
		_build_corridor(world, row)
	_build_climbs(world)
	_build_checkpoint_and_herbs(world)
	_build_traps(world)

	DesertKit.place_player(level, Vector2(150.0, floor_top(0) - 30.0))
	var portal := level.get_node_or_null("ExitPortal")
	if portal != null:
		portal.position = Vector2(WIDTH - 250.0, floor_top(0) - 60.0)
	var camera := level.get_node_or_null("Camera") as HorizontalCamera
	if camera != null:
		camera.follow_y = true
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(WIDTH)
		camera.limit_bottom = LIMIT_BOTTOM
		camera.snap_to_target()
	level.call("set_route", route())


static func _backdrop(world: Node2D) -> void:
	var back := Polygon2D.new()
	back.name = "MazeBackdrop"
	back.color = Color("#1d1a2e")
	back.polygon = PackedVector2Array([Vector2(-200.0, -200.0), Vector2(WIDTH + 200.0, -200.0), Vector2(WIDTH + 200.0, 2000.0), Vector2(-200.0, 2000.0)])
	back.z_index = -30
	world.add_child(back)
	for row in ROW_COUNT:
		var top := floor_top(row) - ROW_HEIGHT
		var tint := Polygon2D.new()
		tint.name = "RowTint%d" % row
		tint.color = Color("#262240") if row % 2 == 0 else Color("#2b2646")
		tint.polygon = PackedVector2Array([Vector2(0.0, top), Vector2(WIDTH, top), Vector2(WIDTH, top + ROW_HEIGHT), Vector2(0.0, top + ROW_HEIGHT)])
		tint.z_index = -25
		world.add_child(tint)
		var x := 260.0
		while x < WIDTH:
			var lamp := Polygon2D.new()
			lamp.color = Color(1.0, 0.82, 0.45, 0.55)
			lamp.position = Vector2(x, top + 30.0)
			lamp.polygon = PackedVector2Array([Vector2(-7.0, 0.0), Vector2(0.0, -9.0), Vector2(7.0, 0.0), Vector2(0.0, 12.0)])
			lamp.z_index = -20
			world.add_child(lamp)
			x += 520.0


static func _build_structure(world: Node2D) -> void:
	# Losas: la del piso 0 es continua; las demás tienen los huecos de los pozos.
	for row in ROW_COUNT:
		_slab(world, floor_top(row), holes(row), "MazeSlab%d" % row)
	_slab(world, floor_top(ROW_COUNT), [], "MazeCeiling")
	var top_y := floor_top(ROW_COUNT)
	var bottom_y := floor_top(0) + SLAB
	var height := bottom_y - top_y
	DesertKit.platform(world, Vector2(-SLAB * 0.5, top_y + height * 0.5), Vector2(SLAB, height), STONE_DARK, Platform.Kind.STATIC, "MazeWallLeft")
	DesertKit.platform(world, Vector2(WIDTH + SLAB * 0.5, top_y + height * 0.5), Vector2(SLAB, height), STONE_DARK, Platform.Kind.STATIC, "MazeWallRight")
	# Muro divisorio entre las dos torres (los cuatro pisos de abajo).
	var divider_top := floor_top(ROW_COUNT - 1) + SLAB
	var divider_height := floor_top(0) - divider_top
	DesertKit.platform(world, Vector2(TOWER_WIDTH, divider_top + divider_height * 0.5), Vector2(DIVIDER_HALF * 2.0, divider_height), STONE_DARK, Platform.Kind.STATIC, "MazeDivider")


static func _slab(world: Node2D, top: float, hole_list: Array, node_name: String) -> void:
	var edges: Array = [0.0]
	for hole in hole_list:
		edges.append(float(hole[0]))
		edges.append(float(hole[1]))
	edges.append(WIDTH)
	var piece := 0
	var i := 0
	while i < edges.size():
		var from_x: float = edges[i]
		var to_x: float = edges[i + 1]
		if to_x - from_x > 1.0:
			DesertKit.platform(world, Vector2((from_x + to_x) * 0.5, top + SLAB * 0.5), Vector2(to_x - from_x, SLAB), STONE, Platform.Kind.STATIC, "%s_%d" % [node_name, piece])
			piece += 1
		i += 2


static func _build_corridor(world: Node2D, row: int) -> void:
	for tower in _towers_for(row):
		var span := walkable(row, tower)
		var floor_y := floor_top(row)
		var length := span.y - span.x
		var hurdle_first := (row + (0 if tower == "A" else 1)) % 2 == 0
		for index in OBSTACLE_FRACTIONS.size():
			var x := span.x + length * float(OBSTACLE_FRACTIONS[index])
			var is_hurdle := (index % 2 == 0) == hurdle_first
			if is_hurdle:
				DesertKit.platform(world, Vector2(x, floor_y - HURDLE_SIZE.y * 0.5), HURDLE_SIZE, STONE_STEP, Platform.Kind.STATIC, "MazeHurdle%d%s%d" % [row, tower, index])
			else:
				var ceiling_bottom := floor_y - ROW_HEIGHT
				DesertKit.platform(world, Vector2(x, ceiling_bottom + HANGING_SIZE.y * 0.5), HANGING_SIZE, STONE_STEP, Platform.Kind.STATIC, "MazeHanging%d%s%d" % [row, tower, index])
		_build_enemy(world, row, tower, span.x + length * ENEMY_FRACTION, floor_y)


static func _towers_for(row: int) -> Array:
	return ["A", "B"] if row < 4 else ["A"]


static func _build_enemy(world: Node2D, row: int, tower: String, x: float, floor_y: float) -> void:
	# Un enemigo terrestre por corredor como mucho (baja densidad).
	var key := "%d%s" % [row, tower]
	match key:
		"0A":
			DesertKit.spearman(world, "MazeSpearman0A", x, floor_y)
		"1A":
			DesertKit.archer(world, "MazeArcher1A", x, floor_y)
		"2A":
			DesertKit.slug(world, "MazeSlug2A", x, floor_y)
		"3A":
			DesertKit.mage(world, "MazeMage3A", x, floor_y)
		"4A":
			DesertKit.spearman(world, "MazeSpearman4A", x - 330.0, floor_y)
			DesertKit.slug(world, "MazeSlug4A", x, floor_y)
		"3B":
			DesertKit.archer(world, "MazeArcher3B", x, floor_y)
		"2B":
			DesertKit.spearman(world, "MazeSpearman2B", x, floor_y)
		"1B":
			DesertKit.slug(world, "MazeSlug1B", x, floor_y)


## Escalones dentro de los pozos de subida (torre izquierda): tres
## repisas (lejana, cercana, lejana) a 84 px de altura cada una.
static func _build_climbs(world: Node2D) -> void:
	for row in range(0, 4):
		for step in range(1, 4):
			var ledge := ledge_position(row, step)
			DesertKit.platform(world, Vector2(ledge.x, ledge.y + 12.0), Vector2(LEDGE_WIDTH, 24.0), STONE_STEP, Platform.Kind.STATIC, "MazeStep%d_%d" % [row, step])


static func _build_checkpoint_and_herbs(world: Node2D) -> void:
	var span4 := walkable(4, "A")
	DesertKit.checkpoint(world, (span4.x + span4.y) * 0.5, floor_top(4))
	for row in [2, 3]:
		var span := walkable(row, "A" if row == 2 else "B")
		DesertKit.herb(world, span.x + (span.y - span.x) * HERB_FRACTION, floor_top(row))


## Trampas nuevas (2026-11-23, ampliadas el mismo día). Todas van en huecos
## libres de los corredores (x; el piso se indica aparte):
##  - Minas: repartidas por los corredores (la del piso 0 obliga a frenar).
##  - Lanzadores de impulso hacia atrás: uno pegado a cada muro bajo, por el
##    lado por el que te acercas (hay que saltar lanzador y muro de una vez),
##    y otro sobre algunas repisas de subida.
##  - Teletransportes saltables y ruedas de cuchillas con giro contrario en
##    el piso superior (centro a 140 px del suelo: pasar con la cuchilla alta).
const MINES := [
	[0, 745.0], [0, 1220.0], [0, 2400.0], [0, 2950.0],
	[1, 730.0], [1, 2700.0], [2, 740.0], [2, 2400.0], [2, 2880.0],
	[3, 730.0], [3, 2700.0], [4, 1280.0], [4, 1650.0], [4, 3010.0],
]
const TELEPORTS := [[0, 985.0], [2, 1050.0], [4, 1450.0]]
## [x, giro horario, ángulo inicial]
const WHEELS := [[700.0, false, 45.0], [2380.0, true, 0.0], [2850.0, false, 45.0]]
const LEDGE_PAD_STEP := 2
const PAD_GAP := 8.0
const LEDGE_PAD_OFFSET := 55.0


## Centros (x, y) de los lanzadores pegados a los muros bajos. Los pisos
## pares se recorren hacia la derecha y los impares hacia la izquierda.
static func hurdle_pad_positions() -> Array:
	var result: Array = []
	for row in ROW_COUNT:
		for tower in _towers_for(row):
			var span := walkable(row, tower)
			var length := span.y - span.x
			var hurdle_first := (row + (0 if tower == "A" else 1)) % 2 == 0
			var direction := 1.0 if row % 2 == 0 else -1.0
			for index in OBSTACLE_FRACTIONS.size():
				if (index % 2 == 0) != hurdle_first:
					continue
				var x := span.x + length * float(OBSTACLE_FRACTIONS[index])
				var offset := HURDLE_SIZE.x * 0.5 + PAD_GAP + HURDLE_SIZE.x * 0.5
				result.append(Vector2(x - direction * offset, floor_top(row) - 15.0))
	return result


## Centros (x, y) de los lanzadores sobre las repisas (lado de la pared).
static func ledge_pad_positions() -> Array:
	var result: Array = []
	for row in range(0, 4):
		var ledge := ledge_position(row, LEDGE_PAD_STEP)
		var side := 1.0 if ledge.x > float((holes(row + 1)[0][0] + holes(row + 1)[0][1]) * 0.5) else -1.0
		result.append(Vector2(ledge.x + side * LEDGE_PAD_OFFSET, ledge.y - 12.0))
	return result


static func _build_traps(world: Node2D) -> void:
	var index := 0
	for entry in MINES:
		var mine := DesertKit.spawn(MINE_SCENE, world, Vector2(float(entry[1]), floor_top(int(entry[0]))))
		mine.name = "MazeMine%d" % index
		index += 1
	index = 0
	for entry in TELEPORTS:
		var teleport := DesertKit.spawn(TELEPORT_SCENE, world, Vector2(float(entry[1]), floor_top(int(entry[0])) - 20.0))
		teleport.name = "MazeTeleport%d" % index
		teleport.set("zone_size", Vector2(60.0, 40.0))
		index += 1
	index = 0
	for position in hurdle_pad_positions():
		var pad := DesertKit.spawn(LAUNCH_PAD_SCENE, world, position)
		pad.name = "MazeHurdlePad%d" % index
		pad.set("zone_size", Vector2(60.0, 30.0))
		pad.set("launch_speed", 650.0)
		index += 1
	index = 0
	for position in ledge_pad_positions():
		var pad := DesertKit.spawn(LAUNCH_PAD_SCENE, world, position)
		pad.name = "MazeLedgePad%d" % index
		pad.set("zone_size", Vector2(50.0, 24.0))
		pad.set("launch_speed", 520.0)
		index += 1
	var top_floor := floor_top(4)
	for i in WHEELS.size():
		var entry: Array = WHEELS[i]
		var wheel := DesertKit.spawn(BLADE_WHEEL_SCENE, world, Vector2(float(entry[0]), top_floor - 140.0))
		wheel.name = "MazeBladeWheel%d" % i
		wheel.set("arm_length", 110.0)
		wheel.set("spin_speed", 0.25)
		wheel.set("clockwise", bool(entry[1]))
		wheel.set("start_angle_degrees", float(entry[2]))
