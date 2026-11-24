extends SceneTree
## Comprueba la babosa saltarina (2026-11-17): permanece quieta, se agacha antes
## de saltar, salta con alturas distintas, salta hacia el jugador cuando está
## cerca (y en el sitio cuando está lejos), no se lanza a un foso y la variante
## de doble salto encadena dos saltos antes de detenerse. Ejecutar con:
## godot --headless --path . --script res://tests/slug_enemy_smoke_test.gd

const SLUG_SCENE := preload("res://scenes/enemies/slug_enemy.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _make_world(floor_left: float, floor_right: float) -> Node2D:
	var world := Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(floor_right - floor_left, 100.0)
	shape.shape = rectangle
	floor_body.add_child(shape)
	floor_body.position = Vector2((floor_left + floor_right) * 0.5, 690.0)
	world.add_child(floor_body)
	return world


func _make_target(world: Node2D, x: float) -> Node2D:
	# Un nodo en el grupo "player" basta para que la babosa lo use de objetivo.
	var target := Node2D.new()
	target.add_to_group("player")
	target.position = Vector2(x, 616.0)
	world.add_child(target)
	return target


func _make_slug(world: Node2D, x: float, double: bool) -> SlugEnemy:
	var slug: SlugEnemy = SLUG_SCENE.instantiate()
	slug.double_jump = double
	slug.idle_min = 0.5
	slug.idle_max = 0.8
	slug.position = Vector2(x, 624.0)
	world.add_child(slug)
	slug.seed_random(1234)
	return slug


func _run() -> void:
	# --- Jugador lejos: saltos en el sitio, alturas distintas, telegrafía.
	var world := _make_world(-4000.0, 4000.0)
	_make_target(world, 3000.0)
	var slug := _make_slug(world, 0.0, false)
	var speeds: Array[float] = []
	var horizontals: Array[float] = []
	slug.jumped.connect(func(speed: float, horizontal: float) -> void:
		speeds.append(speed)
		horizontals.append(horizontal)
	)
	await _wait_physics(20)
	_check(slug.is_in_group("enemies") and slug.is_on_floor(), "La babosa es un enemigo y se apoya en el suelo")
	_check(slug.state == SlugEnemy.State.IDLE and absf(slug.global_position.x) < 1.0, "Permanece quieta al empezar")

	var windup_frames := 0
	var longest_windup := 0
	var bursts: Array[int] = []
	var burst_jumps := 0
	var previous_state := slug.state
	var drift := 0.0
	for _frame in 1800:
		await physics_frame
		if slug.state == SlugEnemy.State.WINDUP:
			windup_frames += 1
			longest_windup = maxi(longest_windup, windup_frames)
		else:
			windup_frames = 0
		if slug.state == SlugEnemy.State.IDLE:
			drift = maxf(drift, absf(slug.velocity.x))
		if previous_state == SlugEnemy.State.LANDING and slug.state == SlugEnemy.State.IDLE:
			bursts.append(speeds.size() - burst_jumps)
			burst_jumps = speeds.size()
		previous_state = slug.state
	_check(speeds.size() >= 8, "Salta de vez en cuando (%d saltos)" % speeds.size())
	_check(drift == 0.0, "Entre saltos permanece quieta")
	_check(longest_windup >= 18, "Se agacha antes de saltar (%d frames de aviso)" % longest_windup)
	var distinct := {}
	for speed in speeds:
		distinct[speed] = true
	_check(distinct.size() == 3, "Usa tres alturas de salto distintas (%d)" % distinct.size())
	var repeats := 0
	for index in range(1, speeds.size()):
		if is_equal_approx(speeds[index], speeds[index - 1]):
			repeats += 1
	_check(repeats == 0, "Nunca repite la misma altura dos veces seguidas")
	var in_place := true
	for horizontal in horizontals:
		if not is_zero_approx(horizontal):
			in_place = false
	_check(in_place, "Con el jugador lejos salta en el sitio")
	var all_single := not bursts.is_empty()
	for count in bursts:
		if count != 1:
			all_single = false
	_check(all_single, "La variante normal da un solo salto por ráfaga")
	world.queue_free()
	await process_frame

	# --- Jugador cerca: salta hacia él y aterriza cerca.
	world = _make_world(-4000.0, 4000.0)
	var target := _make_target(world, 260.0)
	slug = _make_slug(world, 0.0, false)
	slug.toward_player_chance = 1.0
	# Las lambdas capturan los números por valor: los contadores van en arrays.
	var aimed_log: Array[float] = []
	var worst_error := 0.0
	slug.jumped.connect(func(_speed: float, horizontal: float) -> void:
		if slug.last_jump_was_aimed:
			aimed_log.append(horizontal)
	)
	var was_air := false
	for _frame in 600:
		await physics_frame
		if was_air and slug.state == SlugEnemy.State.LANDING and slug.last_jump_was_aimed:
			worst_error = maxf(worst_error, absf(slug.global_position.x - slug.last_target_x))
		was_air = slug.state == SlugEnemy.State.AIR
		# El objetivo se mantiene siempre por delante de la babosa.
		target.position.x = slug.global_position.x + 260.0
	var toward := aimed_log.filter(func(h: float) -> bool: return h > 0.0).size()
	_check(aimed_log.size() >= 3, "Con el jugador cerca salta hacia él (%d saltos dirigidos)" % aimed_log.size())
	_check(aimed_log.size() == toward, "Todos los saltos dirigidos van hacia el jugador")
	_check(slug.global_position.x > 400.0, "Avanza hacia el jugador (x=%.0f)" % slug.global_position.x)
	_check(worst_error < 70.0, "Aterriza cerca de la posición prevista (error %.0f px)" % worst_error)
	world.queue_free()
	await process_frame

	# --- Variante de doble salto.
	world = _make_world(-4000.0, 4000.0)
	_make_target(world, 3000.0)
	var double_slug := _make_slug(world, 0.0, true)
	var jump_log: Array[float] = []
	double_slug.jumped.connect(func(speed: float, _horizontal: float) -> void: jump_log.append(speed))
	var double_bursts: Array[int] = []
	var counted := 0
	var last_state := double_slug.state
	var idle_between := false
	for _frame in 1800:
		await physics_frame
		if last_state == SlugEnemy.State.LANDING and double_slug.state == SlugEnemy.State.IDLE:
			double_bursts.append(jump_log.size() - counted)
			counted = jump_log.size()
		if double_slug.state == SlugEnemy.State.IDLE and jump_log.size() > counted:
			idle_between = true
		last_state = double_slug.state
	var all_double := double_bursts.size() >= 3
	for count in double_bursts:
		if count != 2:
			all_double = false
	_check(all_double, "La variante da dos saltos seguidos antes de detenerse (%s)" % str(double_bursts))
	_check(not idle_between, "No se detiene entre los dos saltos")
	var body_color := (double_slug.get_node("Visual/Body") as Polygon2D).color
	_check(body_color.r > body_color.g, "La variante se distingue por su color naranja")
	world.queue_free()
	await process_frame

	# --- No se lanza a un foso.
	world = _make_world(-4000.0, 600.0)
	_make_target(world, 900.0)
	var edge_slug := _make_slug(world, 570.0, false)
	edge_slug.toward_player_chance = 1.0
	var pit_log: Array[float] = []
	edge_slug.jumped.connect(func(_speed: float, horizontal: float) -> void:
		if edge_slug.last_jump_was_aimed:
			pit_log.append(horizontal)
	)
	var fell := false
	for _frame in 600:
		await physics_frame
		if edge_slug.global_position.y > 700.0:
			fell = true
	_check(not fell, "No cae al foso aunque el jugador esté al otro lado")
	_check(pit_log.is_empty(), "Sin suelo donde aterrizar, salta en el sitio")

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
