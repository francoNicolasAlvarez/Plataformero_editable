extends SceneTree
## Comprueba el nivel 9 "RUINAS" (2026-11-17): fosos de 280 px, escalones y
## puentes, enemigos y trampas por sección, un control, hierbas, portal en la
## isla final y zona de caída a todo el ancho. Ejecutar con:
## godot --headless --path . --script res://tests/level_nine_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_nine.tscn")

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
	var world := level.get_node_or_null("LevelNineGenerated")

	_check(level.level_variant == 9, "El nivel 9 usa la variante RUINAS")
	_check(level.level_name == "NIVEL 2-4", "El nivel se identifica como NIVEL 2-4")
	_check(level.next_level_path == "res://scenes/levels/level_ten.tscn", "El nivel 9 lleva al nivel 10")
	_check(level.time_limit == 70.0, "El nivel 9 tiene 70 segundos")
	_check(world != null, "Se generó el escenario del nivel 9")
	_check(level.get_node("Platforms").get_child_count() == 0, "El nivel 9 limpia las plataformas base")
	_check(player.global_position.x <= 100.0, "El jugador empieza en el extremo izquierdo")
	_check(PlatformSpacing.collect_violations(level).is_empty(), "Las plataformas respetan el espaciado mínimo")

	# Fosos: cada tramo de suelo termina 280 px antes del siguiente.
	var last_ground_end := LevelNineLayout.section_start(LevelNineLayout.SECTION_COUNT - 1) + LevelNineLayout.SECTION_WIDTH
	for index in LevelNineLayout.SECTION_COUNT - 1:
		var gap := LevelNineLayout.section_start(index + 1) - (LevelNineLayout.section_start(index) + LevelNineLayout.SECTION_WIDTH)
		_check(is_equal_approx(gap, 280.0), "El foso %d mide 280 px" % (index + 1))
	_check(is_equal_approx(LevelNineLayout.FINAL_START_X - last_ground_end, 280.0), "El foso final mide 280 px")

	var walkers := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is WalkerEnemy)
	var archers := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is SpreadEnemy)
	var mages := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is RangedEnemy and not e is SpreadEnemy)
	_check(walkers.size() >= 9, "Hay caminantes en cada sección (%d)" % walkers.size())
	_check(archers.size() == 8, "Hay %d arqueros repartidos por las ruinas" % archers.size())
	_check(mages.size() == 8, "Hay %d magos repartidos por las ruinas" % mages.size())
	_check(archers.size() + mages.size() >= 16, "Hay muchos más enemigos que lanzan proyectiles")

	var top_steps := 0
	var peak_steps := 0
	for platform in _collect_platforms(world):
		if is_equal_approx(platform.position.y, LevelNineLayout.TIER_TOP):
			top_steps += 1
		if is_equal_approx(platform.position.y, LevelNineLayout.TIER_PEAK):
			peak_steps += 1
	_check(top_steps == LevelNineLayout.SECTION_COUNT, "Cada sección tiene una plataforma a 330 px")
	_check(peak_steps == LevelNineLayout.SECTION_COUNT, "Cada sección tiene una plataforma a 220 px")
	var rocks := world.get_node_or_null("RockfallSpawner") as RockfallSpawner
	_check(rocks != null and rocks.min_x >= 1500.0 and rocks.max_x <= 14300.0, "Las rocas solo caen en la zona de ruinas")
	_check(rocks != null and rocks.interval <= 2.2 / 3.0 + 0.01, "Caen el triple de rocas que en la versión anterior")
	_check(rocks != null and rocks.ahead_direction > 0.0 and rocks.min_ahead > 0.0, "Las rocas caen por delante del jugador")
	var brutes := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is BruteEnemy)
	_check(brutes.size() == 3, "Hay tres brutos lanzarrocas")
	_check(get_nodes_in_group("rock_piles").size() == 3, "Cada bruto tiene su pila de rocas")
	var bats := world.get_node_or_null("FlyingSpawner") as FlyingSpawner
	_check(bats != null and is_equal_approx(bats.spawn_interval, 5.0), "Hay un murciélago cada 5 s")

	var over_pit := 0
	for enemy in get_nodes_in_group("enemies"):
		var x: float = enemy.global_position.x
		for index in LevelNineLayout.SECTION_COUNT:
			var pit_start := LevelNineLayout.section_start(index) + LevelNineLayout.SECTION_WIDTH
			if x > pit_start and x < pit_start + 280.0:
				over_pit += 1
	_check(over_pit == 0, "Ningún enemigo nace sobre un foso")

	_check(get_nodes_in_group("saws").size() == 3, "Hay una sierra en tres secciones")
	_check(get_nodes_in_group("checkpoints").size() == 1, "El nivel 9 tiene un único control")
	_check(get_nodes_in_group("healing_pickups").size() == 3, "El nivel 9 incluye tres hierbas")
	var checkpoint: Node2D = get_nodes_in_group("checkpoints")[0]
	var expected_x := LevelNineLayout.section_start(LevelNineLayout.CHECKPOINT_SECTION) + 80.0
	_check(absf(checkpoint.global_position.x - expected_x) < 1.0, "El control está en la sección central")
	_check(get_nodes_in_group("coins").is_empty(), "El nivel 9 no tiene monedas")

	var kinds := {}
	for platform in _collect_platforms(world):
		kinds[platform.kind] = true
	_check(kinds.has(Platform.Kind.HORIZONTAL) and kinds.has(Platform.Kind.CIRCULAR), "Los puentes incluyen vaivén y órbita")
	_check(portal.global_position.x >= LevelNineLayout.FINAL_START_X, "El portal está en la isla final")
	_check(camera.limit_right == int(LevelNineLayout.LEVEL_WIDTH), "La cámara cubre todo el nivel 9")
	var fall_zone := world.get_node_or_null("FallZoneRuins") as Area2D
	_check(fall_zone != null, "El nivel 9 tiene zona de caída")
	if fall_zone != null:
		var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
		_check(fall_shape.size.x >= LevelNineLayout.LEVEL_WIDTH, "La zona de caída cubre todo el ancho")

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
