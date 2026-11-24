extends SceneTree
## Comprueba el salto variable, el doble salto permanente y la caída rápida.
## Ejecutar con:
## godot --headless --path . --script res://tests/jump_control_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	await _wait_physics(40)

	_check(player.is_on_floor(), "El jugador comienza sobre el suelo")
	_check(player.stats.max_jumps == 1, "El salto base es único")
	_check(not "double_jumps" in player, "El doble salto es permanente, sin cargas")
	_check(player.stats.jump_hold_time > 0.0, "El salto tiene una ventana de carga")
	_check(player.stats.jump_hold_acceleration > 0.0, "Mantener el botón impulsa el ascenso")

	# Salto corto: soltar enseguida debe recortar la altura.
	var short_ground_y := player.global_position.y
	Input.action_press("jump")
	await _wait_physics(1)
	Input.action_release("jump")
	var short_peak_y := short_ground_y
	for _frame in 50:
		await physics_frame
		short_peak_y = minf(short_peak_y, player.global_position.y)
	var short_height := short_ground_y - short_peak_y
	await _wait_until_floor(player, 90)

	# Salto mantenido: la altura extra debe acercarse al 25% configurado.
	var long_ground_y := player.global_position.y
	Input.action_press("jump")
	var long_peak_y := long_ground_y
	for _frame in 45:
		await physics_frame
		long_peak_y = minf(long_peak_y, player.global_position.y)
	Input.action_release("jump")
	var long_height := long_ground_y - long_peak_y
	await _wait_until_floor(player, 100)

	_check(long_height > short_height * 1.25, "Mantener el botón produce un salto claramente más alto")
	_check(
		long_height >= player.stats.jump_height * 1.12,
		"El salto mantenido aprovecha el impulso adicional"
	)
	_check(
		long_height <= player.stats.jump_height * 1.35,
		"La altura extra no supera el 25% permitido"
	)

	# El doble salto es permanente: un toque en el aire siempre impulsa.
	Input.action_press("jump")
	await _wait_physics(1)
	Input.action_release("jump")
	await _wait_physics(18)
	var air_velocity_before := player.velocity.y
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	_check(
		player.velocity.y < air_velocity_before - 100.0,
		"El doble salto está disponible sin recoger objetos"
	)

	var after_double_jump := player.velocity.y
	await _wait_physics(2)
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	_check(
		player.velocity.y >= after_double_jump - 1.0,
		"No se puede encadenar un tercer salto en el aire"
	)

	# Caída rápida: Abajo/S hunde al jugador al instante.
	Input.action_press("move_down")
	await _wait_physics(3)
	_check(
		player.velocity.y >= player.stats.fast_fall_speed - 1.0,
		"Abajo/S provoca la caída rápida al instante"
	)
	Input.action_release("move_down")
	await _wait_until_floor(player, 100)

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
