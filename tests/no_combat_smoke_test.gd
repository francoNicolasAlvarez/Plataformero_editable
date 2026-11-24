extends SceneTree
## Comprueba que el jugador ya no puede atacar ni hacer daño, y que los
## enemigos no sueltan recompensas de combate.
## Ejecutar con:
## godot --headless --path . --script res://tests/no_combat_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	var walker: WalkerEnemy = level.get_node("WalkerEnemy")
	walker.set_physics_process(false)

	await _wait_physics(20)

	_check(not InputMap.has_action("attack"), "No existe una acción de ataque")
	_check(player.get_node_or_null("AttackHitbox") == null and not player.has_method("_handle_attack"), "El jugador ya no lleva código ni nodos de ataque")
	_check(not InputMap.has_action("item_2") and not InputMap.has_action("item_1"), "No existen acciones de objetos utilizables")

	var health_before := walker.health.current_health
	var x_before := player.global_position.x
	player.global_position = walker.global_position + Vector2(-42.0, 0.0)
	Input.action_press("move_right")
	await _wait_physics(30)
	Input.action_release("move_right")

	_check(walker.health.current_health == health_before, "El contacto no daña al enemigo")
	_check(player.global_position.x > x_before, "El jugador se mueve sin atacar")

	walker.take_damage(9999)
	await _wait_physics(20)
	_check(get_nodes_in_group("range_orbs").is_empty(), "Los enemigos ya no sueltan orbes de rango")

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
