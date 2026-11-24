extends SceneTree
## Comprueba el desbloqueo por mundos (2026-11-17): el mundo siguiente solo se
## abre al completar todos los niveles del anterior seguidos en una misma
## pasada; practicar niveles sueltos no desbloquea nada. Ejecutar con:
## godot --headless --path . --script res://tests/world_unlock_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _reset() -> void:
	SaveGame.cleared_worlds.clear()
	SaveGame.world_run = 0
	SaveGame.world_run_progress = 0
	SaveGame.last_world_cleared = 0


func _finish(level_id: int) -> void:
	SaveGame.record_level_result(level_id, 30.0, MedalRules.GOLD, 0)


func _run() -> void:
	_reset()
	_check(SaveGame.is_world_unlocked(1), "El mundo 1 siempre está abierto")
	_check(not SaveGame.is_world_unlocked(2), "El mundo 2 empieza bloqueado")
	_check(SaveGame.is_level_unlocked(5) and not SaveGame.is_level_unlocked(6), "El nivel 6 (mundo 2) está bloqueado")
	_check(SaveGame.unlock_hint(2).contains("seguidos"), "El aviso explica la pasada seguida")

	# Práctica: niveles sueltos no desbloquean.
	SaveGame.start_at_level(3)
	_check(SaveGame.world_run == 0, "Empezar en un nivel intermedio es práctica, no pasada")
	for id in [3, 4, 5]:
		_finish(id)
	_check(not SaveGame.is_world_cleared(1), "Completar niveles sueltos no supera el mundo")
	_check(not SaveGame.is_world_unlocked(2), "El mundo 2 sigue bloqueado tras practicar")

	# Pasada incompleta.
	SaveGame.start_at_level(1)
	_check(SaveGame.world_run == 1 and SaveGame.world_run_progress == 0, "Empezar en el primer nivel inicia la pasada del mundo")
	for id in [1, 2, 3, 4]:
		_finish(id)
	_check(SaveGame.world_run_progress == 4 and not SaveGame.is_world_cleared(1), "Cuatro de cinco niveles no bastan")
	SaveGame.set_level(5)
	_check(SaveGame.world_run == 1 and SaveGame.world_run_progress == 4, "Entrar al siguiente nivel conserva la pasada")

	# Perder la pasada: reinicio desde el nivel 1 (sin vidas o sin tiempo).
	SaveGame.start_at_level(SaveGame.FIRST_LEVEL)
	_check(SaveGame.world_run_progress == 0, "Reiniciar desde el nivel 1 reinicia el progreso de la pasada")

	# Fuera de orden.
	_finish(1)
	_finish(3)
	_check(SaveGame.world_run == 0 and not SaveGame.is_world_cleared(1), "Saltarse el orden invalida la pasada")

	# Pasada completa del mundo 1.
	SaveGame.start_at_level(1)
	for id in [1, 2, 3, 4]:
		_finish(id)
	_check(SaveGame.last_world_cleared == 0, "Aún no se ha superado el mundo a falta de un nivel")
	_finish(5)
	_check(SaveGame.is_world_cleared(1) and SaveGame.last_world_cleared == 1, "Los cinco niveles seguidos superan el mundo 1")
	_check(SaveGame.is_world_unlocked(2) and SaveGame.is_level_unlocked(6), "El mundo 2 se desbloquea")
	_check(not SaveGame.is_world_unlocked(3), "El mundo 3 sigue bloqueado")

	# Cadena hacia el mundo 2: una nueva pasada empieza en su primer nivel.
	SaveGame.set_level(6)
	_check(SaveGame.world_run == 2 and SaveGame.world_run_progress == 0, "Entrar al primer nivel del mundo 2 inicia su pasada")
	for id in [6, 7, 8, 9]:
		_finish(id)
	_check(not SaveGame.is_world_cleared(2), "El mundo 2 sigue pendiente a falta de un nivel")
	_finish(10)
	_check(SaveGame.is_world_cleared(2) and SaveGame.is_world_unlocked(3), "Superar todos los niveles creados del mundo 2 abre el 3")

	# Pantalla de resultados: en práctica con el mundo siguiente bloqueado.
	_reset()
	SaveGame.start_at_level(5)
	_finish(5)
	var results := (load("res://scenes/ui/level_results.tscn") as PackedScene).instantiate()
	root.add_child(results)
	await process_frame
	await process_frame
	var button: Button = results.find_child("ContinueButton", true, false)
	_check(button.text == "VOLVER AL MENÚ", "Sin desbloquear el mundo 2 el resultado no ofrece el nivel siguiente")
	results.queue_free()
	await process_frame

	_reset()
	SaveGame.start_at_level(1)
	for id in [1, 2, 3, 4, 5]:
		_finish(id)
	results = (load("res://scenes/ui/level_results.tscn") as PackedScene).instantiate()
	root.add_child(results)
	await process_frame
	await process_frame
	button = results.find_child("ContinueButton", true, false)
	_check(button.text == "SIGUIENTE NIVEL", "Tras superar el mundo 1 se ofrece el siguiente nivel")
	var subtitle: Label = results.find_child("Subtitle", true, false)
	_check(subtitle.text.contains("SUPERADA"), "El resultado anuncia la zona superada")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
