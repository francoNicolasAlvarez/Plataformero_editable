extends SceneTree
## Comprueba los niveles 12 "DUNAS", 13 "OASIS", 14 "CAÑÓN" y 15 "TORMENTA"
## (2026-11-17, mundo 3): cadena de niveles, estructura, viento, enemigos,
## trampas, control, hierbas, portal y zona de caída de cada uno. Ejecutar con:
## godot --headless --path . --script res://tests/desert_levels_smoke_test.gd

const SCENES := {
	12: "res://scenes/levels/level_twelve.tscn",
	13: "res://scenes/levels/level_thirteen.tscn",
	14: "res://scenes/levels/level_fourteen.tscn",
	15: "res://scenes/levels/level_fifteen.tscn",
}
const NEXT := {
	12: "res://scenes/levels/level_thirteen.tscn",
	13: "res://scenes/levels/level_fourteen.tscn",
	14: "res://scenes/levels/level_fifteen.tscn",
	15: "res://scenes/levels/level_sixteen.tscn",
}
const NAMES := {12: "DUNAS", 13: "OASIS", 14: "CAÑÓN", 15: "TORMENTA"}

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for number in [12, 13, 14, 15]:
		var level: Node = (load(SCENES[number]) as PackedScene).instantiate()
		root.add_child(level)
		await _wait_physics(30)
		_check_common(level, number)
		match number:
			12: _check_twelve(level)
			13: _check_thirteen(level)
			14: _check_fourteen(level)
			15: _check_fifteen(level)
		level.queue_free()
		await process_frame
		await process_frame

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _count(type_check: Callable) -> int:
	return get_nodes_in_group("enemies").filter(type_check).size()


func _is_archer(e: Node) -> bool:
	return e is SpreadEnemy


func _is_mage(e: Node) -> bool:
	return e is RangedEnemy and not e is SpreadEnemy


func _is_spearman(e: Node) -> bool:
	return e is SpearmanEnemy


func _is_orb(e: Node) -> bool:
	return e is OrbEnemy


func _is_jumper(e: Node) -> bool:
	return e is BlastJumperEnemy


func _is_brute(e: Node) -> bool:
	return e is BruteEnemy


func _is_slug(e: Node) -> bool:
	return e is SlugEnemy


func _check_common(level: Node, number: int) -> void:
	var label := "Nivel %d" % number
	_check(level.level_variant == number, "%s usa su variante" % label)
	_check(level.level_name == "NIVEL %d-%d" % [(number - 1) / 5 + 1, (number - 1) % 5 + 1], "%s se identifica por su código zona-nivel" % label)
	_check(level.next_level_path == NEXT[number], "%s encadena con la escena siguiente" % label)
	_check(level.time_limit == 70.0, "%s tiene 70 segundos" % label)
	_check(LevelRegistry.is_implemented(number) and LevelRegistry.get_level(number).display_name == NAMES[number], "%s está en el registro como %s" % [label, NAMES[number]])
	_check(level.get_node("Platforms").get_child_count() == 0, "%s limpia las plataformas base" % label)
	var player: Player = level.get_node("Player")
	_check(player.global_position.x <= 100.0, "%s empieza en el extremo izquierdo" % label)
	_check(PlatformSpacing.collect_violations(level).is_empty(), "%s respeta el espaciado mínimo" % label)
	_check(get_nodes_in_group("checkpoints").size() == 1, "%s tiene un único control" % label)
	_check(get_nodes_in_group("coins").is_empty(), "%s no tiene monedas" % label)
	var fallen := 0
	for enemy in get_nodes_in_group("enemies"):
		if not enemy is OrbEnemy and enemy.global_position.y > 700.0:
			fallen += 1
	_check(fallen == 0, "%s: ningún enemigo cae al vacío" % label)
	var wind := get_nodes_in_group("wind_fields")
	_check(wind.size() == 1 and (wind[0] as WindField).segments.size() == 3, "%s tiene viento en tres tramos" % label)


func _world(level: Node, node_name: String) -> Node:
	return level.get_node_or_null(node_name)


func _fall_zone_ok(world: Node, zone_name: String, width: float, label: String) -> void:
	var zone := world.get_node_or_null(zone_name) as Area2D
	_check(zone != null and (zone.get_node("CollisionShape2D").shape as RectangleShape2D).size.x >= width, "%s: la zona de caída cubre todo el ancho" % label)


func _portal_ok(level: Node, min_x: float, width: float, label: String) -> void:
	_check((level.get_node("ExitPortal") as Node2D).global_position.x >= min_x, "%s: el portal está en la isla final" % label)
	_check((level.get_node("Camera") as Camera2D).limit_right == int(width), "%s: la cámara cubre todo el nivel" % label)


