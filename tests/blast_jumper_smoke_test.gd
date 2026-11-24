extends SceneTree
## Comprueba el saltador explosivo (2026-11-17): quieto hasta detectar al
## jugador, se comprime con señal visual, salta rápido en parábola, al aterrizar
## genera una onda expansiva a ras de suelo que se esquiva saltando, necesita
## unos segundos para prepararse de nuevo y la variante de salto largo tiene
## preparación más lenta. Ejecutar con:
## godot --headless --path . --script res://tests/blast_jumper_smoke_test.gd

const JUMPER_SCENE := preload("res://scenes/enemies/blast_jumper_enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _make_world() -> Node2D:
	var world := Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8000.0, 100.0)
	shape.shape = rectangle
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 690.0)
	world.add_child(floor_body)
	return world


func _make_target(world: Node2D, x: float) -> Node2D:
	var target := Node2D.new()
	target.add_to_group("player")
	target.position = Vector2(x, 616.0)
	world.add_child(target)
	return target


func _make_player(world: Node2D, position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	world.add_child(player)
	player.set_physics_process(false)
	return player


func _run() -> void:
	# --- Quieto hasta detectar; compresión; parábola; onda; reposo.
	var world := _make_world()
	var target := _make_target(world, 1500.0)
	var jumper: BlastJumperEnemy = JUMPER_SCENE.instantiate()
	jumper.position = Vector2(0.0, 623.0)
	world.add_child(jumper)
	await _wait_physics(40)
	_check(jumper.is_in_group("enemies") and jumper.is_on_floor(), "El saltador es un enemigo y se apoya en el suelo")
	_check(jumper.state == BlastJumperEnemy.State.IDLE and is_zero_approx(jumper.global_position.x), "Permanece quieto mientras no detecta al jugador")

	var blasts: Array[float] = []
	jumper.blasted.connect(func(_position: Vector2, radius: float) -> void: blasts.append(radius))
	target.global_position.x = 300.0
	var windup_frames := 0
	var min_squash := 1.0
	var flashed := false
	var heights: Array[float] = []
	var air_frames := 0
	var landing_x := 0.0
	var rest_frames := 0
	var wave: ShockWave = null
	var wave_radius_early := 0.0
	var left_idle := false
	for _frame in 420:
		await physics_frame
		match jumper.state:
			BlastJumperEnemy.State.WINDUP:
				left_idle = true
				windup_frames += 1
				min_squash = minf(min_squash, absf(jumper.visual.scale.y))
				if jumper.visual.modulate.g < 0.8:
					flashed = true
			BlastJumperEnemy.State.AIR:
				air_frames += 1
				heights.append(jumper.global_position.y)
			BlastJumperEnemy.State.REST:
				rest_frames += 1
				landing_x = jumper.global_position.x
				if rest_frames == 12:
					for node in get_nodes_in_group("shock_waves"):
						wave = node
						wave_radius_early = wave.current_radius()
			_:
				# Solo se mide el primer ciclo: se corta al volver a estar listo tras el reposo.
				if rest_frames > 0:
					break
	_check(left_idle and windup_frames >= 38 and windup_frames <= 46, "Se prepara unos 0,7 s (%d frames)" % windup_frames)
	_check(min_squash < 0.75, "Comprime el cuerpo antes de saltar (escala %.2f)" % min_squash)
	_check(flashed, "Emite una señal visual (parpadeo rojo)")
	var apex: float = heights.min()
	var apex_index := heights.find(apex)
	_check(apex_index > 3 and apex_index < heights.size() - 3, "Salta en parábola: sube y luego baja")
	_check(air_frames <= 50, "El salto es rápido (%d frames en el aire)" % air_frames)
	_check(absf(landing_x - 300.0) < 25.0, "Aterriza hacia la posición del jugador (x=%.0f)" % landing_x)
	_check(blasts.size() >= 1 and is_equal_approx(blasts[0], 260.0), "Al aterrizar genera una onda expansiva de 260 px")
	_check(wave_radius_early > 20.0, "La onda se expande (radio %.0f px a los 0,2 s)" % wave_radius_early)
	_check(rest_frames >= 120, "Necesita unos segundos para volver a prepararse (%d frames)" % rest_frames)
	world.queue_free()
	await process_frame

	# --- Onda expansiva: se esquiva saltando.
	world = _make_world()
	var player := _make_player(world, Vector2(100.0, 616.0))
	var hp_before := player.health.current_health
	var ground_wave := ShockWave.new()
	ground_wave.max_radius = 150.0
	world.add_child(ground_wave)
	ground_wave.global_position = Vector2(0.0, 640.0)
	await _wait_physics(30)
	_check(ground_wave.hit_player and player.health.current_health == hp_before - 1, "La onda daña al jugador que está en el suelo dentro de su radio")
	world.queue_free()
	await process_frame

	world = _make_world()
	player = _make_player(world, Vector2(100.0, 616.0 - 70.0))
	hp_before = player.health.current_health
	ground_wave = ShockWave.new()
	ground_wave.max_radius = 150.0
	world.add_child(ground_wave)
	ground_wave.global_position = Vector2(0.0, 640.0)
	await _wait_physics(30)
	_check(not ground_wave.hit_player and player.health.current_health == hp_before, "Saltando por encima de la onda no hay daño")
	world.queue_free()
	await process_frame

	world = _make_world()
	player = _make_player(world, Vector2(260.0, 616.0))
	hp_before = player.health.current_health
	ground_wave = ShockWave.new()
	ground_wave.max_radius = 150.0
	world.add_child(ground_wave)
	ground_wave.global_position = Vector2(0.0, 640.0)
	await _wait_physics(30)
	_check(player.health.current_health == hp_before, "Fuera del radio de la onda no hay daño")
	world.queue_free()
	await process_frame

	# --- Variante de salto largo: más alcance, más onda, preparación más lenta.
	world = _make_world()
	var normal: BlastJumperEnemy = JUMPER_SCENE.instantiate()
	var long_one: BlastJumperEnemy = JUMPER_SCENE.instantiate()
	long_one.long_jump = true
	normal.position = Vector2(-2000.0, 623.0)
	long_one.position = Vector2(2000.0, 623.0)
	world.add_child(normal)
	world.add_child(long_one)
	await _wait_physics(5)
	_check(long_one.max_distance > normal.max_distance, "El salto largo llega más lejos (%.0f vs %.0f px)" % [long_one.max_distance, normal.max_distance])
	_check(long_one.windup_time > normal.windup_time, "El salto largo tiene la preparación más lenta (%.1f vs %.1f s)" % [long_one.windup_time, normal.windup_time])
	_check(long_one.wave_radius > normal.wave_radius, "El salto largo genera una onda mayor")
	var long_body := (long_one.get_node("Visual/Body") as Polygon2D).color
	var normal_body := (normal.get_node("Visual/Body") as Polygon2D).color
	_check(long_body != normal_body, "La variante se distingue por el color")
	world.queue_free()
	await process_frame

	# --- No aterriza en el vacío.
	world = Node2D.new()
	root.add_child(world)
	var short_floor := StaticBody2D.new()
	short_floor.collision_layer = 1
	var short_shape := CollisionShape2D.new()
	var short_rect := RectangleShape2D.new()
	short_rect.size = Vector2(300.0, 100.0)
	short_shape.shape = short_rect
	short_floor.add_child(short_shape)
	short_floor.position = Vector2(0.0, 690.0)
	world.add_child(short_floor)
	_make_target(world, 700.0)
	var edge: BlastJumperEnemy = JUMPER_SCENE.instantiate()
	edge.position = Vector2(100.0, 623.0)
	world.add_child(edge)
	var fell := false
	for _frame in 300:
		await physics_frame
		if edge.global_position.y > 720.0:
			fell = true
	_check(not fell, "No se lanza al vacío aunque el jugador esté al otro lado")

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
