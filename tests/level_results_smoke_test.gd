extends SceneTree
## Comprueba la pantalla de resultados por nivel de la fase 3 (2026-11-17).
## Ejecutar con:
## godot --headless --path . --script res://tests/level_results_smoke_test.gd

const RESULTS_SCENE := preload("res://scenes/ui/level_results.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveGame.record_level_result(3, 41.5, MedalRules.SILVER, 3)
	var results := RESULTS_SCENE.instantiate()
	root.add_child(results)
	await _wait_process(2)

	_check(results.get_node("Center/Panel/Margin/VBox/Title").text == "NIVEL 1-3 COMPLETADO", "El título usa el código del mundo y nivel")
	_check(results.get_node("Center/Panel/Margin/VBox/Subtitle").text.contains("NOCHE"), "El subtítulo muestra el nivel del registro")
	_check(results.get_node("Center/Panel/Margin/VBox/Stats/TimeLabel").text == "TIEMPO: 00:41.50", "Muestra el tiempo exacto")
	_check(results.get_node("Center/Panel/Margin/VBox/Stats/MedalLabel").text == "MEDALLA: PLATA", "Muestra la medalla conseguida")
	_check(results.get_node("Center/Panel/Margin/VBox/Stats/DeathsLabel").text == "MUERTES: 3", "Muestra las muertes del nivel")
	_check(results.get_node("Center/Panel/Margin/VBox/BestLabel").text.contains("00:41.50"), "Muestra la mejor marca guardada")
	_check(results.get_node("Center/Panel/Margin/VBox/Buttons/ContinueButton").text == "SIGUIENTE NIVEL", "Ofrece continuar cuando hay siguiente nivel")
	_check(results.get_node("Center/Panel/Margin/VBox/Buttons/RepeatButton") != null, "Ofrece repetir el nivel")
	_check(results.get_node("Center/Panel/Margin/VBox/Buttons/MenuButton") != null, "Ofrece volver al menú")
	results.queue_free()

	SaveGame.record_level_result(30, 68.2, MedalRules.BRONZE, 1)
	var final_results := RESULTS_SCENE.instantiate()
	root.add_child(final_results)
	await _wait_process(2)
	_check(final_results.get_node("Center/Panel/Margin/VBox/Title").text == "NIVEL 6-5 COMPLETADO", "El nivel 30 aparece como 6-5")
	_check(final_results.get_node("Center/Panel/Margin/VBox/Buttons/ContinueButton").text == "VER RESULTADO FINAL", "El último nivel lleva al resultado final")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _wait_process(frames: int) -> void:
	for _frame in frames:
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
