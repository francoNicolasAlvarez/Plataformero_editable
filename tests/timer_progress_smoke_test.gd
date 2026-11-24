extends SceneTree
## Comprueba la cuenta regresiva y la barra de progreso hacia el portal.
## Ejecutar con:
## godot --headless --path . --script res://tests/timer_progress_smoke_test.gd

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
	var timer_label: Label = level.get_node("HUD/TimerLabel")
	var medal_label: Label = level.get_node("HUD/MedalLabel")
	var progress: ProgressBar = level.get_node("HUD/LevelProgress")
	var progress_label: Label = level.get_node("HUD/LevelProgress/ProgressLabel")
	var game_over: Label = level.get_node("HUD/GameOver")

	await _wait_process(5)

	_check(level.time_limit == 70.0, "El nivel define un límite de tiempo")
	_check(timer_label.text.begins_with("TIEMPO:"), "El HUD muestra la cuenta regresiva")
	_check(
		medal_label.text.contains("ORO") and medal_label.text.contains("00:00"),
		"El HUD muestra la medalla proyectada y el tiempo exacto"
	)
	_check(is_equal_approx(progress.value, 0.0), "La barra de progreso empieza vacía")
	_check(progress_label.text.begins_with("PROGRESO DE NIVEL"), "El marcador de porcentaje es visible con borde y letras negras")
	_check(not progress.show_percentage, "El porcentaje interno no se superpone al marcador")
	var banner: Label = level.get_node_or_null("HUD/LevelBanner")
	_check(
		banner != null and banner.text.begins_with("NIVEL 1"),
		"El nivel muestra su cartel de presentación al empezar"
	)

	player.set_physics_process(false)
	player.global_position.x = (player.global_position.x + portal.global_position.x) * 0.5
	await _wait_process(3)
	_check(progress.value > 25.0 and progress.value < 75.0, "La barra avanza al recorrer la mitad del nivel")
	_check(progress_label.text.contains("%"), "El marcador actualiza el porcentaje del recorrido")

	player.global_position.x = portal.global_position.x - 100.0
	await _wait_process(3)
	_check(progress.value > 90.0, "La barra casi se llena al llegar al final")

	level._process(999.0)
	await _wait_process(2)
	_check(player.health.is_dead, "El jugador muere cuando la cuenta regresiva llega a cero")
	_check(game_over.visible, "La pantalla de muerte aparece al agotarse el tiempo")
	_check(game_over.text.contains("TIEMPO AGOTADO"), "El aviso distingue el tiempo agotado de una muerte normal")
	_check(game_over.text.contains("nivel 1"), "Al agotarse el tiempo la partida vuelve al nivel 1")

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
