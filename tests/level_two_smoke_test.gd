extends SceneTree
## Comprueba el nivel 2: atardecer, trampas, enemigos móviles con ráfagas
## comunes y portal siempre disponible. Ejecutar con:
## godot --headless --path . --script res://tests/level_two_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_two.tscn")
const LEVEL_THREE := "res://scenes/levels/level_three.tscn"

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	var portal: ExitPortal = level.get_node("ExitPortal")
	var hint: Label = level.get_node("HUD/PortalHint")
	var camera: Camera2D = level.get_node("Camera")

	await _wait_physics(30)

	_check(level.level_variant == 2, "El nivel 2 usa la variante atardecer")
	_check(level.level_name == "NIVEL 1-2", "El nivel se identifica como NIVEL 1-2")
	_check(level.next_level_path == LEVEL_THREE, "El nivel 2 continúa hacia el nivel 3")
	_check(level.get_node_or_null("LevelTwoGenerated") != null, "Se generó el contenido del nivel 2")
	_check(level.get_node("Platforms").get_child_count() == 0, "Se limpiaron las plataformas del nivel 1")
	_check(not level.get_node("Background").visible, "El fondo diurno queda oculto")
	_check(not level.get_node("BackgroundDecor").visible, "Las colinas diurnas quedan ocultas")
	_check(level.get_node_or_null("SpreadEnemy") == null, "La instancia base del enemigo ráfaga se limpia en el nivel 2")

	var enemies := get_nodes_in_group("enemies")
	var moving := get_nodes_in_group("moving_platforms")
	var saws := get_nodes_in_group("saws")
	var spikes := get_nodes_in_group("spikes")

	var static_enemies := 0
	var platform_enemies := 0
	var spread_enemies := 0
	for enemy in enemies:
		var enemy_script := enemy.get_script() as Script
		if enemy_script != null and enemy_script.resource_path.ends_with("training_dummy.gd"):
			static_enemies += 1
		if enemy is WalkerEnemy and enemy.global_position.y < 570.0:
			platform_enemies += 1
		if enemy is SpreadEnemy:
			spread_enemies += 1

	_check(enemies.size() >= 24, "El nivel 2 aumenta la densidad de enemigos")
	var spawn_clear := true
	for enemy in enemies:
		if enemy is WalkerEnemy and enemy.global_position.y > 590.0 and enemy.global_position.x < 900.0:
			spawn_clear = false
	_check(spawn_clear, "No hay walkers de suelo junto a la salida del nivel 2")
	_check(static_enemies == 0, "No quedan enemigos estáticos en el nivel 2")
	_check(platform_enemies >= 8, "Hay varios enemigos patrullando plataformas")
	_check(spread_enemies >= 4, "El nivel 2 incluye enemigos ráfaga comunes")
	_check(_count_named(level, "FallZone") >= 5, "El nivel 2 añade más pozos mortales")
	_check(_count_platforms(level) >= 40, "El nivel 2 añade muchas más plataformas")
	_check(moving.size() >= 4, "Hay plataformas móviles sobre los fosos")
	_check(saws.size() >= 8, "Hay sierras móviles repartidas por el nivel")
	var loose_spikes := _loose_spikes(spikes)
	_check(loose_spikes.size() == 5, "Hay cinco pinchos sueltos, todos sobre suelo firme")
	_check(_all_spikes_supported(level, loose_spikes), "Ningún pincho suelto está colocado sobre el aire")
	_check(level.get_node_or_null("LevelTwoGenerated/FallZone") != null, "Existe zona de caída mortal")
	_check(portal.monitoring, "El portal del nivel 2 está activo desde el inicio")
	_check(get_nodes_in_group("checkpoints").size() == 1, "El nivel 2 tiene un único control a mitad del recorrido")
	_check(not hint.visible, "No hay aviso de portal bloqueado")
	_check(portal.global_position.x > 12500.0, "El portal está al final del nivel")
	_check(camera.limit_right == 13400, "La cámara cubre todo el nivel 2")

	var start_platform_x: float = (moving[0] as Node2D).position.x
	await _wait_physics(30)
	_check(absf((moving[0] as Node2D).position.x - start_platform_x) > 5.0, "Las plataformas móviles se desplazan")

	var saw := saws[0] as Area2D
	saw._on_body_entered(player)
	await _wait_physics(4)
	_check(player.health.current_health == 2, "Las sierras consumen uno de los 3 golpes")

	player.global_position = Vector2(6600.0, 790.0)
	await _wait_physics(70)
	_check(player.health.current_health == 0, "La zona de caída elimina al jugador")
	_check(level.get_node("HUD/GameOver").visible, "La zona de caída muestra la pantalla de muerte")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _loose_spikes(spikes: Array[Node]) -> Array[Node]:
	## Los pinchos hijos de una plataforma pertenecen al asset modular; solo
	## los sueltos deben validarse contra el suelo.
	var loose: Array[Node] = []
	for spike in spikes:
		if not spike.get_parent() is Platform:
			loose.append(spike)
	return loose


func _all_spikes_supported(level: Node, spikes: Array[Node]) -> bool:
	## Cada pincho suelto debe apoyar sobre una plataforma estática.
	var platforms := PlatformSpacing.collect_platforms(level)
	for spike in spikes:
		var probe: Vector2 = (spike as Node2D).global_position + Vector2(0.0, 10.0)
		var supported := false
		for platform in platforms:
			if PlatformSpacing.platform_rect(platform).has_point(probe):
				supported = true
				break
		if not supported:
			return false
	return true


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
