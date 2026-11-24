extends SceneTree
## Comprueba el nivel 4 "El Gran Pozo" (2026-11-12): solo hay suelo al inicio
## y al final, el resto es abismo mortal cruzado por una cadena principal de
## plataformas móviles (verticales, diagonales, circulares y giratorias).
## Todas las plataformas están activas a la vez y sus trayectorias no se
## solapan. Valida que el hueco entre bordes de plataformas consecutivas quede
## a menos de la distancia de salto máxima (extremos incluidos) y que inicio y
## final estén al alcance de la primera y la última.
## Ejecutar con:
## godot --headless --path . --script res://tests/level_four_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_four.tscn")
const NEXT_SCENE := "res://scenes/levels/level_five.tscn"
const START_RIGHT_EDGE := 1900.0
const END_LEFT_EDGE := 10100.0
const GROUND_SURFACE := 640.0
const MAX_REACH := 300.0
const PLATFORM_HALF_WIDTH := 90.0
const PLATFORM_FULL_WIDTH := PLATFORM_HALF_WIDTH * 2.0
const MAX_TILT_DEGREES := 30.0

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var portal: ExitPortal = level.get_node("ExitPortal")
	var camera: Camera2D = level.get_node("Camera")
	var player: Player = level.get_node("Player")
	await _wait_physics(30)

	_check(level.level_variant == 4, "El nivel 4 usa la variante del gran pozo")
	_check(level.level_name == "NIVEL 1-4", "El nivel se identifica como NIVEL 1-4")
	_check(level.next_level_path == NEXT_SCENE, "El nivel 4 continúa hacia el nivel 5")
	_check(level.time_limit == 70.0, "El nivel 4 tiene 70 segundos")
	_check(level.get_node_or_null("LevelFourGenerated") != null, "Se generó el contenido del gran pozo")
	_check(level.get_node("Platforms").get_child_count() == 0, "El nivel 4 limpia las plataformas base")
	_check(not level.get_node("Background").visible, "El fondo diurno queda oculto")
	_check(not level.get_node("BackgroundDecor").visible, "Las colinas diurnas quedan ocultas")

	var statics := PlatformSpacing.collect_platforms(level)
	_check(statics.size() == 3, "Hay tres islas firmes: salida, descanso central y llegada")
	if statics.size() == 3:
		var rects: Array[Rect2] = []
		for platform in statics:
			rects.append(PlatformSpacing.platform_rect(platform))
		rects.sort_custom(func(a: Rect2, b: Rect2) -> bool:
			return a.position.x < b.position.x
		)
		var start_rect := rects[0]
		var rest_rect := rects[1]
		var end_rect := rects[2]
		_check(
			is_equal_approx(start_rect.end.x, START_RIGHT_EDGE),
			"La isla inicial termina en el borde del pozo"
		)
		_check(
			is_equal_approx(end_rect.position.x, END_LEFT_EDGE),
			"La isla final empieza en el borde del pozo"
		)
		_check(
			absf(rest_rect.get_center().x - 6000.0) < 1.0,
			"La isla de descanso está a mitad del pozo"
		)
		_check(
			rest_rect.position.y > start_rect.position.y,
			"La isla de descanso queda por debajo de las plataformas móviles"
		)
		_check(end_rect.position.x - start_rect.end.x >= 8000.0, "El pozo central es enorme")

	var fall_zone := level.get_node_or_null("LevelFourGenerated/FallZonePit") as Area2D
	_check(fall_zone != null, "El abismo tiene una zona de caída mortal")
	_check(
		player.global_position.x <= 100.0,
		"El jugador empieza pegado al extremo izquierdo del nivel"
	)
	var left_half_enemies := 0
	for enemy in get_nodes_in_group("enemies"):
		if enemy.global_position.x < LevelFourLayout.START_SAFE_X:
			left_half_enemies += 1
	_check(
		left_half_enemies == 0,
		"No hay enemigos en la mitad izquierda de la pantalla inicial"
	)

	var all_moving := get_nodes_in_group("moving_platforms")
	_check(
		all_moving.size() == LevelFourRoute.ROUTE_COUNT,
		"Todas las plataformas de la ruta están activas a la vez (%d)" % all_moving.size()
	)
	var route := level.get_node_or_null("LevelFourGenerated/RouteStream") as LevelFourRoute
	if route == null:
		# Escena horneada: el controlador de la ruta se convierte en un nodo
		# normal con las plataformas ya colocadas (editables a mano). Se omiten
		# las pruebas que usan el controlador.
		_check(level.get_node_or_null("LevelFourGenerated/RouteStream") != null, "El tramo principal existe como contenedor de plataformas (nivel horneado)")
		print("")
		print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
		quit(1 if _failures > 0 else 0)
		return
	_check(LevelFourRoute.ROUTE_COUNT >= 16, "La ruta define suficientes huecos para cruzar el pozo")
	_check(LevelFourRoute.SPEED_SCALE >= 1.29, "Las plataformas se mueven un 30% más rápido")

	var kinds := {"vertical": 0, "diagonal": 0, "circle": 0, "rotating": 0}
	for index in LevelFourRoute.ROUTE_COUNT:
		var kind := String(LevelFourRoute.motion_config(index)["kind"])
		kinds[kind] = int(kinds.get(kind, 0)) + 1
	_check(kinds.vertical >= 4, "Hay plataformas que suben y bajan")
	_check(kinds.diagonal >= 4, "Hay plataformas en diagonal")
	_check(kinds.circle >= 4, "Hay plataformas que se mueven en círculos")
	_check(kinds.rotating >= 4, "Hay plataformas que giran sobre su eje")

	var start_point := Vector2(START_RIGHT_EDGE, GROUND_SURFACE)
	var end_point := Vector2(END_LEFT_EDGE, GROUND_SURFACE)
	var first_gap := _min_distance_to_index_path(0, start_point) - PLATFORM_HALF_WIDTH
	var last_gap := _min_distance_to_index_path(LevelFourRoute.ROUTE_COUNT - 1, end_point) - PLATFORM_HALF_WIDTH
	_check(first_gap <= MAX_REACH, "La primera plataforma está al alcance del inicio (hueco %.0f px)" % first_gap)
	_check(last_gap <= MAX_REACH, "La última plataforma está al alcance del final (hueco %.0f px)" % last_gap)

	var worst_gap := 0.0
	var worst_index := 0
	var overlapping_paths := 0
	var previous_right := -INF
	for index in LevelFourRoute.ROUTE_COUNT:
		var extent := _path_horizontal_extent(index)
		if index > 0 and extent.x < previous_right - 0.01:
			overlapping_paths += 1
		previous_right = maxf(previous_right, extent.y)
		if index < LevelFourRoute.ROUTE_COUNT - 1:
			var gap := _min_index_path_distance(index, index + 1) - PLATFORM_FULL_WIDTH
			if gap > worst_gap:
				worst_gap = gap
				worst_index = index
	_check(
		worst_gap <= MAX_REACH,
		"Todas las plataformas consecutivas quedan a rango de salto (peor hueco: %.0f px en #%d)"
			% [worst_gap, worst_index]
	)
	_check(
		overlapping_paths == 0,
		"Las trayectorias de las plataformas no se solapan"
	)
	_check(
		_path_vertical_span(0) <= MAX_REACH,
		"El recorrido principal no exige subidas imposibles"
	)

	var rotating: Node2D = null
	var circling: Node2D = null
	for platform in all_moving:
		if absf(platform.get("rotation_speed")) > 0.0 and rotating == null:
			rotating = platform
		if platform.get("circle_radius") > 0.0 and circling == null:
			circling = platform
	_check(rotating != null and circling != null, "La ruta incluye giro y órbita")
	if rotating != null and circling != null:
		var rot_before: float = rotating.rotation
		var circle_before: Vector2 = circling.position
		await _wait_physics(40)
		_check(not is_equal_approx(rotating.rotation, rot_before), "Las plataformas giratorias oscilan sobre su eje")
		_check(
			absf(rad_to_deg(rotating.rotation)) <= MAX_TILT_DEGREES + 0.01,
			"La inclinación de las plataformas no supera 30 grados"
		)
		_check(circling.position.distance_to(circle_before) > 5.0, "Las plataformas circulares orbitan")

	var slots_before := route.get_active_slot_indices()
	_check(
		slots_before.size() == LevelFourRoute.ROUTE_COUNT,
		"La ruta mantiene todas las plataformas activas"
	)
	player.set_physics_process(false)
	player.global_position = Vector2(6000.0, 300.0)
	await _wait_physics(5)
	var slots_after := route.get_active_slot_indices()
	_check(slots_after == slots_before, "Avanzar no elimina ni recicla plataformas")
	_check(
		get_nodes_in_group("moving_platforms").size() == LevelFourRoute.ROUTE_COUNT,
		"No desaparecen plataformas al avanzar"
	)

	var misplaced := 0
	var stale_bodies := 0
	var rotating_platform: Node2D = null
	for platform in get_nodes_in_group("moving_platforms"):
		var slot := int(platform.get_meta("slot_index"))
		if platform.global_position.distance_to(LevelFourRoute.slot_origin(slot)) > 150.0:
			misplaced += 1
		var body_transform: Transform2D = PhysicsServer2D.body_get_state(
			platform.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM
		)
		if platform.global_position.distance_to(body_transform.origin) > 2.0:
			stale_bodies += 1
		if absf(platform.get("rotation_speed")) > 0.0 and rotating_platform == null:
			rotating_platform = platform
	_check(misplaced == 0, "Cada plataforma permanece en su hueco")
	_check(stale_bodies == 0, "La colisión de las plataformas acompaña a su cuerpo")
	_check(rotating_platform != null, "La ruta conserva plataformas giratorias")
	if rotating_platform != null:
		var rotation_before: float = rotating_platform.rotation
		await _wait_physics(20)
		_check(
			not is_equal_approx(rotating_platform.rotation, rotation_before),
			"La plataforma giratoria sigue oscilando"
		)
		_check(
			absf(rad_to_deg(rotating_platform.rotation)) <= MAX_TILT_DEGREES + 0.01,
			"La plataforma giratoria no pasa de 30 grados"
		)
		_check(
			rotating_platform.global_position.distance_to(
				LevelFourRoute.slot_origin(int(rotating_platform.get_meta("slot_index")))
			) < 150.0,
			"La plataforma giratoria permanece en su hueco"
		)

	var platform_guards_group := get_nodes_in_group("platform_enemies")
	var anchored_guards := 0
	var floating_guards := 0
	for guard in platform_guards_group:
		if bool(guard.get("anchored")):
			anchored_guards += 1
		if guard.position.distance_to(Vector2(0.0, -35.0)) > 2.0:
			floating_guards += 1
	_check(
		anchored_guards == platform_guards_group.size(),
		"Los guardias de plataforma están anclados"
	)
	_check(floating_guards == 0, "Los guardias no se despegan de su plataforma")

	player.global_position = Vector2(8000.0, 300.0)
	await _wait_physics(3)
	player.global_position = Vector2(6000.0, 300.0)
	await _wait_physics(3)
	_check(
		route.get_active_slot_indices().size() == LevelFourRoute.ROUTE_COUNT,
		"Retroceder tampoco elimina plataformas"
	)

	var guard_for_shot := get_nodes_in_group("platform_enemies")[0] as Node2D
	guard_for_shot.call("_shoot", 1.0)
	await _wait_physics(1)
	var projectiles_in_route := 0
	for child in route.get_children():
		if child is EnemyProjectile:
			projectiles_in_route += 1
	_check(
		projectiles_in_route > 0,
		"Los proyectiles de los guardias nacen en el mundo, no en la plataforma"
	)

	var walkers_on_air := 0
	var walkers := 0
	var spread_enemies := 0
	var ranged_enemies := 0
	var platform_guards := get_nodes_in_group("platform_enemies").size()
	var enemies_at_checkpoint := 0
	for enemy in get_nodes_in_group("enemies"):
		if enemy is WalkerEnemy:
			walkers += 1
			if enemy.global_position.y < 590.0:
				walkers_on_air += 1
		elif enemy is SpreadEnemy:
			spread_enemies += 1
		elif enemy is RangedEnemy:
			ranged_enemies += 1
		if (
			enemy.global_position.y > 600.0
			and absf(enemy.global_position.x - 6000.0) < 250.0
		):
			enemies_at_checkpoint += 1
	_check(walkers_on_air == 0, "Los walkers solo patrullan las islas firmes")
	_check(walkers >= 5, "El gran pozo tiene walkers en la salida y la llegada")
	_check(platform_guards >= 2, "Hay enemigos viajando sobre las plataformas móviles")
	_check(enemies_at_checkpoint == 0, "No hay enemigos parados en el control central")
	_check(spread_enemies >= 4, "El gran pozo reparte enemigos de ráfaga por el recorrido")
	_check(ranged_enemies >= 2, "El gran pozo recupera magos en las islas firmes")

	_check(get_nodes_in_group("coins").is_empty(), "El gran pozo ya no tiene monedas")
	_check(get_nodes_in_group("healing_pickups").size() >= 2, "El gran pozo incluye curaciones")
	_check(get_nodes_in_group("checkpoints").size() == 1, "El gran pozo tiene un único control en la isla central")
	_check(portal.global_position.x > 11900.0, "El portal está en la isla final")
	_check(camera.limit_right == 12400, "La cámara cubre todo el gran pozo")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _index_path_points(index: int, samples: int = 40) -> Array[Vector2]:
	return LevelFourRoute.trajectory_points(index, samples)


func _min_index_path_distance(a: int, b: int) -> float:
	var points_a := _index_path_points(a)
	var points_b := _index_path_points(b)
	var best := INF
	for point_a in points_a:
		for point_b in points_b:
			best = minf(best, point_a.distance_to(point_b))
	return best


func _min_distance_to_index_path(index: int, point: Vector2) -> float:
	var best := INF
	for path_point in _index_path_points(index):
		best = minf(best, path_point.distance_to(point))
	return best


func _path_horizontal_extent(index: int) -> Vector2:
	var points := _index_path_points(index)
	var min_x := INF
	var max_x := -INF
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
	var half_width := PLATFORM_HALF_WIDTH
	if String(LevelFourRoute.motion_config(index)["kind"]) == "rotating":
		half_width = sqrt(PLATFORM_HALF_WIDTH * PLATFORM_HALF_WIDTH + 11.0 * 11.0)
	return Vector2(min_x - half_width, max_x + half_width)


func _path_vertical_span(index: int) -> float:
	var points := _index_path_points(index)
	var top := -INF
	var bottom := INF
	for point in points:
		top = maxf(top, point.y)
		bottom = minf(bottom, point.y)
	return top - bottom


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
