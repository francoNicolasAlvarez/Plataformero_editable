extends SceneTree
## Comprueba que el portal está siempre disponible, guarda el nivel alcanzado
## y detiene al jugador al completar el nivel.
## Ejecutar con:
## godot --headless --path . --script res://tests/exit_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	var portal: ExitPortal = level.get_node("ExitPortal")
	var hint: Label = level.get_node("HUD/PortalHint")
	var completed: Label = level.get_node("HUD/Completed")

	await _wait_physics(20)

	_check(not completed.visible, "El mensaje de nivel completado empieza oculto")
	_check(not hint.visible, "No hay aviso de portal bloqueado")
	_check(portal.monitoring, "El portal está activo desde el inicio")

	var spread_total := 0
	for enemy in get_nodes_in_group("enemies"):
		if enemy is SpreadEnemy:
			spread_total += 1
	_check(spread_total >= 5, "El enemigo ráfaga (antiguo jefe) aparece repartido por el nivel 1")

	var coin_free := get_nodes_in_group("coins").is_empty()
	_check(coin_free, "El nivel 1 ya no contiene monedas")

	player.global_position = portal.global_position
	await _wait_physics(12)

	_check(completed.visible, "Al tocar el portal aparece el mensaje de nivel completado")
	_check(completed.text.begins_with("NIVEL 1-1 COMPLETADO"), "El mensaje indica el nivel completado")
	_check(completed.text.contains("MEDALLA ORO"), "El resumen muestra la medalla conseguida")
	_check(not completed.text.contains("Recursos"), "El resumen ya no cuenta recursos")
	_check(not player.is_physics_processing(), "El jugador deja de moverse al completar el nivel")
	_check(not portal.monitoring, "El portal se desactiva después de usarse")
	_check(SaveGame.level == 2, "Completar el nivel guarda el siguiente como continuación")
	_check(SaveGame.get_medal(1) == MedalRules.GOLD, "El resultado guarda la medalla de oro")
	_check(SaveGame.get_best_time(1) > 0.0, "El resultado guarda el mejor tiempo")
	_check(SaveGame.is_level_completed(1), "El resultado marca el nivel como completado")

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
