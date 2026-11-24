extends SceneTree
## Comprueba el nivel 21 "LABERINTO" (2026-11-18): estructura (sin pozos, sin
## voladores, pocos enemigos terrestres, cámara con seguimiento vertical,
## progreso por ruta) y, con un robot que sigue la ruta con la física real,
## que se puede llegar a la salida dentro del límite de tiempo. Ejecutar con:
## godot --headless --path . --script res://tests/maze_level_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_twentyone.tscn")
const MAX_FRAMES := 4100

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(20)
	var player: Player = level.get_node("Player")
	var camera := level.get_node("Camera") as HorizontalCamera

	_check(level.next_level_path == "res://scenes/levels/level_twentytwo.tscn", "El laberinto lleva al campanario (nivel 22)")
	_check(LevelRegistry.get_level(21).display_name == "LABERINTO", "Está registrado como LABERINTO")
	_check(camera.follow_y, "La cámara sigue también en vertical")
	_check(camera.limit_bottom > 1000 and camera.limit_right == int(LevelTwentyoneLayout.WIDTH), "La cámara tiene límites de edificio alto")
	_check(get_nodes_in_group("fall_zones").is_empty() and level.find_children("FallZone*", "Area2D", true, false).is_empty(), "No hay pozos mortales")
	_check(level.find_children("FlyingSpawner", "Node", true, false).is_empty(), "No hay generador de voladores")
	var enemies := get_nodes_in_group("enemies")
	var flying := 0
	for enemy in enemies:
		if enemy is FlyingEnemy:
			flying += 1
	_check(flying == 0, "No hay enemigos voladores")
	_check(enemies.size() >= 5 and enemies.size() <= 12, "Pocos enemigos terrestres (%d)" % enemies.size())
	_check(get_nodes_in_group("sky_sentries").is_empty() and get_nodes_in_group("rockfall_spawners").is_empty(), "Sin centinela ni rocas")
	_check(get_nodes_in_group("checkpoints").size() == 1, "Hay un control a mitad del recorrido")

	var route := LevelTwentyoneLayout.route()
	_check(route[0].distance_to(player.global_position) < 80.0, "El jugador empieza en el inicio de la ruta")
	var portal := level.get_node("ExitPortal") as Node2D
	_check(route[route.size() - 1].distance_to(portal.global_position) < 120.0, "La ruta acaba en el portal")
	_check(level._route_length > 12000.0, "La ruta es larga (%.0f px): lo difícil es recorrerla" % level._route_length)
	var up := 0
	var down := 0
	for i in range(1, route.size()):
		if route[i].y < route[i - 1].y - 1.0:
			up += 1
		elif route[i].y > route[i - 1].y + 1.0:
			down += 1
	_check(up >= 8 and down >= 4, "El camino sube y baja (%d subidas, %d bajadas)" % [up, down])
	var xs := {}
	for point in route:
		xs[snappedf(point.x, 10.0)] = true
	_check(level.route_progress(route[0]) < 0.01 and level.route_progress(route[route.size() - 1]) > 0.99, "El progreso por ruta va de 0 a 1")
	_check(level.route_progress(route[route.size() / 2]) > 0.3 and level.route_progress(route[route.size() / 2]) < 0.7, "A mitad de la ruta el progreso ronda el 50 %")

	# Holguras: el jugador (48 px) cabe bajo las repisas y los muros colgantes.
	var clearance_ok := true
	for node in level.find_children("MazeStep*", "Platform", true, false):
		var platform := node as Platform
		var underside := platform.global_position.y + platform.platform_size.y * 0.5
		var row := int(String(node.name).substr(8, 1))
		clearance_ok = clearance_ok and (LevelTwentyoneLayout.floor_top(row) - (platform.global_position.y - platform.platform_size.y * 0.5) - 24.0) >= 48.0 and underside > 0.0
	_check(clearance_ok, "Hay holgura para pasar bajo cada repisa")
	_check(LevelTwentyoneLayout.ROW_HEIGHT - LevelTwentyoneLayout.HANGING_SIZE.y >= 72.0, "Bajo los muros colgantes queda paso de sobra")
	_check(LevelTwentyoneLayout.HURDLE_SIZE.y <= player.stats.jump_height - 20.0, "Los muros bajos se pueden saltar")

	# Trampas nuevas (2026-11-23).
	_check(get_nodes_in_group("mines").size() == LevelTwentyoneLayout.MINES.size(), "Hay %d minas de proximidad" % LevelTwentyoneLayout.MINES.size())
	_check(level.find_children("MazeTeleport*", "Area2D", true, false).size() == LevelTwentyoneLayout.TELEPORTS.size(), "Hay %d trampas de teletransporte" % LevelTwentyoneLayout.TELEPORTS.size())
	var ledge_pads := LevelTwentyoneLayout.ledge_pad_positions()
	var pad_nodes := level.find_children("MazeHurdlePad*", "Area2D", true, false)
	var hurdles := level.find_children("MazeHurdle*", "Platform", true, false)
	_check(pad_nodes.size() == hurdles.size(), "Hay un lanzador por cada muro bajo (%d)" % hurdles.size())
	var every_hurdle_has_pad := true
	for hurdle in hurdles:
		var row := int(String(hurdle.name).substr(10, 1))
		var approach := -1.0 if row % 2 == 1 else 1.0
		var expected_x := (hurdle as Node2D).position.x - approach * 68.0
		var found := false
		for pad in pad_nodes:
			var pad_position := (pad as Node2D).position
			found = found or (absf(pad_position.x - expected_x) < 1.0 and absf(pad_position.y - (LevelTwentyoneLayout.floor_top(row) - 15.0)) < 1.0)
		every_hurdle_has_pad = every_hurdle_has_pad and found
	_check(every_hurdle_has_pad, "Cada lanzador está pegado a su muro bajo, por el lado de la aproximación")
	_check(level.find_children("MazeLedgePad*", "Area2D", true, false).size() == ledge_pads.size(), "Hay lanzadores sobre las repisas (%d)" % ledge_pads.size())
	var ledge_ok := true
	for i in ledge_pads.size():
		var ledge_pad := level.find_child("MazeLedgePad%d" % i, true, false) as Node2D
		ledge_ok = ledge_ok and ledge_pad != null and ledge_pad.position.distance_to(ledge_pads[i]) < 1.0
	_check(ledge_ok, "Los lanzadores de las repisas coinciden con el generador")
	var wheels := get_nodes_in_group("blade_wheels")
	_check(wheels.size() == LevelTwentyoneLayout.WHEELS.size(), "Hay %d ruedas de cuchillas" % LevelTwentyoneLayout.WHEELS.size())
	var clockwise_count := 0
	for wheel in wheels:
		clockwise_count += 1 if wheel.clockwise else 0
		_check(LevelTwentyoneLayout.ROW_HEIGHT - 140.0 - float(wheel.arm_length) >= 20.0, "La rueda en x=%d cabe bajo el techo" % int((wheel as Node2D).position.x))
	_check(clockwise_count > 0 and clockwise_count < wheels.size(), "Hay ruedas con giro horario y antihorario")

	# Robot: sigue la ruta con la física real (sin enemigos, para probar la geometría).
	for enemy in enemies:
		enemy.queue_free()
	for trap in get_nodes_in_group("traps"):
		trap.queue_free()
	await _wait_physics(2)
	var index := 1
	var frames := 0
	var stuck := 0
	var hold := 0
	var last_position := player.global_position
	while frames < MAX_FRAMES and not level._completed and not player.health.is_dead:
		var target: Vector2 = route[index]
		var delta_vector := target - player.global_position
		var is_drop_point := index + 1 < route.size() and absf(route[index + 1].x - target.x) < 1.0 and route[index + 1].y > target.y
		var reached := absf(delta_vector.x) < 24.0 and absf(delta_vector.y) < 44.0 and (player.is_on_floor() or is_drop_point)
		if reached and index < route.size() - 1:
			index += 1
			target = route[index]
			delta_vector = target - player.global_position
		_press("move_right", delta_vector.x > 14.0)
		_press("move_left", delta_vector.x < -14.0)
		var wants_up := delta_vector.y < -30.0 and (absf(delta_vector.x) < 150.0 or _edge_ahead(player, signf(delta_vector.x)))
		if player.is_on_floor() and hold <= 0 and (wants_up or player.is_on_wall()):
			hold = 26
		_press("jump", hold > 0)
		hold = maxi(0, hold - 1)
		await physics_frame
		frames += 1
		if player.global_position.distance_to(last_position) < 1.0:
			stuck += 1
		else:
			stuck = 0
			last_position = player.global_position
		if stuck > 240:
			break
	for action in ["move_right", "move_left", "jump"]:
		Input.action_release(action)
	_check(level._completed, "El robot llega a la salida en %.1f s (índice de ruta %d/%d, x=%.0f y=%.0f)" % [float(frames) / 60.0, index, route.size() - 1, player.global_position.x, player.global_position.y])

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _edge_ahead(player: Player, direction: float) -> bool:
	## Cierto si a 30 px en la dirección de avance ya no hay suelo bajo los pies.
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(direction * 30.0, 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 60.0), 1)
	return space.intersect_ray(query).is_empty()


func _press(action: String, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not pressed and Input.is_action_pressed(action):
		Input.action_release(action)


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