func _check_twelve(level: Node) -> void:
	var world := _world(level, "LevelTwelveGenerated")
	_check(world != null, "Nivel 12: se generó el escenario")
	_check(_count(_is_spearman) == 7 and get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is SpearmanEnemy and e.narrow).size() == 2, "Nivel 12: 7 lanceros, 2 de ellos estrechos")
	_check(_count(_is_jumper) == 5 and get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is BlastJumperEnemy and e.long_jump).size() == 2, "Nivel 12: 5 saltadores, 2 de salto largo")
	_check(_count(_is_orb) == 2 and get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is OrbEnemy and e.axis == OrbEnemy.Axis.VERTICAL).size() == 1, "Nivel 12: 2 orbes, 1 vertical")
	_check(_count(_is_archer) == 3 and _count(_is_mage) == 2, "Nivel 12: arqueros y magos")
	_check(get_nodes_in_group("saws").size() == 2, "Nivel 12: sierras en el suelo")
	_check(get_nodes_in_group("healing_pickups").size() == 3, "Nivel 12: tres hierbas")
	var kinds := {}
	for node in world.get_children():
		if node is Platform:
			kinds[node.kind] = true
	_check(kinds.has(Platform.Kind.HORIZONTAL) and kinds.has(Platform.Kind.CIRCULAR), "Nivel 12: puentes de vaivén y circulares")
	for index in LevelTwelveLayout.SECTION_COUNT - 1:
		var gap := LevelTwelveLayout.section_start(index + 1) - (LevelTwelveLayout.section_start(index) + LevelTwelveLayout.SECTION_WIDTH)
		_check(is_equal_approx(gap, 300.0), "Nivel 12: el foso %d mide 300 px" % (index + 1))
	_fall_zone_ok(world, "FallZoneDunes", LevelTwelveLayout.LEVEL_WIDTH, "Nivel 12")
	_portal_ok(level, LevelTwelveLayout.FINAL_START_X, LevelTwelveLayout.LEVEL_WIDTH, "Nivel 12")


func _check_thirteen(level: Node) -> void:
	var world := _world(level, "LevelThirteenGenerated")
	_check(world != null, "Nivel 13: se generó el escenario")
	var route: Array[Platform] = []
	var kinds := {}
	var islands := 0
	for node in world.get_children():
		if node is Platform and node.name.begins_with("OasisPlatform"):
			route.append(node)
			kinds[node.kind] = true
			if node.platform_size.x > LevelThirteenLayout.PLATFORM_SIZE.x:
				islands += 1
	_check(route.size() == LevelThirteenLayout.ROUTE_COUNT, "Nivel 13: ruta de %d plataformas" % LevelThirteenLayout.ROUTE_COUNT)
	for kind in [Platform.Kind.STATIC, Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR, Platform.Kind.ROTATING]:
		_check(kinds.has(kind), "Nivel 13: la ruta usa el tipo %d" % kind)
	_check(islands == 6, "Nivel 13: seis islas anchas")
	_check(_count(_is_brute) == 2 and get_nodes_in_group("rock_piles").size() == 2, "Nivel 13: dos brutos con su pila")
	_check(_count(_is_archer) == 2 and _count(_is_mage) == 1, "Nivel 13: arqueros y mago en las islas (sin enemigos sobre las rocas)")
	_check(_count(_is_orb) == 3, "Nivel 13: tres orbes sobre el agua")
	_check(get_nodes_in_group("saws").size() == 3, "Nivel 13: tres sierras suspendidas")
	var bats := world.get_node_or_null("FlyingSpawner") as FlyingSpawner
	_check(bats != null and is_equal_approx(bats.spawn_interval, 4.5), "Nivel 13: un murciélago cada 4,5 s")
	_check(get_nodes_in_group("healing_pickups").size() == 2, "Nivel 13: dos hierbas")
	var strongest := 0.0
	for segment in (get_nodes_in_group("wind_fields")[0] as WindField).segments:
		strongest = maxf(strongest, absf(float(segment["speed"])))
	_check(strongest <= 80.0, "Nivel 13: el viento es suave (%.0f px/s)" % strongest)
	_fall_zone_ok(world, "FallZoneOasis", LevelThirteenLayout.LEVEL_WIDTH, "Nivel 13")
	_portal_ok(level, LevelThirteenLayout.END_START_X, LevelThirteenLayout.LEVEL_WIDTH, "Nivel 13")


