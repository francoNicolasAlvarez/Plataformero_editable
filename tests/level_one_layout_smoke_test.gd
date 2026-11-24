extends SceneTree
## Comprueba el nivel 1: recorrido largo, enemigos móviles, decoración diurna
## y portal siempre disponible. Ejecutar con:
## godot --headless --path . --script res://tests/level_one_layout_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var extension: Node2D = level.get_node("LevelOneExtension")
	var spread: Node2D = level.get_node("SpreadEnemy")
	var portal: ExitPortal = level.get_node("ExitPortal")
	var hint: Label = level.get_node("HUD/PortalHint")
	var camera: Camera2D = level.get_node("Camera")
	var background: ColorRect = level.get_node("Background")

	await _wait_physics(30)

	var enemies := get_nodes_in_group("enemies")
	var coins := get_nodes_in_group("coins")
	var suns := get_nodes_in_group("decor_sun")
	var birds := get_nodes_in_group("birds")
	var rabbits := get_nodes_in_group("ambient_animals")

	var static_enemies := 0
	var platform_enemies := 0
	var spread_enemies := 0
	for enemy in enemies:
		var script := enemy.get_script() as Script
		if script != null and script.resource_path.ends_with("training_dummy.gd"):
			static_enemies += 1
		if enemy is WalkerEnemy and enemy.global_position.y < 570.0:
			platform_enemies += 1
		if enemy is SpreadEnemy:
			spread_enemies += 1

	_check(extension.get_child_count() >= 100, "El nivel 1 genera una gran cantidad de contenido")
	_check(enemies.size() >= 25 and enemies.size() <= 55, "El nivel 1 tiene muchos enemigos móviles")
	_check(static_enemies == 0, "No quedan enemigos estáticos en el nivel")
	_check(platform_enemies >= 20, "Hay muchos enemigos patrullando sobre las plataformas")
	_check(spread_enemies >= 5, "El enemigo ráfaga (antiguo jefe) aparece en el nivel 1")
	_check(coins.is_empty(), "El nivel 1 ya no tiene monedas")
	_check(_count_named(extension, "FallZone") >= 12, "El nivel 1 añade muchos pozos mortales")
	_check(_count_platforms(extension) >= 100, "El nivel 1 tiene muchas más plataformas")
	_check(level.time_limit == 70.0, "El nivel 1 tiene una cuenta regresiva de 70 segundos")
	_check(suns.size() >= 1, "El nivel 1 incluye un sol de fondo")
	_check(birds.size() >= 10, "El nivel 1 incluye aves posadas en los árboles")
	_check(rabbits.is_empty(), "El conejo anterior ya no aparece en el nivel")
	_check(spread.global_position.x < 2800.0, "El enemigo ráfaga ya no guarda el final del nivel")
	_check(portal.global_position.x > 21000.0, "El portal está al final del recorrido")
	_check(portal.monitoring, "El portal está activo desde el inicio")
	_check(not hint.visible, "El HUD no muestra un aviso de bloqueo")
	_check(camera.limit_right == 22400, "La cámara cubre el nivel extendido")
	_check(background.size.x > 22000.0, "El fondo cubre todo el nivel extendido")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _count_named(node: Node, prefix: String) -> int:
	var total := 0
	for child in node.get_children():
		if child.name.begins_with(prefix):
			total += 1
		total += _count_named(child, prefix)
	return total


func _count_platforms(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		if child is Platform:
			total += 1
		total += _count_platforms(child)
	return total


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
