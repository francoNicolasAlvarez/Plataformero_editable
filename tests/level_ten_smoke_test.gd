extends SceneTree
## Comprueba el nivel 10 "TEMPLO" (2026-11-17): ruta zigzagueante de 24
## plataformas en cuatro alturas con los cinco tipos del asset modular,
## altares con arquero o mago, sierras suspendidas, murciélagos, un control,
## hierbas y portal en la isla final. Ejecutar con:
## godot --headless --path . --script res://tests/level_ten_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_ten.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(30)

	var portal: ExitPortal = level.get_node("ExitPortal")
	var camera: Camera2D = level.get_node("Camera")
	var player: Player = level.get_node("Player")
	var world := level.get_node_or_null("LevelTenGenerated")

	_check(level.level_variant == 10, "El nivel 10 usa la variante TEMPLO")
	_check(level.level_name == "NIVEL 2-5", "El nivel se identifica como NIVEL 2-5")
	_check(level.next_level_path == "res://scenes/levels/level_eleven.tscn", "El nivel 10 lleva al nivel 11")
	_check(level.time_limit == 70.0, "El nivel 10 tiene 70 segundos")
	_check(world != null, "Se generó el escenario del nivel 10")
	_check(level.get_node("Platforms").get_child_count() == 0, "El nivel 10 limpia las plataformas base")
	_check(player.global_position.x <= 100.0, "El jugador empieza en el extremo izquierdo")
	_check(PlatformSpacing.collect_violations(level).is_empty(), "Las plataformas respetan el espaciado mínimo")

	var route: Array[Platform] = []
	var kinds := {}
	var last_route_x := LevelTenLayout.route_x(LevelTenLayout.ROUTE_COUNT - 1)
	for platform in _collect_platforms(world):
		if platform.name.begins_with("TempleSkyStep"):
			continue
		if platform.position.x >= LevelTenLayout.ROUTE_START_X - 1.0 and platform.position.x <= last_route_x + 1.0:
			route.append(platform)
			kinds[platform.kind] = true
	route.sort_custom(func(a: Platform, b: Platform) -> bool: return a.position.x < b.position.x)
	_check(route.size() == LevelTenLayout.ROUTE_COUNT, "La ruta tiene %d plataformas" % LevelTenLayout.ROUTE_COUNT)
	for kind in [Platform.Kind.STATIC, Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR, Platform.Kind.SPIKED, Platform.Kind.ROTATING]:
		_check(kinds.has(kind), "La ruta usa el tipo de plataforma %d" % kind)

	var tiers := {}
	var max_gap := 0.0
	var max_step := 0.0
	for index in route.size():
		# Las plataformas móviles se desplazan: se compara con la altura de diseño.
		tiers[LevelTenLayout.route_y(index)] = true
		if index > 0:
			var left_half := route[index - 1].platform_size.x * 0.5
			var right_half := route[index].platform_size.x * 0.5
			max_gap = maxf(max_gap, route[index].position.x - route[index - 1].position.x - left_half - right_half)
			max_step = maxf(max_step, absf(LevelTenLayout.route_y(index) - LevelTenLayout.route_y(index - 1)))
	_check(tiers.size() == 4, "La ruta usa cuatro alturas")
	_check(max_gap <= 360.0, "Los saltos horizontales son alcanzables (máximo %.0f px)" % max_gap)
	_check(max_step <= 100.1, "Los desniveles son de una altura como máximo (%.0f px)" % max_step)

	var first := route[0]
	var last := route[route.size() - 1]
	_check(first.position.x - first.platform_size.x * 0.5 - LevelTenLayout.START_WIDTH <= 300.0, "La primera plataforma está al alcance del inicio")
	_check(LevelTenLayout.END_START_X - (last.position.x + last.platform_size.x * 0.5) <= 300.0, "La última plataforma está al alcance del final")

	var altars := 0
	for platform in route:
		if platform.platform_size.x > LevelTenLayout.PLATFORM_SIZE.x:
			altars += 1
	_check(altars == 4, "Hay cuatro altares anchos")
	var archers := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is SpreadEnemy)
	var mages := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is RangedEnemy and not e is SpreadEnemy)
	_check(archers.size() == 6, "Hay %d arqueros: dos en altares y cuatro en plataformas altas" % archers.size())
	_check(mages.size() == 2, "Hay %d magos sobre la ruta" % mages.size())
	var sky_steps := _collect_platforms(world).filter(func(p: Platform) -> bool: return p.name.begins_with("TempleSkyStep"))
	_check(sky_steps.size() == 4, "Hay cuatro plataformas altas")
	for step in sky_steps:
		_check(is_equal_approx(step.position.y, LevelTenLayout.SKY_TIER), "La plataforma alta %s está a 150 px" % step.name)
	var brutes := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is BruteEnemy)
	var slugs := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is SlugEnemy)
	_check(brutes.size() == 2 and get_nodes_in_group("rock_piles").size() == 2, "Hay dos brutos, cada uno con su pila de rocas")
	_check(slugs.size() == 4, "Hay cuatro babosas saltarinas")
	_check(slugs.filter(func(s: SlugEnemy) -> bool: return s.double_jump).size() == 2, "Dos de las babosas son de doble salto")
	var rocks := world.get_node_or_null("RockfallSpawner") as RockfallSpawner
	_check(rocks != null and rocks.interval <= 2.2 / 3.0 + 0.01, "Caen rocas el triple de a menudo")
	_check(rocks != null and rocks.ahead_direction > 0.0 and rocks.max_x <= LevelTenLayout.END_START_X, "Las rocas caen por delante y no sobre la isla final")
	_check(get_nodes_in_group("saws").size() == LevelTenLayout.AIR_SAW_INDICES.size(), "Hay sierras suspendidas entre plataformas")
	var spawner := world.get_node_or_null("FlyingSpawner") as FlyingSpawner
	_check(spawner != null and is_equal_approx(spawner.spawn_interval, 4.0), "Un murciélago cada 4 s")
	_check(get_nodes_in_group("checkpoints").size() == 1, "El nivel 10 tiene un único control")
	_check(get_nodes_in_group("healing_pickups").size() == 3, "El nivel 10 incluye tres hierbas")
	_check(get_nodes_in_group("coins").is_empty(), "El nivel 10 no tiene monedas")
	_check(portal.global_position.x >= LevelTenLayout.END_START_X, "El portal está en la isla final")
	_check(camera.limit_right == int(LevelTenLayout.LEVEL_WIDTH), "La cámara cubre todo el nivel 10")
	var fall_zone := world.get_node_or_null("FallZoneTemple") as Area2D
	_check(fall_zone != null, "El nivel 10 tiene zona de caída")
	if fall_zone != null:
		var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
		_check(fall_shape.size.x >= LevelTenLayout.LEVEL_WIDTH, "La zona de caída cubre todo el ancho")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _collect_platforms(node: Node) -> Array[Platform]:
	var found: Array[Platform] = []
	if node is Platform:
		found.append(node)
	for child in node.get_children():
		found.append_array(_collect_platforms(child))
	return found


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
