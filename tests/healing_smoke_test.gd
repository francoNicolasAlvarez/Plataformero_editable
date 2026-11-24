extends SceneTree
## Comprueba que la curación no se consume con la vida llena, restaura vida
## y respeta el máximo del jugador.
## Ejecutar con:
## godot --headless --path . --script res://tests/healing_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	var herbs := get_nodes_in_group("healing_pickups")

	await _wait_physics(20)

	_check(herbs.size() >= 2, "El nivel contiene varias curaciones")
	var first_herb: HealingHerb = herbs[0]
	player.global_position = first_herb.global_position
	await _wait_physics(8)
	_check(
		is_instance_valid(first_herb) and player.health.current_health == 3,
		"La curación no se gasta con los 3 golpes llenos"
	)

	player.global_position += Vector2(60.0, 0.0)
	await _wait_physics(4)
	player.take_damage(20)
	await _wait_physics(2)
	player.global_position = first_herb.global_position
	await _wait_physics(8)
	_check(player.health.current_health == 3, "La curación recupera el golpe perdido")
	_check(not is_instance_valid(first_herb), "La curación desaparece al usarse")

	var second_herb: HealingHerb = get_nodes_in_group("healing_pickups")[0]
	await _wait_physics(70)
	player.take_damage(20)
	await _wait_physics(2)
	player.global_position = second_herb.global_position
	await _wait_physics(8)
	_check(player.health.current_health == 3, "La segunda curación vuelve a llenar los 3 golpes")

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
