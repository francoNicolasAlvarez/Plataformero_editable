extends SceneTree
## Comprueba las trampas nuevas (2026-11-21): mina de proximidad, teletransporte,
## lanzador sin daño y rueda de cuchillas giratoria.
## Ejecutar con:
## godot --headless --path . --script res://tests/new_traps_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")
const MINE_SCENE := preload("res://scenes/world/proximity_mine.tscn")
const TELEPORT_SCENE := preload("res://scenes/world/teleport_trap.tscn")
const PAD_SCENE := preload("res://scenes/world/launch_pad.tscn")
const WHEEL_SCENE := preload("res://scenes/world/blade_wheel.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var player: Player = level.get_node("Player")
	await _wait_physics(10)
	var start := player.global_position
	var far := Vector2(start.x, start.y - 4000.0)

	# --- Mina de proximidad ---
	var mine: ProximityMine = MINE_SCENE.instantiate()
	level.add_child(mine)
	mine.global_position = far
	await _wait_physics(2)
	_check(mine.state == Hazard.State.IDLE, "La mina empieza armada y en reposo")
	player.set_physics_process(false)  # sin suelo, caería fuera del radio
	var lives := player.health.current_health
	player.global_position = far + Vector2(60.0, -10.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(4)
	_check(mine.state == Hazard.State.WARNING, "Acercarse activa la cuenta atrás de la mina")
	await _wait_physics(40)
	_check(mine.state == Hazard.State.WARNING, "A los ~0,7 s todavía no ha explotado")
	await _wait_physics(30)
	_check(mine.state == Hazard.State.ACTIVE or mine.state == Hazard.State.COOLDOWN, "Explota ~1 s después de acercarse")
	_check(player.health.current_health < lives, "La explosión daña a quien sigue dentro del radio")
	mine.reset()
	_check(mine.state == Hazard.State.IDLE, "reset() vuelve a armar la mina")
	# Huir a tiempo: salir del radio de explosión pero seguir en el de detección.
	mine.global_position = far
	player.health.reset()
	player.global_position = far + Vector2(60.0, -10.0)
	await _wait_physics(4)
	player.global_position = far + Vector2(110.0, -10.0)
	var safe_lives := player.health.current_health
	await _wait_physics(80)
	_check(player.health.current_health == safe_lives, "Si huyes del radio de explosión no recibes daño")
	player.health.reset()
	player.set_physics_process(true)

	# --- Teletransporte ---
	var tele: TeleportTrap = TELEPORT_SCENE.instantiate()
	level.add_child(tele)
	tele.global_position = far + Vector2(1000.0, 0.0)
	await _wait_physics(2)
	var before := player.health.current_health
	player.global_position = tele.global_position
	await _wait_physics(6)
	_check(player.global_position.distance_to(start) < 80.0, "La trampa teletransporta al inicio del nivel")
	_check(player.health.current_health == before, "El teletransporte no hace daño")
	tele.use_custom_target = true
	tele.custom_target = far + Vector2(500.0, 0.0)
	_check(tele.start_target() == tele.custom_target, "Se puede fijar un destino propio")

	# --- Lanzador ---
	var pad: LaunchPad = PAD_SCENE.instantiate()
	level.add_child(pad)
	pad.global_position = far + Vector2(2000.0, 0.0)
	await _wait_physics(2)
	var hp := player.health.current_health
	player.global_position = pad.global_position + Vector2(-20.0, 0.0)
	player.velocity = Vector2(200.0, 0.0)
	var launch := pad.launch_vector_for(player)
	_check(launch.x < 0.0 and launch.y < 0.0, "Yendo a la derecha, el lanzador manda hacia atrás (izquierda) y arriba")
	player.velocity = Vector2(-200.0, 0.0)
	_check(pad.launch_vector_for(player).x > 0.0, "Yendo a la izquierda, lo manda hacia la derecha")
	player.velocity = Vector2(200.0, 0.0)
	await _wait_physics(4)
	_check(player.velocity.x < -300.0, "El jugador sale despedido hacia atrás")
	_check(player.health.current_health == hp, "El lanzador no hace daño")

	# --- Rueda de cuchillas ---
	var wheel: BladeWheel = WHEEL_SCENE.instantiate()
	level.add_child(wheel)
	wheel.global_position = far + Vector2(3000.0, 0.0)
	await _wait_physics(2)
	_check(wheel.get_children().filter(func(c): return c is CollisionShape2D).size() == 5, "La rueda tiene 4 cuchillas y el eje con colisión")
	var angle0 := wheel.rotation
	await _wait_physics(10)
	_check(wheel.rotation > angle0, "Por defecto gira en sentido horario")
	wheel.clockwise = false
	var angle1 := wheel.rotation
	await _wait_physics(10)
	_check(wheel.rotation < angle1, "Con clockwise desactivado gira al revés")
	player.health.reset()
	player.global_position = wheel.global_position
	player.velocity = Vector2.ZERO
	var hp2 := player.health.current_health
	await _wait_physics(6)
	_check(player.health.current_health < hp2, "Tocar la rueda quita un golpe")

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
