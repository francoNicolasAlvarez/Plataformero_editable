extends SceneTree
## Comprueba (2026-11-18) que en ningún nivel hay enemigos superpuestos a las
## pilas de rocas del bruto (RockPile). El bruto de cada pila queda excluido.
## Ejecutar con: godot --headless --path . --script res://tests/pile_overlap_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for config in LevelRegistry.implemented_levels():
		var number: int = config.number
		var level: Node = (load(LevelRegistry.scene_path_for(number)) as PackedScene).instantiate()
		root.add_child(level)
		await physics_frame
		await physics_frame
		var offenders: Array[String] = []
		for pile in get_nodes_in_group("rock_piles"):
			for enemy in get_nodes_in_group("enemies"):
				if enemy is BruteEnemy or not enemy is Node2D:
					continue
				if _overlaps(pile as Node2D, enemy as Node2D):
					offenders.append(String(enemy.name))
		_check(offenders.is_empty(), "Nivel %d: ningún enemigo sobre las rocas %s" % [number, str(offenders)])
		level.queue_free()
		await physics_frame

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _overlaps(pile: Node2D, enemy: Node2D) -> bool:
	var dx := absf(enemy.global_position.x - pile.global_position.x)
	var dy := enemy.global_position.y - pile.global_position.y
	return dx <= 85.0 and dy >= -(RockPile.total_height() + 40.0) and dy <= 30.0


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
