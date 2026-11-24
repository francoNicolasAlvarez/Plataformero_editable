extends SceneTree
## Prueba automática del jugador sin combate: movimiento, salto, cámara e
## inventario pasivo. Ejecutar con:
## godot --headless --path . --script res://tests/player_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	var camera: Camera2D = level.get_node("Camera")
	var progress: ProgressBar = level.get_node("HUD/LevelProgress")

	await _wait_physics(35)

	_check(InputMap.has_action("move_left"), "Existe la acción move_left")
	_check(InputMap.has_action("move_right"), "Existe la acción move_right")
	_check(InputMap.has_action("move_down"), "Existe la acción move_down")
	_check(InputMap.has_action("jump"), "Existe la acción jump")
	_check(InputMap.has_action("dash") and not InputMap.has_action("run"), "Existe la acción dash (Ctrl) y ya no run")
	_check(not InputMap.has_action("item_1") and not InputMap.has_action("inventory"), "No existen acciones de objetos ni inventario")
	_check(not InputMap.has_action("attack"), "La acción de ataque fue eliminada")
	_check(not InputMap.has_action("item_2"), "No existe el espacio rápido 2")

	_check(player.is_on_floor(), "El personaje cae y detecta el suelo")
	_check(player.visual.animation == &"idle", "Animación idle en reposo")
	_check(player.stats.max_jumps == 1, "El salto base es único")
	_check(not "double_jumps" in player, "El doble salto ya no depende de cargas")
	_check(is_equal_approx(player.stats.max_speed, 266.0), "La velocidad base aumentó un 40%")
	_check(
		is_equal_approx(player.stats.run_speed, player.stats.max_speed * 2.0),
		"La carrera mueve al personaje un 100% más rápido"
	)
	_check(camera.zoom.x < 0.8, "La cámara se aleja para mostrar mucho más escenario")
	_check(progress.max_value == 100.0, "El HUD incluye una barra de progreso hacia la meta")

	var spawn_y := player.global_position.y
	var spawn_camera_x := camera.global_position.x
	Input.action_press("jump")
	await _wait_physics(6)
	_check(player.velocity.y < 0.0, "El salto aplica velocidad vertical")
	_check(player.global_position.y < spawn_y, "El personaje asciende al saltar")
	_check(not player.is_on_floor(), "El personaje deja el suelo al saltar")

	await _wait_physics(28)
	Input.action_release("jump")
	var fall_velocity_before := player.velocity.y
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	_check(
		player.velocity.y < fall_velocity_before - 100.0,
		"El doble salto está disponible siempre, sin objetos"
	)

	var after_double_jump := player.velocity.y
	await _wait_physics(2)
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	_check(
		player.velocity.y >= after_double_jump - 1.0,
		"Solo hay un salto aéreo por salto desde el suelo"
	)

	Input.action_press("move_down")
	await _wait_physics(3)
	var fast_fall_velocity := player.velocity.y
	Input.action_release("move_down")
	_check(
		fast_fall_velocity >= player.stats.fast_fall_speed - 1.0,
		"Abajo/S provoca la caída rápida al instante"
	)

	await _wait_until_floor(player, 100)
	_check(player.is_on_floor(), "El personaje vuelve a aterrizar")

	Input.action_press("move_right")
	var start_x := player.global_position.x
	await _wait_physics(60)
	_check(player.global_position.x > start_x + 80.0, "El personaje se desplaza a la derecha")
	_check(player.velocity.x > player.stats.max_speed + 20.0, "Se corre por defecto, sin pulsar nada más")
	_check(player.visual.animation == &"run", "Se reproduce la animación de carrera")
	_check(not player.visual.flip_h, "El personaje mira a la derecha")
	_check(camera.global_position.x > spawn_camera_x, "La cámara sigue al personaje en horizontal")
	_check(progress.value > 0.0, "La barra de progreso avanza al acercarse a la meta")

	Input.action_release("move_right")
	await _wait_physics(30)

	# Impulso (Ctrl): en el suelo y en el aire (sin gastar el doble salto).
	Input.action_press("move_right")
	await _wait_physics(5)
	Input.action_press("dash")
	await _wait_physics(3)
	Input.action_release("dash")
	_check(player.is_dashing() and player.velocity.x >= player.stats.dash_speed - 1.0, "Ctrl lanza un impulso rápido hacia delante")
	_check(not get_nodes_in_group("dash_afterimages").is_empty(), "El impulso deja una estela de imágenes")
	await _wait_physics(30)
	_check(not player.is_dashing(), "El impulso dura un instante")
	Input.action_release("move_right")
	await _wait_physics(40)
	# Terreno abierto y jugador activo (el portal pudo congelarlo).
	player.set_physics_process(true)
	player.global_position = Vector2(300.0, 600.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(30)
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	await _wait_physics(10)
	Input.action_press("move_right")
	Input.action_press("dash")
	await _wait_physics(3)
	Input.action_release("dash")
	_check(player.is_dashing() and absf(player.velocity.y) < 1.0, "En el aire el impulso es horizontal")
	await _wait_physics(30)
	var vy_after_dash := player.velocity.y
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	_check(player.velocity.y < vy_after_dash - 1.0, "El impulso aéreo no consume el doble salto")
	Input.action_release("move_right")
	await _wait_until_floor(player, 200)
	await _wait_physics(30)

	# El impulso (triple de alcance) puede haber llegado al portal, que congela
	# al jugador: se le devuelve a terreno abierto y se reactiva.
	player.set_physics_process(true)
	player._dash_time_left = 0.0
	player.global_position = Vector2(300.0, 600.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(20)
	Input.action_press("move_left")
	await _wait_physics(6)
	Input.action_release("move_left")
	_check(player.visual.flip_h, "El personaje mira a la izquierda al moverse hacia atrás")

	await _wait_physics(20)
	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _wait_until_floor(player: Player, max_frames: int) -> void:
	for _frame in max_frames:
		if player.is_on_floor():
			return
		await physics_frame


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
