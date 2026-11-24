extends SceneTree
## Comprueba (2026-11-18) que el jugador no puede salirse por el borde izquierdo
## del nivel y que al morir desaparecen los proyectiles, los enemigos fijos
## vuelven a su posición inicial y los que aparecen solos desaparecen.
## Ejecutar con:
## godot --headless --path . --script res://tests/death_reset_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_one.tscn")
const PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")
const FLYING_SCENE := preload("res://scenes/enemies/flying_enemy.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(10)
	var player: Player = level.get_node("Player")

	_check(level.get_node_or_null("BoundaryWalls/LeftWall") != null, "Hay un muro invisible en el borde izquierdo")
	_check(level.get_node_or_null("BoundaryWalls/RightWall") != null, "Hay un muro invisible en el borde derecho")
	player.global_position.x = 60.0
	Input.action_press("move_left")
	await _wait_physics(90)
	Input.action_release("move_left")
	_check(player.global_position.x >= 0.0, "El jugador no sale por la izquierda del nivel (x=%.0f)" % player.global_position.x)
	_check(not player.health.is_dead, "No muere al ir hacia la izquierda")

	# Enemigos: se mueven y luego vuelven a su sitio.
	var walkers := _enemies_of(level, WalkerEnemy)
	_check(not walkers.is_empty(), "El nivel tiene caminantes")
	var walker: TrainingDummy = walkers[0]
	var start: Vector2 = walker._start_position
	walker.position += Vector2(150.0, -40.0)
	var projectile := PROJECTILE_SCENE.instantiate()
	level.add_child(projectile)
	var flyer := FLYING_SCENE.instantiate()
	level.add_child(flyer)
	_check(not get_nodes_in_group("enemy_projectiles").is_empty(), "Hay un proyectil enemigo antes de morir")
	projectile.speed = 0.0
	level._reset_hazards()
	await _wait_physics(3)
	_check(walker.position.distance_to(start) < 20.0, "El enemigo vuelve a su posición inicial")
	_check(get_nodes_in_group("enemy_projectiles").is_empty(), "Los proyectiles desaparecen")
	_check(not is_instance_valid(flyer), "El enemigo que aparece solo desaparece")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _enemies_of(level: Node, type: Variant) -> Array:
	var result: Array = []
	for node in get_nodes_in_group("enemies"):
		if is_instance_of(node, type) and level.is_ancestor_of(node):
			result.append(node)
	return result


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
