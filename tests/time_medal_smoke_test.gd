extends SceneTree
## Comprueba la fase contrarreloj (2026-11-17): medallas por tiempo real,
## cronómetro que sigue corriendo durante la muerte y registros por nivel.
## Ejecutar con:
## godot --headless --path . --script res://tests/time_medal_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(MedalRules.for_time(20.0, 35.0, 50.0, 70.0) == MedalRules.GOLD, "Menos de 35 s da oro")
	_check(MedalRules.for_time(40.0, 35.0, 50.0, 70.0) == MedalRules.SILVER, "Entre 35 y 50 s da plata")
	_check(MedalRules.for_time(60.0, 35.0, 50.0, 70.0) == MedalRules.BRONZE, "Entre 50 y 70 s da bronce")
	_check(MedalRules.is_better(MedalRules.GOLD, MedalRules.SILVER), "El oro supera a la plata")
	var short_route := MedalRules.thresholds_for_route(8000.0, 532.0, 70.0)
	var long_route := MedalRules.thresholds_for_route(20000.0, 532.0, 70.0)
	_check(short_route["gold"] < long_route["gold"], "Un recorrido más largo tiene un oro más holgado")
	_check(long_route["gold"] < long_route["silver"] and long_route["silver"] < long_route["bronze"], "Los umbrales largos están ordenados")
	_check(short_route["bronze"] == 70.0, "El bronce es el límite del nivel")

	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var player: Player = level.get_node("Player")
	var medal_label: Label = level.get_node("HUD/MedalLabel")

	await _wait_process(4)

	_check(level._timer.limit == 70.0, "El cronómetro usa el límite del nivel")
	_check(medal_label.text.contains("ORO"), "La medalla proyectada empieza en oro")

	level._timer.set_elapsed(60.0)
	await _wait_process(2)
	_check(medal_label.text.contains("PLATA"), "La medalla proyectada cambia con el tiempo real")

	var remaining_before_death: float = level._timer.remaining
	player.take_damage(9999)
	await _wait_process(8)
	_check(player.health.is_dead, "El jugador muere con daño letal")
	_check(
		level._timer.remaining < remaining_before_death,
		"El reloj sigue corriendo mientras el jugador está muerto"
	)

	SaveGame.record_level_result(1, 42.0, MedalRules.SILVER, 2)
	_check(is_equal_approx(SaveGame.get_best_time(1), 42.0), "SaveGame guarda el mejor tiempo")
	_check(SaveGame.get_medal(1) == MedalRules.SILVER, "SaveGame guarda la mejor medalla")
	_check(SaveGame.is_level_completed(1), "SaveGame marca el nivel completado")
	_check(SaveGame.get_level_deaths(1) == 2, "SaveGame guarda las muertes del nivel")
	_check(
		SaveGame.format_time_precise(42.37) == "00:42.37",
		"El formato preciso muestra centésimas para medallas"
	)

	SaveGame.record_level_result(1, 55.0, MedalRules.BRONZE, 1)
	_check(is_equal_approx(SaveGame.get_best_time(1), 42.0), "Un tiempo peor no reemplaza al mejor")
	_check(SaveGame.get_medal(1) == MedalRules.SILVER, "Una medalla peor no reemplaza a la mejor")

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
