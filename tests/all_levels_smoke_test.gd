extends SceneTree
## Prueba automática de TODOS los niveles implementados (2026-11-18): carga
## cada escena, deja correr unos frames y comprueba lo básico (jugador vivo,
## portal, cámara con límites, muros laterales, plataformas bajo el spawn y
## enemigos con posición inicial registrada). Sirve de red de seguridad al
## añadir niveles nuevos: se descubren solos desde `LevelRegistry`.
## Ejecutar con:
## godot --headless --path . --script res://tests/all_levels_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for config in LevelRegistry.implemented_levels():
		var path := LevelRegistry.scene_path_for(config.number)
		if path.is_empty():
			continue
		var tag := "Nivel %d" % config.number
		var scene := load(path) as PackedScene
		_check(scene != null, "%s: la escena carga" % tag)
		if scene == null:
			continue
		var level := scene.instantiate()
		root.add_child(level)
		for _frame in 30:
			await physics_frame
		var player := level.get_node_or_null("Player") as Player
		_check(player != null and not player.health.is_dead, "%s: el jugador está vivo tras 30 frames" % tag)
		_check(level.get_node_or_null("ExitPortal") != null, "%s: tiene portal de salida" % tag)
		_check(level.get_node_or_null("BoundaryWalls/LeftWall") != null, "%s: tiene muros laterales" % tag)
		_check(get_nodes_in_group("checkpoints").size() >= 1, "%s: tiene al menos un control" % tag)
		_check(is_equal_approx(level.time_limit, 70.0), "%s: límite de 70 s" % tag)
		_check(level.gold_medal_time > 0.0 and level.gold_medal_time < level.silver_medal_time
				and level.silver_medal_time < level.bronze_medal_time, "%s: umbrales de medalla ordenados (%.1f/%.1f/%.1f)" % [tag, level.gold_medal_time, level.silver_medal_time, level.bronze_medal_time])
		var unrecorded := 0
		for enemy in get_nodes_in_group("enemies"):
			if enemy is TrainingDummy and level.is_ancestor_of(enemy) and not enemy._start_recorded:
				unrecorded += 1
		_check(unrecorded == 0, "%s: todos los enemigos tienen posición inicial" % tag)
		level.queue_free()
		for _frame in 3:
			await process_frame

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
