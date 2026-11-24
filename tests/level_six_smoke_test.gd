extends SceneTree
## Comprueba el nivel 6 "FORTALEZA" (2026-11-13): saltos largos que exigen
## doble salto, pinchos solo en los bordes de las plataformas, sierras
## patrullando, plataformas giratorias, un control y el portal final.
## Ejecutar con:
## godot --headless --path . --script res://tests/level_six_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_six.tscn")
const NEXT_SCENE := "res://scenes/levels/level_seven.tscn"

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

	_check(level.level_variant == 6, "El nivel 6 usa la variante FORTALEZA")
	_check(level.level_name == "NIVEL 2-1", "El nivel se identifica como NIVEL 2-1")
	_check(level.next_level_path == NEXT_SCENE, "El nivel 6 lleva al nivel 7")
	_check(level.time_limit == 70.0, "El nivel 6 tiene 70 segundos")
	_check(level.get_node_or_null("LevelSixGenerated") != null, "Se generó la fortaleza del nivel 6")
	_check(level.get_node("Platforms").get_child_count() == 0, "El nivel 6 limpia las plataformas base")
	_check(player.global_position.x <= 100.0, "El jugador empieza en el extremo izquierdo")

	var platforms := _collect_platforms(level.get_node("LevelSixGenerated"))
	var route: Array[Platform] = []
	var route_end_x := LevelSixLayout.ROUTE_START_X + float(LevelSixLayout.ROUTE_COUNT - 1) * LevelSixLayout.ROUTE_STEP
	var spiked := 0
	var rotating: Platform = null
	for platform in platforms:
		if (
			platform.position.x >= LevelSixLayout.ROUTE_START_X - 1.0
			and platform.position.x <= route_end_x + 1.0
		):
			route.append(platform)
		if platform.kind == Platform.Kind.SPIKED:
			spiked += 1
		if platform.kind == Platform.Kind.ROTATING and rotating == null:
			rotating = platform
	route.sort_custom(func(a: Platform, b: Platform) -> bool:
		return a.position.x < b.position.x
	)
	_check(
		route.size() == LevelSixLayout.ROUTE_COUNT,
		"La ruta del nivel 6 tiene %d plataformas" % LevelSixLayout.ROUTE_COUNT
	)
	_check(spiked >= 5, "El nivel 6 tiene varias plataformas con pinchos")
	_check(rotating != null, "El nivel 6 incluye plataformas giratorias")
	_check(PlatformSpacing.collect_violations(level).is_empty(), "Las plataformas respetan el espaciado mínimo")

	var min_gap := INF
	var max_gap := 0.0
	for index in range(route.size() - 1):
		var gap := route[index + 1].position.x - route[index].position.x - LevelSixLayout.PLATFORM_SIZE.x
		min_gap = minf(min_gap, gap)
		max_gap = maxf(max_gap, gap)
	_check(min_gap >= 450.0, "Los saltos son largos y exigen doble salto (hueco mínimo %.0f px)" % min_gap)
	_check(max_gap <= 520.0, "Los saltos siguen siendo posibles con doble salto (hueco máximo %.0f px)" % max_gap)

	var start_edge := LevelSixLayout.START_CENTER + 600.0
	var end_edge := LevelSixLayout.END_CENTER - 900.0
	var first := route[0]
	var last := route[route.size() - 1]
	_check(first.position.x - LevelSixLayout.PLATFORM_SIZE.x * 0.5 - start_edge <= 300.0, "La primera plataforma está al alcance del inicio")
	_check(end_edge - (last.position.x + LevelSixLayout.PLATFORM_SIZE.x * 0.5) <= 520.0, "La última plataforma está al alcance del final")

	for platform in route:
		if platform.kind != Platform.Kind.SPIKED:
			continue
		var left := platform.get_node_or_null("SpikeLeft") as Area2D
		var right := platform.get_node_or_null("SpikeRight") as Area2D
		_check(left != null and right != null, "La plataforma con pinchos tiene pinchos en ambos bordes")
		if left != null and right != null:
			_check(left.position.x < -60.0 and right.position.x > 60.0, "Los pinchos están en los bordes, no en el centro")
			_check(left.visible and right.visible, "Los pinchos de borde son visibles")

	var saws := get_nodes_in_group("saws")
	var expected_saws := LevelSixLayout.SAW_INDICES.size() + LevelSixLayout.AIR_SAW_INDICES.size()
	_check(saws.size() == expected_saws, "El nivel 6 tiene %d sierras entre suelo y aire" % expected_saws)
	var air_saws: Array[Node] = []
	var guided_saws := 0
	for saw in saws:
		var guide := saw.get_node_or_null("PathGuide") as Line2D
		if guide != null and guide.points.size() == 2:
			guided_saws += 1
		if float(saw.get("move_range")) >= LevelSixLayout.PLATFORM_SIZE.x - 1.0:
			air_saws.append(saw)
	_check(guided_saws == saws.size(), "Cada sierra muestra la guía de su trayecto")
	_check(
		air_saws.size() == LevelSixLayout.AIR_SAW_INDICES.size(),
		"Hay %d sierras suspendidas en el aire" % LevelSixLayout.AIR_SAW_INDICES.size()
	)
	if not air_saws.is_empty():
		var air_saw := air_saws[0] as Node2D
		var air_guide := air_saw.get_node("PathGuide") as Line2D
		_check(air_saw.global_position.y < 400.0, "La sierra suspendida está en el aire")
		_check(
			is_equal_approx(absf(air_guide.points[1].x - air_guide.points[0].x), LevelSixLayout.PLATFORM_SIZE.x * 2.0),
			"El trayecto de la sierra mide el doble que una plataforma"
		)
	var saw_start := Vector2.ZERO
	if saws.size() > 0:
		var saw := saws[0] as Node2D
		saw_start = saw.global_position
		await _wait_physics(35)
		_check(saw.global_position.distance_to(saw_start) > 2.0, "Las sierras patrullan sobre las plataformas")
		_check(saw.global_position.y < 550.0, "Las sierras quedan por encima de las plataformas")

	if rotating != null:
		var rotation_before := rotating.rotation
		await _wait_physics(25)
		_check(not is_equal_approx(rotating.rotation, rotation_before), "La plataforma giratoria oscila")
		_check(absf(rad_to_deg(rotating.rotation)) <= 30.01, "La plataforma no se inclina más de 30 grados")

	_check(get_nodes_in_group("checkpoints").size() == 1, "El nivel 6 tiene un único control")
	_check(get_nodes_in_group("healing_pickups").size() >= 2, "El nivel 6 incluye hierbas curativas")
	var sentry := level.get_node_or_null("LevelSixGenerated/SkySentry") as SkySentry
	_check(sentry != null, "El nivel 6 tiene un centinela superior")
	if sentry != null:
		_check(sentry.is_in_group("enemies"), "El centinela cuenta como enemigo")
		_check(is_equal_approx(sentry.shoot_interval, 4.0 / 0.75), "El centinela dispara cada 5,33 s (frecuencia a la mitad)")
		var center := camera.get_screen_center_position()
		var half_width := root.get_visible_rect().size.x * 0.5 / maxf(camera.zoom.x, 0.01)
		var expected_x := center.x + half_width - sentry.right_margin
		_check(
			absf(sentry.global_position.x - expected_x) < 2.0,
			"El centinela se mantiene en la esquina superior derecha"
		)
		_check(sentry.global_position.y < 120.0, "El centinela está en el borde superior")
	_check(level.get_node_or_null("LevelSixGenerated/GiantCreatureParallax/GiantCreature") != null, "El nivel 6 muestra una criatura gigante lejana")
	_check(get_nodes_in_group("coins").is_empty(), "El nivel 6 no tiene monedas")
	_check(portal.global_position.x > 17000.0, "El portal está en la isla final del nivel 6")
	_check(camera.limit_right == int(LevelSixLayout.LEVEL_WIDTH), "La cámara cubre todo el nivel 6")

	var fall_zone := level.get_node_or_null("LevelSixGenerated/FallZoneFortress") as Area2D
	_check(fall_zone != null, "El nivel 6 tiene zona de caida")
	if fall_zone != null:
		var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
		_check(
			fall_shape.size.x >= LevelSixLayout.LEVEL_WIDTH,
			"La zona de caida cubre todo el ancho del nivel 6"
		)

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
