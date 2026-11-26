extends SceneTree
## Comprueba las rocas que caen (2026-11-17, ajustado el 2026-11-23): cuelgan
## armadas con marcador, caen 0,2 s después de que el jugador se coloque
## debajo, caída rápida, daño de un golpe al jugador, rotura contra el suelo y que no
## se creen rocas sobre un foso. Ejecutar con:
## godot --headless --path . --script res://tests/rockfall_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_nine.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(20)

	var player: Player = level.get_node("Player")
	var camera: Camera2D = level.get_node("Camera")
	var spawner := level.get_node("LevelNineGenerated/RockfallSpawner") as RockfallSpawner
	_check(spawner != null, "El nivel 9 tiene generador de rocas")
	_check(is_equal_approx(FallingRock.TRIGGER_DELAY, 0.2), "La roca cae 0,2 s después de ponerse el jugador debajo")
	_check(FallingRock.FALL_SPEED >= 1200.0, "La roca cae muy rápido")
	spawner.active = false
	# Sin murciélagos: podían golpear al jugador y volver intermitente el test.
	for bats in level.find_children("*", "FlyingSpawner", true, false):
		bats.active = false
	FlyingSpawner.clear_flying_enemies(self)
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait_physics(2)

	# Sobre un foso no hay superficie: no se crea roca.
	player.global_position = Vector2(1300.0, 600.0)
	camera.snap_to_target()
	await _wait_physics(5)
	_check(spawner.spawn_rock_at(1540.0) == null, "No cae ninguna roca sobre un foso")

	# Roca sobre el suelo, lejos de plataformas. El jugador empieza lejos.
	var x := LevelNineLayout.section_start(0) + 100.0
	player.global_position = Vector2(x - 500.0, 600.0)
	player.velocity = Vector2.ZERO
	camera.global_position = Vector2(x, 360.0)
	camera.snap_to_target()
	await _wait_physics(40)
	var hp_before := player.health.current_health
	var rock := spawner.spawn_rock_at(x)
	_check(rock != null, "Se crea una roca sobre el suelo")
	if rock == null:
		print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
		quit(1)
		return
	await _wait_physics(2)
	var markers := get_nodes_in_group("rock_warnings")
	_check(markers.size() == 1, "Aparece un marcador de aviso")
	_check(rock.state == FallingRock.State.WARNING and not rock.is_triggered(), "La roca cuelga armada, sin activarse")
	_check(absf((markers[0] as Node2D).global_position.y - LevelNineLayout.GROUND_TOP) < 2.0, "El marcador está sobre la superficie de impacto")
	_check(absf((markers[0] as Node2D).global_position.x - x) < 2.0, "El marcador está en la columna de impacto")
	_check(rock.global_position.y < LevelNineLayout.GROUND_TOP - 200.0 and rock.get_node("Rock").visible, "La roca cuelga visible arriba")
	_check(rock.get_node("Rock").find_child("Ball", true, false) != null, "Es una bola de hierro")
	_check(rock.get_node("Rock").find_child("Flame0", true, false) == null, "Ya no lleva llamas")
	var spikes := 0
	for child in rock.get_node("Rock").get_children():
		if child is Polygon2D and String(child.name).begins_with("Spike"):
			spikes += 1
	_check(spikes == FallingRock.SPIKE_COUNT, "La bola lleva púas (%d)" % spikes)

	await _wait_physics(60)
	_check(rock.state == FallingRock.State.WARNING, "Con el jugador lejos la roca sigue colgada")
	_check(player.health.current_health == hp_before, "Colgada no hace daño a distancia")

	# Tocar la bola colgada (inmóvil) también hace daño y no la hace caer.
	# Encima de la bola (no debajo) para no activar la caída.
	player.global_position = rock.global_position + Vector2(0.0, -34.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(2)
	_check(player.health.current_health == hp_before - 1, "Tocar la bola colgada quita un golpe")
	_check(rock.state == FallingRock.State.WARNING, "La bola sigue colgada tras el contacto")
	player.global_position = Vector2(x - 500.0, 600.0)
	player.velocity = Vector2.ZERO
	player.health.heal(99)
	await _wait_physics(50)
	hp_before = player.health.current_health

	# El jugador se coloca debajo: cae 0,2 s después, no antes.
	player.global_position = Vector2(x, 600.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(4)
	_check(rock.is_triggered() and rock.state == FallingRock.State.WARNING, "Al ponerse debajo se activa la cuenta de 0,2 s")
	await _wait_physics(5)
	_check(rock.state == FallingRock.State.WARNING, "A los ~0,15 s todavía no ha caído")
	await _wait_physics(8)
	_check(rock.state != FallingRock.State.WARNING, "Pasados 0,2 s empieza a caer")
	await _wait_physics(40)
	_check(not is_instance_valid(rock) or rock.state == FallingRock.State.DONE, "La roca se rompe al llegar al suelo")
	_check(get_nodes_in_group("rock_warnings").is_empty(), "El marcador desaparece tras el impacto")
	_check(player.health.current_health == hp_before - 1, "La roca quita un golpe al jugador que está debajo")

	# Roca que cae en un sitio libre: no daña.
	player.global_position = Vector2(x + 500.0, 600.0)
	await _wait_physics(80)
	var hp_mid := player.health.current_health
	var other := spawner.spawn_rock_at(x)
	_check(other != null, "Se crea otra roca lejos del jugador")
	await _wait_physics(150)
	_check(player.health.current_health == hp_mid, "Una roca que no cae sobre el jugador no daña")
	await _wait_physics(80)
	_check(other == null or not is_instance_valid(other) or other.state != FallingRock.State.WARNING, "Si nadie se pone debajo cae sola tras %.1f s" % FallingRock.MAX_WAIT)

	# Las rocas del generador siempre caen por delante del jugador.
	FallingRock.clear_rocks(self)
	await _wait_physics(2)
	var px := LevelNineLayout.section_start(2) + 100.0
	player.global_position = Vector2(px, 600.0)
	player.velocity = Vector2.ZERO
	camera.snap_to_target()
	await _wait_physics(40)
	var created := 0
	var behind := 0
	for _attempt in 40:
		spawner._spawn_event(player)
	for rock_node in get_nodes_in_group("falling_rocks"):
		created += 1
		if rock_node.position.x < player.global_position.x + spawner.min_ahead - 1.0:
			behind += 1
	_check(created > 10, "El generador crea rocas (%d)" % created)
	_check(behind == 0, "Ninguna roca aparece detrás o sobre el jugador")
	_check(spawner.interval <= 2.2 / 3.0 + 0.01, "Caen 3 veces más rocas que antes (cada %.2f s)" % spawner.interval)

	var extra := spawner.spawn_rock_at(x)
	if extra != null:
		FallingRock.clear_rocks(self)
		await _wait_physics(2)
		_check(get_nodes_in_group("falling_rocks").is_empty(), "clear_rocks elimina las rocas pendientes")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


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
