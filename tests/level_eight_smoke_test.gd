extends SceneTree
## Smoke test del nivel 8: espejo horizontal del nivel 2 con controles
## invertidos. Comprueba spawn a la derecha, portal a la izquierda, espejo de
## plataformas/trampas/enemigos y dirección real del movimiento.

const LEVEL_SCENE := preload("res://scenes/levels/level_eight.tscn")
const COMPLETE_SCENE := "res://scenes/levels/level_nine.tscn"

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(30)

	var player: Player = level.get_node("Player")
	var portal: ExitPortal = level.get_node("ExitPortal")
	var camera: Camera2D = level.get_node("Camera")
	var generated := level.get_node_or_null("LevelEightGenerated")

	_check(level.level_variant == 8, "El nivel 8 usa la variante ESPEJO")
	_check(level.level_name == "NIVEL 2-3", "El nivel se identifica como NIVEL 2-3")
	_check(level.time_limit == 70.0, "El nivel 8 tiene 70 segundos")
	_check(level.next_level_path == COMPLETE_SCENE, "El nivel 8 lleva al nivel 9")
	_check(generated != null, "Se generó el mundo espejo del nivel 2")
	_check(level.get_node("Platforms").get_child_count() == 0, "El nivel 8 limpia las plataformas base")

	_check(player.inverted_controls, "El jugador usa controles invertidos")
	_check(player.global_position.x > 12000.0, "El jugador aparece en el lado derecho")
	_check(is_equal_approx(player.global_position.x, LevelEightLayout.PLAYER_START_X), "El spawn es el espejo del nivel 2")
	_check(player.is_on_floor() and player.global_position.y > 600.0 and player.global_position.y < 625.0, "El jugador se apoya en el suelo del nivel 2")
	_check(player.visual.flip_h, "El jugador mira hacia la izquierda al empezar")

	_check(is_equal_approx(portal.global_position.x, 450.0), "El portal es el espejo del portal del nivel 2")
	_check(is_equal_approx(portal.global_position.y, 580.0), "El portal mantiene la altura")
	_check(portal.global_position.x < player.global_position.x, "El recorrido va hacia la izquierda")
	_check(camera.limit_left == 0 and camera.limit_right == 13400, "La cámara cubre el ancho del nivel 2")
	_check(camera.limit_bottom == 720, "La cámara mantiene la altura de pantalla")

	var platforms := _collect_by_type(generated, "Platform")
	_check(platforms.size() >= 40, "El nivel 8 conserva las plataformas del nivel 2")
	var ground_originals := [1100.0, 2750.0, 3860.0, 5250.0, 6310.0, 7650.0, 8710.0, 10050.0, 11010.0, 12400.0]
	for original_x in ground_originals:
		_check(_has_node_at_x(platforms, LevelEightLayout.mirror_x(original_x), 680.0), "Suelo reflejado en x=%d" % int(LevelEightLayout.mirror_x(original_x)))

	var moving := level.get_tree().get_nodes_in_group("moving_platforms")
	_check(moving.size() == 4, "El nivel 8 conserva las 4 plataformas móviles")
	var moving_originals := [2290.0, 4740.0, 7140.0, 9540.0]
	for original_x in moving_originals:
		var mirrored_x := LevelEightLayout.mirror_x(original_x)
		_check(_has_node_at_x(moving, mirrored_x, 556.0, 30.0), "Plataforma móvil reflejada en x=%d" % int(mirrored_x))
	for platform in moving:
		_check(float(platform.get("travel").x) < 0.0, "El vaivén de las plataformas móviles también está invertido")

	var saws := level.get_tree().get_nodes_in_group("saws")
	_check(saws.size() == 10, "El nivel 8 conserva las 10 sierras")
	var saw_originals := [1450.0, 3050.0, 4300.0, 5650.0, 6750.0, 7900.0, 8950.0, 10250.0, 11250.0, 12150.0]
	for original_x in saw_originals:
		_check(_has_node_at_x(saws, LevelEightLayout.mirror_x(original_x), 608.0), "Sierra reflejada en x=%d" % int(LevelEightLayout.mirror_x(original_x)))

	var spikes: Array = []
	for item in level.get_tree().get_nodes_in_group("spikes"):
		if item is CanvasItem and (item as CanvasItem).visible:
			spikes.append(item)
	_check(spikes.size() == 5, "El nivel 8 conserva los 5 pinchos sobre suelo firme")
	var spike_originals := [1750.0, 3300.0, 5800.0, 8050.0, 10500.0]
	for original_x in spike_originals:
		_check(_has_node_at_x(spikes, LevelEightLayout.mirror_x(original_x), 632.0), "Pincho reflejado en x=%d" % int(LevelEightLayout.mirror_x(original_x)))

	var checkpoints := level.get_tree().get_nodes_in_group("checkpoints")
	_check(checkpoints.size() == 1, "El nivel 8 tiene un control a mitad del recorrido")
	if not checkpoints.is_empty():
		_check(is_equal_approx((checkpoints[0] as Node2D).global_position.x, 6700.0), "El control queda en el centro del espejo")

	var enemies := level.get_tree().get_nodes_in_group("enemies")
	_check(enemies.size() == 30, "El nivel 8 conserva los 30 enemigos del nivel 2")
	var spread_originals := [1950.0, 4450.0, 6950.0, 9350.0, 11750.0]
	var spreads := _collect_by_type(generated, "SpreadEnemy")
	_check(spreads.size() == 5, "El nivel 8 conserva los 5 arqueros")
	for original_x in spread_originals:
		_check(_has_node_at_x(spreads, LevelEightLayout.mirror_x(original_x), 616.0, 80.0, 8.0), "Arquero reflejado en x=%d" % int(LevelEightLayout.mirror_x(original_x)))

	var herbs := level.get_tree().get_nodes_in_group("healing_pickups")
	_check(herbs.size() == 6, "El nivel 8 conserva las 6 hierbas")
	var herb_originals := [1450.0, 3950.0, 6450.0, 8850.0, 11250.0, 12200.0]
	for original_x in herb_originals:
		_check(_has_node_at_x(herbs, LevelEightLayout.mirror_x(original_x), 618.0), "Hierba reflejada en x=%d" % int(LevelEightLayout.mirror_x(original_x)))

	Input.action_press("move_right")
	await _wait_physics(10)
	_check(player.velocity.x < -20.0, "Pulsar derecha mueve al jugador hacia la izquierda")
	Input.action_release("move_right")
	await _wait_physics(4)
	Input.action_press("move_left")
	await _wait_physics(10)
	_check(player.velocity.x > 20.0, "Pulsar izquierda mueve al jugador hacia la derecha")
	Input.action_release("move_left")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _collect_by_type(node: Node, script_name: String) -> Array:
	var result: Array = []
	for child in node.get_children():
		var matches := (script_name == "Platform" and child is Platform) 			or (script_name == "SpreadEnemy" and child is SpreadEnemy)
		if matches:
			result.append(child)
		result.append_array(_collect_by_type(child, script_name))
	return result


func _has_node_at_x(nodes: Array, x: float, y: float, tolerance: float = 2.0, y_tolerance: float = 2.0) -> bool:
	for node in nodes:
		var item := node as Node2D
		if item != null and absf(item.global_position.x - x) < tolerance and absf(item.global_position.y - y) < y_tolerance:
			return true
	return false


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
