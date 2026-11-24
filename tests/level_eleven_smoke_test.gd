extends SceneTree
## Comprueba el nivel 11 "VIENTO" (2026-11-17): 34 plataformas con los cinco
## tipos, viento en tres tramos, sierras suspendidas, arqueros y magos, los
## enemigos nuevos (lanceros, orbes y saltadores explosivos), un control y el
## portal en la isla final. Ejecutar con:
## godot --headless --path . --script res://tests/level_eleven_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_eleven.tscn")

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
	var world := level.get_node_or_null("LevelElevenGenerated")

	_check(level.level_variant == 11, "El nivel 11 usa la variante VIENTO")
	_check(level.level_name == "NIVEL 3-1", "El nivel se identifica como NIVEL 3-1")
	_check(level.next_level_path == "res://scenes/levels/level_twelve.tscn", "El nivel 11 lleva al nivel 12")
	_check(level.time_limit == 70.0, "El nivel 11 tiene 70 segundos")
	_check(world != null, "Se generó el escenario del nivel 11")
	_check(level.get_node("Platforms").get_child_count() == 0, "El nivel 11 limpia las plataformas base")
	_check(player.global_position.x <= 100.0, "El jugador empieza en el extremo izquierdo")
	_check(PlatformSpacing.collect_violations(level).is_empty(), "Las plataformas respetan el espaciado mínimo")
	_check(LevelRegistry.is_implemented(11) and LevelRegistry.get_level(11).display_name == "VIENTO", "El registro incluye el nivel 11 (3-1)")

	var route: Array[Platform] = []
	var kinds := {}
	for platform in _collect_platforms(world):
		if platform.name.begins_with("WindPlatform"):
			route.append(platform)
			kinds[platform.kind] = true
	route.sort_custom(func(a: Platform, b: Platform) -> bool: return a.position.x < b.position.x)
	_check(route.size() == LevelElevenLayout.ROUTE_COUNT, "La ruta tiene %d plataformas" % LevelElevenLayout.ROUTE_COUNT)
	for kind in [Platform.Kind.STATIC, Platform.Kind.HORIZONTAL, Platform.Kind.CIRCULAR, Platform.Kind.SPIKED, Platform.Kind.ROTATING]:
		_check(kinds.has(kind), "La ruta usa el tipo de plataforma %d" % kind)
	var max_gap := 0.0
	var max_step := 0.0
	var bastions := 0
	for index in route.size():
		if route[index].platform_size.x > LevelElevenLayout.PLATFORM_SIZE.x:
			bastions += 1
		if index > 0:
			# Posiciones de diseño: las plataformas móviles se desplazan.
			var gap := LevelElevenLayout.route_x(index) - LevelElevenLayout.route_x(index - 1) - route[index].platform_size.x * 0.5 - route[index - 1].platform_size.x * 0.5
			max_gap = maxf(max_gap, gap)
			max_step = maxf(max_step, absf(LevelElevenLayout.route_y(index) - LevelElevenLayout.route_y(index - 1)))
	_check(max_gap <= 200.0, "Los saltos son cortos para compensar el viento (máximo %.0f px)" % max_gap)
	_check(max_step <= 100.1, "Los desniveles son de una altura como máximo (%.0f px)" % max_step)
	_check(bastions == 5, "Hay cinco fortines anchos")
	_check(LevelElevenLayout.ROUTE_START_X - route[0].platform_size.x * 0.5 - LevelElevenLayout.START_WIDTH <= 300.0, "La primera plataforma está al alcance del inicio")
	_check(LevelElevenLayout.END_START_X - (route[route.size() - 1].position.x + route[route.size() - 1].platform_size.x * 0.5) <= 300.0, "La última plataforma está al alcance del final")

	# Viento.
	var wind := world.get_node_or_null("WindField") as WindField
	_check(wind != null and wind.segments.size() == 3, "El viento tiene tres tramos")
	if wind != null:
		var signs: Array[float] = []
		for segment in wind.segments:
			signs.append(signf(float(segment["speed"])))
		_check(signs[0] < 0.0 and signs[1] > 0.0 and signs[2] < 0.0, "El viento cambia de sentido: en contra, a favor y en contra")
		_check(float(wind.segments[0]["from"]) >= LevelElevenLayout.START_WIDTH, "No hay viento en la isla de inicio")
		_check(float(wind.segments[2]["to"]) <= LevelElevenLayout.END_START_X, "No hay viento en la isla final")

	# Enemigos y trampas.
	var enemies := get_nodes_in_group("enemies")
	var archers := enemies.filter(func(e: Node) -> bool: return e is SpreadEnemy)
	var mages := enemies.filter(func(e: Node) -> bool: return e is RangedEnemy and not e is SpreadEnemy)
	var spearmen := enemies.filter(func(e: Node) -> bool: return e is SpearmanEnemy)
	var orbs := enemies.filter(func(e: Node) -> bool: return e is OrbEnemy)
	var jumpers := enemies.filter(func(e: Node) -> bool: return e is BlastJumperEnemy)
	_check(archers.size() == 4 and mages.size() == 4, "Hay 4 arqueros y 4 magos que disparan proyectiles")
	_check(spearmen.size() == 3 and spearmen.filter(func(e: SpearmanEnemy) -> bool: return e.narrow).size() == 2, "Hay 3 lanceros, dos de ellos de plataforma estrecha")
	_check(orbs.size() == 3 and orbs.filter(func(e: OrbEnemy) -> bool: return e.axis == OrbEnemy.Axis.VERTICAL).size() == 1, "Hay 3 orbes, uno vertical")
	_check(jumpers.size() == 2 and jumpers.filter(func(e: BlastJumperEnemy) -> bool: return e.long_jump).size() == 1, "Hay 2 saltadores explosivos, uno de salto largo")
	_check(get_nodes_in_group("saws").size() == LevelElevenLayout.AIR_SAW_INDICES.size(), "Hay sierras suspendidas entre plataformas")
	var spiked := 0
	for platform in route:
		if platform.kind == Platform.Kind.SPIKED:
			spiked += 1
	_check(spiked >= 5, "Hay varias plataformas con pinchos (%d)" % spiked)
	var fell := 0
	for enemy in enemies:
		if enemy is OrbEnemy:
			continue
		if enemy.global_position.y > 700.0:
			fell += 1
	_check(fell == 0, "Ningún enemigo cae al vacío")
	_check(get_nodes_in_group("checkpoints").size() == 1, "El nivel 11 tiene un único control")
	_check(get_nodes_in_group("healing_pickups").size() == 3, "El nivel 11 incluye tres hierbas")
	_check(get_nodes_in_group("coins").is_empty(), "El nivel 11 no tiene monedas")
	_check(portal.global_position.x >= LevelElevenLayout.END_START_X, "El portal está en la isla final")
	_check(camera.limit_right == int(LevelElevenLayout.LEVEL_WIDTH), "La cámara cubre todo el nivel 11")
	var fall_zone := world.get_node_or_null("FallZoneWind") as Area2D
	_check(fall_zone != null, "El nivel 11 tiene zona de caída")
	if fall_zone != null:
		var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
		_check(fall_shape.size.x >= LevelElevenLayout.LEVEL_WIDTH, "La zona de caída cubre todo el ancho")

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
