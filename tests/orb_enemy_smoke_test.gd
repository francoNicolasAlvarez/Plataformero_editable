extends SceneTree
## Comprueba el orbe perseguidor (2026-11-17): permanece suspendido, persigue
## en línea recta con aceleración progresiva al entrar el jugador en su radio,
## se detiene unos instantes al chocar con una plataforma y se reactiva; la
## variante vertical solo se mueve en vertical. Ejecutar con:
## godot --headless --path . --script res://tests/orb_enemy_smoke_test.gd

const ORB_SCENE := preload("res://scenes/enemies/orb_enemy.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _make_target(world: Node2D, position: Vector2) -> Node2D:
	# Un nodo en el grupo "player" basta como objetivo del orbe.
	var target := Node2D.new()
	target.add_to_group("player")
	target.position = position
	world.add_child(target)
	return target


func _make_wall(world: Node2D, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)
	body.position = center
	world.add_child(body)


func _run() -> void:
	# --- Suspendido y persecución con aceleración.
	var world := Node2D.new()
	root.add_child(world)
	var target := _make_target(world, Vector2(1200.0, 300.0))
	var orb: OrbEnemy = ORB_SCENE.instantiate()
	orb.position = Vector2(300.0, 300.0)
	world.add_child(orb)
	await _wait_physics(60)
	_check(orb.is_in_group("enemies"), "El orbe es un enemigo")
	_check(orb.state == OrbEnemy.State.HOVER and orb.global_position.is_equal_approx(Vector2(300.0, 300.0)), "Con el jugador lejos permanece suspendido sin caer")

	target.global_position = Vector2(560.0, 300.0)
	await _wait_physics(6)
	_check(orb.state == OrbEnemy.State.CHASE, "Al entrar en el radio de detección empieza a perseguir")
	var early_speed := orb.speed
	var early_distance := orb.global_position.distance_to(target.global_position)
	await _wait_physics(40)
	_check(orb.speed > early_speed + 50.0, "Acelera progresivamente (%.0f -> %.0f px/s)" % [early_speed, orb.speed])
	_check(orb.speed <= orb.max_speed, "No supera su velocidad máxima")
	_check(orb.global_position.distance_to(target.global_position) < early_distance, "Se acerca al jugador")
	_check(absf(orb.global_position.y - 300.0) < 1.0, "Sigue una trayectoria directa hacia el jugador")

	# Giro limitado: si el jugador pasa al lado opuesto, el orbe conserva inercia.
	var heading_before: Vector2 = orb._heading
	target.global_position = orb.global_position - heading_before * 300.0
	await _wait_physics(6)
	_check(orb._heading.dot(heading_before) > 0.95, "Con giro limitado no da la vuelta al instante (dot %.2f)" % orb._heading.dot(heading_before))
	_check(orb.velocity.dot(heading_before) > 0.0, "Sigue avanzando por inercia antes de girar")
	await _wait_physics(120)
	_check(orb._heading.dot((target.global_position - orb.global_position).normalized()) > 0.9, "Con el tiempo termina girando hacia el jugador")

	# Si el jugador se aleja del todo, vuelve a quedarse suspendido.
	target.global_position = Vector2(5000.0, 300.0)
	await _wait_physics(5)
	_check(orb.state == OrbEnemy.State.HOVER, "Si el jugador se aleja demasiado vuelve a quedarse suspendido")
	world.queue_free()
	await process_frame

	# --- Choque con una plataforma: se detiene y se reactiva.
	world = Node2D.new()
	root.add_child(world)
	_make_wall(world, Vector2(500.0, 300.0), Vector2(30.0, 400.0))
	target = _make_target(world, Vector2(620.0, 300.0))
	orb = ORB_SCENE.instantiate()
	orb.position = Vector2(300.0, 300.0)
	world.add_child(orb)
	var stunned_frames := 0
	var reactivated := false
	var was_stunned := false
	for _frame in 300:
		await physics_frame
		if orb.state == OrbEnemy.State.STUNNED:
			stunned_frames += 1
			was_stunned = true
			if orb.velocity.length() > 0.01:
				_check(false, "Aturdido debe estar parado")
		elif was_stunned and orb.state == OrbEnemy.State.CHASE:
			reactivated = true
			break
	_check(was_stunned, "Al chocar con una plataforma se detiene")
	_check(stunned_frames >= 40 and stunned_frames <= 56, "La pausa dura unos %.1f s (%d frames)" % [orb.stun_time, stunned_frames])
	_check(reactivated, "Después vuelve a activarse")
	_check(orb.speed < orb.max_speed * 0.5, "Tras reactivarse vuelve a empezar despacio")
	world.queue_free()
	await process_frame

	# --- Variante vertical: solo se mueve en vertical.
	world = Node2D.new()
	root.add_child(world)
	target = _make_target(world, Vector2(330.0, 480.0))
	var vertical: OrbEnemy = ORB_SCENE.instantiate()
	vertical.axis = OrbEnemy.Axis.VERTICAL
	vertical.position = Vector2(300.0, 200.0)
	world.add_child(vertical)
	var min_y := 9999.0
	var max_y := -9999.0
	for _frame in 300:
		await physics_frame
		min_y = minf(min_y, vertical.global_position.y)
		max_y = maxf(max_y, vertical.global_position.y)
	_check(max_y - min_y > 200.0, "El orbe vertical sube y baja sin parar (%.0f px de recorrido)" % (max_y - min_y))
	_check(min_y >= 200.0 - vertical.vertical_range - 8.0 and max_y <= 200.0 + vertical.vertical_range + 8.0, "El recorrido se limita a su rango")
	_check(is_equal_approx(vertical.global_position.x, 300.0), "El orbe vertical no se mueve en horizontal")
	target.global_position = Vector2(1500.0, 480.0)
	var before_y := vertical.global_position.y
	await _wait_physics(20)
	_check(not is_equal_approx(vertical.global_position.y, before_y), "El orbe vertical sigue moviéndose aunque el jugador se aleje")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


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