func _check_fourteen(level: Node) -> void:
	var world := _world(level, "LevelFourteenGenerated")
	_check(world != null, "Nivel 14: se generó el escenario")
	var route: Array[Platform] = []
	var ledges := 0
	for node in world.get_children():
		if node is Platform and node.name.begins_with("CanyonPlatform"):
			route.append(node)
			if node.platform_size.x > LevelFourteenLayout.PLATFORM_SIZE.x:
				ledges += 1
	_check(route.size() == LevelFourteenLayout.ROUTE_COUNT, "Nivel 14: ruta de %d plataformas" % LevelFourteenLayout.ROUTE_COUNT)
	_check(ledges == 5, "Nivel 14: cinco repisas anchas")
	var tiers := {}
	var max_step := 0.0
	for index in route.size():
		tiers[LevelFourteenLayout.route_y(index)] = true
		if index > 0:
			max_step = maxf(max_step, absf(LevelFourteenLayout.route_y(index) - LevelFourteenLayout.route_y(index - 1)))
	_check(tiers.size() == 5 and tiers.has(150.0), "Nivel 14: cinco alturas, hasta 150 px")
	_check(max_step <= 100.1, "Nivel 14: desniveles de una altura como máximo")
	var rocks := world.get_node_or_null("RockfallSpawner") as RockfallSpawner
	_check(rocks != null and rocks.interval <= 2.2 / 3.0 + 0.01 and rocks.ahead_direction > 0.0, "Nivel 14: rocas por delante, el triple de a menudo")
	_check(world.get_node_or_null("SkySentry") is SkySentry, "Nivel 14: centinela en la esquina")
	_check(_count(_is_jumper) == 2 and get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is BlastJumperEnemy and e.long_jump).size() == 1, "Nivel 14: dos saltadores, uno de salto largo")
	_check(_count(_is_brute) == 1 and get_nodes_in_group("rock_piles").size() == 1, "Nivel 14: un bruto con su pila")
	_check(_count(_is_spearman) == 3, "Nivel 14: tres lanceros estrechos")
	_check(_count(_is_archer) == 3 and _count(_is_mage) == 3, "Nivel 14: arqueros y magos")
	_check(_count(_is_orb) == 3 and get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is OrbEnemy and e.axis == OrbEnemy.Axis.VERTICAL).size() == 1, "Nivel 14: tres orbes, uno vertical")
	_check(get_nodes_in_group("saws").size() == 3, "Nivel 14: tres sierras suspendidas")
	_check(get_nodes_in_group("healing_pickups").size() == 2, "Nivel 14: dos hierbas")
	_fall_zone_ok(world, "FallZoneCanyon", LevelFourteenLayout.LEVEL_WIDTH, "Nivel 14")
	_portal_ok(level, LevelFourteenLayout.END_START_X, LevelFourteenLayout.LEVEL_WIDTH, "Nivel 14")


func _check_fifteen(level: Node) -> void:
	var world := _world(level, "LevelFifteenGenerated")
	_check(world != null, "Nivel 15: se generó el escenario")
	_check(_count(_is_spearman) == 4, "Nivel 15: cuatro lanceros")
	_check(_count(_is_slug) == 2 and get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is SlugEnemy and e.double_jump).size() == 1, "Nivel 15: dos babosas, una de doble salto")
	_check(_count(_is_jumper) == 3, "Nivel 15: tres saltadores explosivos")
	_check(_count(_is_brute) == 2 and get_nodes_in_group("rock_piles").size() == 2, "Nivel 15: dos brutos con su pila")
	_check(_count(_is_orb) == 3, "Nivel 15: tres orbes")
	_check(_count(_is_archer) == 3 and _count(_is_mage) == 4, "Nivel 15: arqueros y magos")
	_check(get_nodes_in_group("saws").size() == 2, "Nivel 15: sierras suspendidas")
	_check(get_nodes_in_group("healing_pickups").size() == 2, "Nivel 15: dos hierbas")
	var rocks := world.get_node_or_null("RockfallSpawner") as RockfallSpawner
	_check(rocks != null and rocks.max_x < LevelFifteenLayout.END_START_X, "Nivel 15: las rocas no caen en la isla final")
	_check(world.get_node_or_null("SkySentry") is SkySentry, "Nivel 15: centinela en la esquina")
	_check(world.get_node_or_null("FlyingSpawner") is FlyingSpawner, "Nivel 15: murciélagos")
	_fall_zone_ok(world, "FallZoneStorm", LevelFifteenLayout.LEVEL_WIDTH, "Nivel 15")
	_portal_ok(level, LevelFifteenLayout.END_START_X, LevelFifteenLayout.LEVEL_WIDTH, "Nivel 15")


func _wait_physics(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
