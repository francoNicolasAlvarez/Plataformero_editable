extends SceneTree
## Comprueba el viento (2026-11-17): WindField define tramos con su dirección,
## sopla a ráfagas (40-100 %), empuja al jugador (más en el aire que en el
## suelo, sin acumular velocidad) y no actúa fuera de los tramos ni con el
## jugador muerto. Ejecutar con:
## godot --headless --path . --script res://tests/wind_smoke_test.gd

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _make_world() -> Node2D:
	var world := Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20000.0, 100.0)
	shape.shape = rectangle
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 690.0)
	world.add_child(floor_body)
	return world


func _make_field(world: Node2D, from_x: float, to_x: float, speed: float) -> WindField:
	var field := WindField.new()
	field.show_effects = false
	var segments: Array[Dictionary] = []
	segments.append({"from": from_x, "to": to_x, "speed": speed})
	field.segments = segments
	world.add_child(field)
	return field


func _run() -> void:
	var world := _make_world()
	var field := _make_field(world, -1000.0, 1000.0, 100.0)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(0.0, 616.0)
	world.add_child(player)
	await _wait_physics(30)

	_check(field.speed_at(0.0) > 0.0 and field.speed_at(0.0) <= 100.0, "Dentro del tramo sopla en su dirección (%.0f px/s)" % field.speed_at(0.0))
	_check(is_zero_approx(field.speed_at(5000.0)), "Fuera de los tramos no hay viento")
	var min_gust := 1.0
	var max_gust := 0.0
	for _frame in 480:
		await physics_frame
		min_gust = minf(min_gust, field.gust_factor())
		max_gust = maxf(max_gust, field.gust_factor())
	_check(min_gust >= field.gust_min - 0.001 and min_gust < 0.5, "Las ráfagas bajan hasta el %.0f %%" % (min_gust * 100.0))
	_check(max_gust > 0.95 and max_gust <= 1.0, "Las ráfagas suben hasta el 100 %")
	_check(is_equal_approx(player.wind_speed, field.current_speed), "El campo escribe la velocidad del viento en el jugador")

	# En el suelo, sin teclas: empuja poco y sin acumular velocidad.
	player.global_position = Vector2(0.0, 616.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(5)
	var start_x := player.global_position.x
	await _wait_physics(60)
	var ground_drift := player.global_position.x - start_x
	_check(ground_drift > 8.0, "En el suelo el viento empuja al jugador (%.0f px en 1 s)" % ground_drift)
	_check(absf(player.velocity.x) < 120.0, "La velocidad del viento no se acumula en el jugador")

	# En el aire empuja más que en el suelo.
	player.global_position = Vector2(0.0, 100.0)
	player.velocity = Vector2.ZERO
	var air_start := player.global_position.x
	await _wait_physics(20)
	var air_drift := player.global_position.x - air_start
	_check(air_drift > 10.0, "En el aire el viento empuja al jugador (%.0f px en 0,33 s)" % air_drift)
	_check(Player.WIND_GROUND_FACTOR < 1.0, "En el suelo el viento pesa menos que en el aire")

	# Viento en contra (signo negativo).
	world.queue_free()
	await process_frame
	world = _make_world()
	field = _make_field(world, -1000.0, 1000.0, -100.0)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(0.0, 100.0)
	world.add_child(player)
	await _wait_physics(2)
	var back_start := player.global_position.x
	await _wait_physics(20)
	_check(player.global_position.x < back_start - 10.0, "Un viento negativo empuja hacia la izquierda")

	# Sin viento fuera del tramo y con el jugador muerto.
	player.global_position = Vector2(5000.0, 616.0)
	await _wait_physics(3)
	_check(is_zero_approx(player.wind_speed), "Fuera del tramo el jugador no recibe viento")
	player.global_position = Vector2(0.0, 616.0)
	player.health.take_damage(9999)
	await _wait_physics(3)
	_check(is_zero_approx(player.wind_speed), "Con el jugador muerto no hay viento")

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
