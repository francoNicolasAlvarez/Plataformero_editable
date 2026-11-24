extends SceneTree
## Comprueba la Fase 4 (2026-11-18): la máquina de estados de `Hazard`, el
## respiradero de vapor (aviso y daño solo en fase activa), la plataforma que
## se derrumba (agrieta, cae, reaparece, la reinicia la muerte) y la zona
## oscura (se oscurece solo con el jugador dentro). Ejecutar con:
## godot --headless --path . --script res://tests/hazard_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_sixteen.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_state_machine()

	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(10)
	var player: Player = level.get_node("Player")
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait_physics(2)

	await _check_vent(level, player)
	await _check_crumbling(level, player)
	await _check_dark_zone(level, player)
	await _check_death_reset(level, player)

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check_state_machine() -> void:
	var hazard := Hazard.new()
	hazard.warning_time = 0.1
	hazard.active_time = 0.1
	hazard.cooldown_time = 0.1
	var seen: Array[int] = []
	hazard.state_changed.connect(func(new_state: int) -> void: seen.append(new_state))
	_check(hazard.state == Hazard.State.IDLE, "El obstáculo empieza en reposo")
	hazard.tick(0.01)
	_check(hazard.state == Hazard.State.WARNING, "Con ciclo automático pasa al aviso")
	hazard.tick(0.11)
	_check(hazard.state == Hazard.State.ACTIVE, "Tras el aviso queda activo")
	hazard.tick(0.11)
	_check(hazard.state == Hazard.State.COOLDOWN, "Tras la fase activa se enfría")
	hazard.tick(0.11)
	_check(hazard.state == Hazard.State.IDLE, "Tras enfriarse vuelve al reposo")
	_check(seen == [1, 2, 3, 0], "Emite los cambios de estado en orden")
	hazard.tick(0.01)
	hazard.reset()
	_check(hazard.state == Hazard.State.IDLE, "reset() devuelve el obstáculo al reposo")

	var manual := Hazard.new()
	manual.auto_cycle = false
	manual.tick(1.0)
	_check(manual.state == Hazard.State.IDLE, "Sin ciclo automático espera a ser activado")
	manual.trigger()
	_check(manual.state == Hazard.State.WARNING, "trigger() arranca el aviso")
	hazard.free()
	manual.free()


func _check_vent(level: Node, player: Player) -> void:
	var vent := SteamVent.new()
	vent.initial_delay = 0.2
	vent.position = Vector2(500.0, 640.0)
	level.add_child(vent)
	vent.warning_time = 0.3
	vent.active_time = 0.6
	vent.cooldown_time = 5.0
	await _wait_physics(2)
	var zone_shape := vent.zone.get_node("ZoneShape") as CollisionShape2D
	_check(zone_shape.disabled, "El chorro no hace daño en reposo")
	player.global_position = Vector2(500.0, 610.0)
	player.velocity = Vector2.ZERO
	var hp := player.health.current_health
	await _wait_physics(25)
	_check(vent.state == Hazard.State.WARNING, "El respiradero avisa antes del chorro")
	_check(player.health.current_health == hp, "Durante el aviso no hay daño")
	await _wait_physics(30)
	_check(vent.state == Hazard.State.ACTIVE or vent.state == Hazard.State.COOLDOWN, "Después del aviso sale el chorro")
	_check(player.health.current_health < hp, "El chorro activo quita un golpe al jugador")
	vent.queue_free()
	await _wait_physics(2)


func _check_crumbling(level: Node, player: Player) -> void:
	player.global_position = Vector2(300.0, 600.0)
	player.velocity = Vector2.ZERO
	var platform := CaveKit.crumbling(level, Vector2(700.0, 520.0), "TestCrumbling")
	await _wait_physics(2)
	_check(platform.is_solid() and platform.state == Hazard.State.IDLE, "La plataforma empieza entera y sólida")
	player.global_position = Vector2(700.0, 470.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(18)
	_check(platform.state == Hazard.State.WARNING, "Al pisarla se agrieta y avisa")
	_check(platform.is_solid(), "Durante el aviso todavía sostiene al jugador")
	await _wait_physics(40)
	_check(platform.state == Hazard.State.ACTIVE, "Tras el aviso se derrumba")
	_check(not platform.is_solid(), "Derrumbada, ya no es sólida")
	_check(player.global_position.y > 540.0, "El jugador cae con ella")
	player.global_position = Vector2(300.0, 600.0)
	await _wait_physics(190)
	_check(platform.state == Hazard.State.IDLE and platform.is_solid(), "La plataforma reaparece sólida")
	platform.trigger()
	await _wait_physics(5)
	platform.reset()
	_check(platform.state == Hazard.State.IDLE and platform.is_solid(), "reset() restaura la plataforma")
	platform.queue_free()


func _check_dark_zone(level: Node, player: Player) -> void:
	player.global_position = Vector2(300.0, 600.0)
	player.velocity = Vector2.ZERO
	var zone := CaveKit.dark_zone(level, 900.0, 1500.0, "TestDark")
	await _wait_physics(10)
	_check(not zone.player_inside and zone.current_amount() < 0.01, "Fuera de la zona no hay oscuridad")
	_check(not zone.shade.visible, "La capa oscura está oculta fuera de la zona")
	player.global_position = Vector2(1200.0, 600.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(50)
	_check(zone.player_inside, "La zona detecta al jugador")
	_check(zone.current_amount() > 0.95 and zone.shade.visible, "Dentro de la zona la pantalla se oscurece")
	_check(zone.overlay_layer.layer < 10, "La oscuridad queda por debajo del HUD")
	player.global_position = Vector2(300.0, 600.0)
	await _wait_physics(50)
	_check(not zone.player_inside and zone.current_amount() < 0.01, "Al salir se aclara")
	zone.reset()
	_check(not zone.player_inside, "reset() limpia la zona")
	zone.queue_free()


func _check_death_reset(level: Node, player: Player) -> void:
	var platform := CaveKit.crumbling(level, Vector2(700.0, 520.0), "ResetCrumbling")
	var vent := SteamVent.new()
	vent.position = Vector2(900.0, 640.0)
	level.add_child(vent)
	await _wait_physics(3)
	platform.trigger()
	vent.tick(1.2)
	await _wait_physics(40)
	_check(platform.state != Hazard.State.IDLE, "La plataforma está en pleno derrumbe antes de morir")
	level._reset_hazards()
	var vent_state := vent.state
	await _wait_physics(2)
	_check(platform.state == Hazard.State.IDLE and platform.is_solid(), "Morir reinicia las plataformas que se derrumban")
	_check(vent_state == Hazard.State.IDLE, "Morir reinicia los respiraderos")
	platform.queue_free()
	vent.queue_free()


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
