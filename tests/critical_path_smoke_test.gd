extends SceneTree
## Camino crítico de TODOS los niveles (2026-11-27). Para cada nivel de
## `LevelRegistry.implemented_levels()` comprueba lo imprescindible para poder
## terminarlo, sin jugarlo entero:
## 1. El jugador nace apoyado (suelo o techo en gravedad invertida) y vivo.
## 2. Ningún enemigo nace encima del jugador (zona segura de salida).
## 3. El portal y el control tienen superficie sólida debajo (no flotan sobre
##    un pozo) y quedan dentro de los límites horizontales de la cámara.
## 4. La escena siguiente existe (la cadena de niveles no se rompe).
## 5. Entrar en el portal completa el nivel; si el portal empieza bloqueado
##    (niveles con condición de victoria) se comprueba que no lo completa.
## Ejecutar con:
## godot --headless --path . --script res://tests/critical_path_smoke_test.gd

## Radio de la zona segura de salida (px): ningún enemigo puede nacer dentro.
const SPAWN_SAFE_RADIUS := 160.0
## Distancia máxima hasta la superficie bajo el portal/control.
const SURFACE_PROBE := 260.0

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for config in LevelRegistry.implemented_levels():
		var path := LevelRegistry.scene_path_for(config.number)
		if path.is_empty():
			continue
		await _check_level(config.number, path)

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check_level(number: int, path: String) -> void:
	var tag := "Nivel %d" % number
	var level: Node2D = (load(path) as PackedScene).instantiate()
	root.add_child(level)
	for _frame in 30:
		await physics_frame

	var player := level.get_node("Player") as Player
	var down := -1.0 if player.inverted_gravity else 1.0
	_check(not player.health.is_dead and player.is_on_floor(), "%s: el jugador nace apoyado y vivo" % tag)

	var start: Vector2 = level.get_meta("start_point", player.global_position)
	var close := 0
	for enemy in get_nodes_in_group("enemies"):
		if enemy is Node2D and level.is_ancestor_of(enemy) and (enemy as Node2D).global_position.distance_to(start) < SPAWN_SAFE_RADIUS:
			close += 1
	_check(close == 0, "%s: ningún enemigo nace a menos de %d px del jugador" % [tag, int(SPAWN_SAFE_RADIUS)])

	var camera := level.get_node("Camera") as Camera2D
	var portal := level.get_node("ExitPortal") as ExitPortal
	_check(_has_surface(level, portal.global_position, down), "%s: el portal tiene suelo debajo" % tag)
	_check(portal.global_position.x > camera.limit_left and portal.global_position.x < camera.limit_right, "%s: el portal queda dentro de la cámara" % tag)
	for checkpoint in get_nodes_in_group("checkpoints"):
		if level.is_ancestor_of(checkpoint):
			_check(_has_surface(level, (checkpoint as Node2D).global_position, down), "%s: el control tiene suelo debajo" % tag)

	var next := LevelRegistry.next_implemented_level(number)
	if next != -1:
		_check(ResourceLoader.exists(LevelRegistry.scene_path_for(next)), "%s: la escena del nivel siguiente existe" % tag)

	# Entrar en el portal.
	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	for _frame in 6:
		await physics_frame
	if portal.locked:
		_check(not level._completed, "%s: el portal bloqueado no completa el nivel" % tag)
	else:
		_check(level._completed, "%s: entrar en el portal completa el nivel" % tag)

	# Fuera el nivel antes de que su transición (2 s) cambie de escena.
	level.set_process(false)
	level.queue_free()
	for _frame in 3:
		await process_frame


func _has_surface(level: Node, point: Vector2, down: float) -> bool:
	var space := (level as Node2D).get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(point, point + Vector2(0.0, SURFACE_PROBE * down), 1)
	query.collide_with_areas = false
	return not space.intersect_ray(query).is_empty()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
