extends SceneTree
## Comprueba que el enemigo patrullero se mueve, respeta su zona de patrulla
## y conserva el daño por contacto.
## Ejecutar con:
## godot --headless --path . --script res://tests/enemy_patrol_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var walker: WalkerEnemy = level.get_node("WalkerEnemy")
	var player: Player = level.get_node("Player")

	await _wait_physics(20)

	var start_x := walker.global_position.x
	await _wait_physics(36)
	var moved_x := walker.global_position.x
	_check(absf(moved_x - start_x) >= 15.0, "El enemigo patrullero se desplaza")
	_check(WalkerEnemy.MOVE_SPEED_SCALE >= 1.2, "Los walkers aplican el aumento de velocidad")
	_check(walker.is_on_floor(), "El enemigo patrullero se mantiene sobre el suelo")

	await _wait_physics(150)
	_check(
		absf(walker.global_position.x - start_x) <= walker.patrol_distance + 20.0,
		"El enemigo respeta su distancia máxima de patrulla"
	)

	_check(walker.health.max_health == 30, "El patrullero conserva la vida del enemigo base")
	_check(walker.damage_area.monitoring, "El área de daño por contacto está activa")

	player.global_position = walker.global_position + Vector2(float(walker._direction) * 45.0, 0.0)
	await _wait_physics(45)
	_check(player.health.current_health == 2, "El patrullero consume uno de los 3 golpes")

	# Contacto continuo: antes solo se aplicaba el primer body_entered y, si
	# el jugador seguía pegado al enemigo, no volvía a recibir daño.
	walker.patrol_speed = 0.0
	player.set_physics_process(false)
	player.global_position = walker.global_position
	player._invulnerability_left = 0.0
	await _wait_physics(2)
	player._invulnerability_left = 0.0
	await _wait_physics(2)
	player._invulnerability_left = 0.0
	await _wait_physics(2)
	_check(
		player.health.is_dead,
		"El contacto continuo vuelve a dañar al acabar la invulnerabilidad"
	)

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
