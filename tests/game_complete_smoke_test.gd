extends SceneTree
## Comprueba la pantalla final del juego (2026-11-12): título, resumen de
## tiempo y muertes, botones y formato del cronómetro.
## Ejecutar con:
## godot --headless --path . --script res://tests/game_complete_smoke_test.gd

const COMPLETE_SCENE := preload("res://scenes/ui/game_complete.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveGame.ensure_loaded()
	SaveGame.total_time = 125.0
	SaveGame.deaths = 4

	var screen := COMPLETE_SCENE.instantiate()
	root.add_child(screen)
	await _wait_process(2)

	var title: Label = screen.get_node("Center/Panel/Margin/VBox/Title")
	var stats: Label = screen.get_node("Center/Panel/Margin/VBox/Stats")
	var replay: Button = screen.get_node("Center/Panel/Margin/VBox/Buttons/ReplayButton")
	var menu: Button = screen.get_node("Center/Panel/Margin/VBox/Buttons/MenuButton")
	var quit: Button = screen.get_node("Center/Panel/Margin/VBox/Buttons/QuitButton")

	_check(ResourceLoader.exists("res://scenes/ui/game_complete.tscn"), "La pantalla final existe como escena")
	_check(title.text.contains("COMPLETADO"), "La pantalla final felicita al jugador")
	_check(stats.text.contains("02:05"), "La pantalla final muestra el tiempo total formateado")
	_check(stats.text.contains("4"), "La pantalla final muestra el número de muertes")
	_check(replay.text.contains("JUGAR"), "Hay un botón para empezar otra partida")
	_check(menu.text.contains("MEN"), "Hay un botón para volver al menú")
	_check(quit.text.contains("SALIR"), "Hay un botón para salir del juego")
	_check(SaveGame.format_time(65.0) == "01:05", "El formato de tiempo usa minutos y segundos")

	SaveGame.completed = true
	SaveGame.level = 3
	SaveGame.begin_new_run()
	_check(not SaveGame.completed, "Empezar una partida nueva limpia el estado completado")
	_check(SaveGame.level == SaveGame.FIRST_LEVEL, "La partida nueva vuelve al nivel 1")
	_check(SaveGame.deaths == 0 and is_zero_approx(SaveGame.total_time), "La partida nueva reinicia estadísticas")

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
