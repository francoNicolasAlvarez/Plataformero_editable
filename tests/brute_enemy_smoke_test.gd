extends SceneTree
## Comprueba el bruto lanzarrocas del nivel 9 (2026-11-17): 30 % más alto que
## los demás enemigos, lanza un peñasco a 45 grados que describe una parábola,
## rápido y de 1,5 veces el modelo del jugador, y la pila de rocas sobre la que
## se puede saltar. Ejecutar con:
## godot --headless --path . --script res://tests/brute_enemy_smoke_test.gd

const BRUTE_SCENE := preload("res://scenes/enemies/brute_enemy.tscn")
const WALKER_SCENE := preload("res://scenes/enemies/walker_enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const LEVEL_NINE := preload("res://scenes/levels/level_nine.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8000.0, 100.0)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(2000.0, 690.0)
	world.add_child(floor_body)

	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(830.0, 600.0)
	world.add_child(player)
	var brute: BruteEnemy = BRUTE_SCENE.instantiate()
	brute.position = Vector2(500.0, 608.0)
	world.add_child(brute)
	var walker: WalkerEnemy = WALKER_SCENE.instantiate()
	walker.position = Vector2(-500.0, 608.0)
	world.add_child(walker)
	await _wait_physics(30)

	# Tamaño: 30 % más alto que el resto de enemigos.
	var brute_height := (brute.get_node("CollisionShape2D").shape as RectangleShape2D).size.y
	var walker_height := (walker.get_node("CollisionShape2D").shape as RectangleShape2D).size.y
	_check(is_equal_approx(brute_height / walker_height, 1.3), "El bruto es un 30 %% más alto que los demás enemigos (%.1f vs %.1f)" % [brute_height, walker_height])
	_check(is_equal_approx(absf(brute.visual.scale.y) / absf(walker.visual.scale.y), 1.3), "Su silueta también es un 30 % mayor")
	_check(brute.is_in_group("enemies") and brute.is_on_floor(), "Es un enemigo y se apoya en el suelo")
	var red_parts := 0
	for part_name in ["Torso", "ArmLeft", "ArmRight", "Headband"]:
		var part := brute.get_node("Visual/%s" % part_name) as Polygon2D
		if part != null and part.color.r > 0.6 and part.color.g < 0.3 and part.color.b < 0.3:
			red_parts += 1
	_check(red_parts == 4, "Va vestido de rojo")
	var torso := brute.get_node("Visual/Torso") as Polygon2D
	var torso_width := torso.polygon[1].x - torso.polygon[0].x
	_check(torso_width >= 36.0, "Es fornido: torso ancho (%.0f px)" % torso_width)

	# Proyectil: ángulo de 45 grados, rápido, parábola y tamaño.
	var seen := false
	var first: ThrownBoulder = null
	var radius := 0.0
	var launch_velocity := Vector2.ZERO
	var heights: Array[float] = []
	var hp_before := player.health.current_health
	for frame in 400:
		await physics_frame
		var boulders := get_nodes_in_group("thrown_boulders")
		if not seen and not boulders.is_empty():
			seen = true
			first = boulders[0]
			launch_velocity = first.velocity
			for child in first.get_children():
				if child is CollisionShape2D:
					radius = (child.shape as CircleShape2D).radius
		if seen:
			if is_instance_valid(first):
				heights.append(first.global_position.y)
			else:
				break
	_check(seen, "El bruto lanza un proyectil al ver al jugador")
	if seen:
		var angle := rad_to_deg(atan2(-launch_velocity.y, launch_velocity.x))
		_check(absf(angle - 45.0) < 3.0, "El proyectil sale a 45 grados (%.1f°)" % angle)
		_check(launch_velocity.length() >= BruteEnemy.MIN_SPEED - 1.0, "El proyectil se mueve rápido (%.0f px/s)" % launch_velocity.length())
		_check(launch_velocity.x > 0.0, "Sale hacia el lado del jugador")
		_check(is_equal_approx(radius * 2.0, 1.5 * 48.0), "El proyectil mide 1,5 veces el modelo del jugador (72 px)")
		var apex: float = heights.min()
		var apex_index := heights.find(apex)
		_check(apex_index > 2 and apex_index < heights.size() - 2, "La trayectoria sube y luego baja: es una parábola")
		_check(apex < heights[0] - 20.0, "Alcanza una altura apreciable (%.0f px)" % (heights[0] - apex))
	_check(player.health.current_health == hp_before - 1, "El peñasco cae sobre el jugador y le quita un golpe")
	_check(get_nodes_in_group("thrown_boulders").is_empty(), "El peñasco se rompe al impactar")

	# La velocidad calculada alcanza el objetivo a distintas distancias.
	for distance in [200.0, 350.0, 500.0]:
		var origin := brute.launch_origin(1.0)
		var target := Vector2(brute.global_position.x + distance, 616.0)
		var speed := brute.compute_launch_speed(origin, target)
		var t := (target.x - origin.x) / (speed * cos(deg_to_rad(45.0)))
		var y := origin.y - speed * sin(deg_to_rad(45.0)) * t + 0.5 * brute.boulder_gravity * t * t
		_check(speed >= BruteEnemy.MIN_SPEED - 1.0 and absf(y - target.y) < 12.0 or speed == BruteEnemy.MIN_SPEED, "El tiro a %.0f px apunta al jugador" % distance)

	# Pila de rocas: se puede saltar sobre ella.
	var pile := RockPile.new()
	pile.position = Vector2(1400.0, 640.0)
	world.add_child(pile)
	player.global_position = Vector2(1400.0, 440.0)
	player.velocity = Vector2.ZERO
	player.health.current_health = player.health.max_health
	await _wait_physics(60)
	var pile_top := 640.0 - RockPile.total_height()
	_check(player.is_on_floor() and absf(player.global_position.y - (pile_top - 24.0)) < 4.0, "El jugador se posa sobre la pila de rocas")
	_check(RockPile.total_height() > 60.0 and RockPile.total_height() < 120.0, "La pila se puede saltar (%.0f px)" % RockPile.total_height())
	world.queue_free()
	await process_frame

	# En el nivel 9 cada bruto tiene su pila al lado.
	var level := LEVEL_NINE.instantiate()
	root.add_child(level)
	await _wait_physics(10)
	var brutes := get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e is BruteEnemy)
	_check(brutes.size() == 3, "El nivel 9 tiene tres brutos")
	for level_brute in brutes:
		var near_pile := false
		for level_pile in get_nodes_in_group("rock_piles"):
			var gap := absf(level_pile.global_position.x - level_brute.global_position.x)
			if gap > 40.0 and gap < 160.0:
				near_pile = true
		_check(near_pile, "%s está de pie junto a una pila de rocas" % level_brute.name)

	# Las rocas del bruto no se frenan contra su propia pila de rocas.
	var test_pile := RockPile.new()
	test_pile.position = Vector2(2000.0, 640.0)
	root.add_child(test_pile)
	var passing := ThrownBoulder.new()
	passing.velocity = Vector2.ZERO
	passing.fall_gravity = 0.0
	root.add_child(passing)
	passing.global_position = Vector2(2000.0, 600.0)
	await _wait_physics(10)
	_check(is_instance_valid(passing) and not passing.is_queued_for_deletion(), "El peñasco no se rompe contra la pila de rocas")
	var fresh_brute := BruteEnemy.new()
	_check(is_equal_approx(fresh_brute.throw_interval, 4.4 / 1.25), "El bruto lanza un 25 %% más a menudo (%.2f s)" % fresh_brute.throw_interval)
	fresh_brute.free()

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
