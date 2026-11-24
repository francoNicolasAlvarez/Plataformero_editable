extends SceneTree
## Comprueba el nivel 3: granja nocturna, enemigos móviles rápidos, magos,
## enemigos ráfaga comunes (antiguo jefe) y ausencia de árboles, arbustos y
## aves.
## Ejecutar con:
## godot --headless --path . --script res://tests/level_three_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_three.tscn")
const LEVEL_FOUR := "res://scenes/levels/level_four.tscn"

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var portal: ExitPortal = level.get_node("ExitPortal")
	var hint: Label = level.get_node("HUD/PortalHint")
	var camera: Camera2D = level.get_node("Camera")

	await _wait_physics(30)

	_check(level.level_variant == 3, "El nivel 3 usa la variante nocturna")
	_check(level.level_name == "NIVEL 1-3", "El nivel se identifica como NIVEL 1-3")
	_check(level.next_level_path == LEVEL_FOUR, "El nivel 3 continúa hacia el nivel 4")
	_check(level.get_node_or_null("LevelThreeGenerated") != null, "Se generó el contenido de la granja")
	_check(not level.get_node("Background").visible, "El fondo diurno queda oculto")
	_check(not level.get_node("BackgroundDecor").visible, "Las colinas diurnas quedan ocultas")

	var enemies := get_nodes_in_group("enemies")
	var coins := get_nodes_in_group("coins")
	var herbs := get_nodes_in_group("healing_pickups")
	var birds := get_nodes_in_group("birds")

	var walkers := 0
	var ranged := 0
	var static_enemies := 0
	var fast_walkers := 0
	var platform_enemies := 0
	var spread_enemies := 0
	for enemy in enemies:
		if enemy is SpreadEnemy:
			spread_enemies += 1
		if enemy is RangedEnemy and not enemy is SpreadEnemy:
			ranged += 1
		if enemy is WalkerEnemy:
			walkers += 1
			if float(enemy.get("patrol_speed")) >= 150.0:
				fast_walkers += 1
			if enemy.global_position.y < 570.0:
				platform_enemies += 1
		var enemy_script := enemy.get_script() as Script
		if enemy_script != null and enemy_script.resource_path.ends_with("training_dummy.gd"):
			static_enemies += 1

	_check(enemies.size() >= 40, "La granja mantiene una densidad alta de enemigos")
	_check(
		walkers + spread_enemies + ranged == enemies.size(),
		"Los enemigos del nivel 3 son walkers, magos y ráfagas"
	)
	_check(ranged >= 3, "La granja recupera magos como enemigos a distancia")
	_check(walkers <= 36, "La granja redujo la densidad de walkers")
	_check(static_enemies == 0, "El nivel 3 no tiene enemigos estáticos")
	_check(fast_walkers == walkers, "Los walkers de la granja son rápidos")
	_check(spread_enemies >= 4, "La granja incluye varios enemigos ráfaga comunes")
	_check(platform_enemies >= 20, "La granja coloca muchos enemigos en plataformas")
	_check(_count_named(level, "FallZone") >= 8, "La granja añade más pozos mortales")
	_check(_count_platforms(level) >= 20, "La granja añade muchas más plataformas")
	_check(birds.is_empty(), "El nivel 3 no tiene aves")
	_check(_count_named(level, "Tree") == 0, "El nivel 3 no tiene árboles")
	_check(_count_named(level, "Bush") == 0, "El nivel 3 no tiene arbustos")
	_check(coins.is_empty(), "La granja ya no tiene monedas")
	_check(herbs.size() >= 3, "La granja contiene varias curaciones")
	_check(portal.monitoring, "El portal del nivel 3 está activo desde el inicio")
	_check(get_nodes_in_group("checkpoints").size() == 1, "La granja tiene un único control a mitad del recorrido")
	_check(not hint.visible, "No hay aviso de portal bloqueado")
	_check(portal.global_position.x > 12000.0, "El portal está al final de la granja")
	_check(camera.limit_right == 12600, "La cámara cubre toda la granja")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _count_platforms(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		if child is Platform:
			total += 1
		total += _count_platforms(child)
	return total


func _count_named(node: Node, prefix: String) -> int:
	var total := 0
	for child in node.get_children():
		if child.name.begins_with(prefix):
			total += 1
		total += _count_named(child, prefix)
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
