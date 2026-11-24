extends SceneTree
## Comprueba el lancero de patrulla (2026-11-17): patrulla sin caerse del
## borde, se detiene medio segundo en postura de preparación al detectar al
## jugador, da una estocada horizontal muy rápida (solo a su altura, se salta)
## y queda recuperándose; la variante estrecha apenas se mueve y llega más
## lejos. Ejecutar con:
## godot --headless --path . --script res://tests/spearman_enemy_smoke_test.gd

const SPEARMAN_SCENE := preload("res://scenes/enemies/spearman_enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _make_world(left: float, right: float) -> Node2D:
	var world := Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(right - left, 100.0)
	shape.shape = rectangle
	floor_body.add_child(shape)
	floor_body.position = Vector2((left + right) * 0.5, 690.0)
	world.add_child(floor_body)
	return world


func _make_player(world: Node2D, position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	world.add_child(player)
	player.set_physics_process(false)
	return player


func _run() -> void:
	# --- Patrulla en una plataforma de 400 px sin caerse.
	var world := _make_world(-200.0, 200.0)
	var spearman: SpearmanEnemy = SPEARMAN_SCENE.instantiate()
	spearman.position = Vector2(0.0, 610.0)
	world.add_child(spearman)
	await _wait_physics(10)
	_check(spearman.is_in_group("enemies") and spearman.is_on_floor(), "El lancero es un enemigo y se apoya en el suelo")
	var min_x := 0.0
	var max_x := 0.0
	var fell := false
	for _frame in 600:
		await physics_frame
		min_x = minf(min_x, spearman.global_position.x)
		max_x = maxf(max_x, spearman.global_position.x)
		if spearman.global_position.y > 700.0:
			fell = true
	_check(max_x - min_x > 100.0, "Patrulla de un extremo al otro (%.0f px)" % (max_x - min_x))
	_check(not fell and min_x > -200.0 and max_x < 200.0, "No se cae por el borde de la plataforma")
	_check(spearman.state == SpearmanEnemy.State.PATROL, "Sin jugador cerca sigue patrullando")
	world.queue_free()
	await process_frame

	# --- Ciclo: preparación 0,5 s -> estocada -> recuperación.
	world = _make_world(-1000.0, 1000.0)
	spearman = SPEARMAN_SCENE.instantiate()
	spearman.position = Vector2(0.0, 610.0)
	world.add_child(spearman)
	var player := _make_player(world, Vector2(110.0, 616.0))
	var counts := {SpearmanEnemy.State.WINDUP: 0, SpearmanEnemy.State.THRUST: 0, SpearmanEnemy.State.RECOVER: 0}
	var spear_back := 0.0
	var spear_front := 0.0
	var order: Array[int] = []
	var hp_before := player.health.current_health
	var sweep_start := 999.0
	var sweep_end := 0.0
	var damage_during_recover := false
	var thrust_seen := false
	for _frame in 260:
		await physics_frame
		var state := spearman.state
		if counts.has(state):
			counts[state] += 1
		if order.is_empty() or order[order.size() - 1] != state:
			order.append(state)
		var spear := spearman.get_node("Visual/Spear") as Node2D
		if state == SpearmanEnemy.State.WINDUP:
			spear_back = minf(spear_back, spear.position.x)
		if state == SpearmanEnemy.State.THRUST:
			thrust_seen = true
			spear_front = maxf(spear_front, spear.position.x)
			if sweep_start == 999.0:
				sweep_start = spear.rotation_degrees
			sweep_end = spear.rotation_degrees
		if state == SpearmanEnemy.State.RECOVER and thrust_seen and player.health.current_health < hp_before - 1:
			damage_during_recover = true
		# Solo se mide el primer ciclo completo.
		if order.size() >= 4 and state == SpearmanEnemy.State.PATROL:
			break
	_check(counts[SpearmanEnemy.State.WINDUP] >= 28 and counts[SpearmanEnemy.State.WINDUP] <= 33, "Se prepara durante medio segundo (%d frames)" % counts[SpearmanEnemy.State.WINDUP])
	_check(counts[SpearmanEnemy.State.THRUST] >= 5 and counts[SpearmanEnemy.State.THRUST] <= 12, "La estocada es muy rápida (%d frames)" % counts[SpearmanEnemy.State.THRUST])
	_check(counts[SpearmanEnemy.State.RECOVER] >= 50, "Después queda recuperándose (%d frames)" % counts[SpearmanEnemy.State.RECOVER])
	_check(order.size() >= 4 and order[1] == SpearmanEnemy.State.WINDUP and order[2] == SpearmanEnemy.State.THRUST and order[3] == SpearmanEnemy.State.RECOVER, "Orden: patrulla, preparación, estocada, recuperación")
	_check(spear_back < -10.0, "En la preparación echa la lanza hacia atrás")
	_check(spear_front > 10.0, "En la estocada adelanta la lanza")
	_check(absf(sweep_start) < 60.0 and sweep_end < -75.0, "La lanza parte hacia delante y sube hasta ~90° (%.0f° -> %.0f°)" % [sweep_start, sweep_end])
	_check(is_equal_approx(spearman.thrust_time, 0.1), "El barrido dura 0,1 s")
	_check(player.health.current_health == hp_before - 1, "La estocada quita un golpe al jugador a su altura")
	_check(not damage_during_recover, "Durante la recuperación no hay segundo golpe")
	_check(spearman.facing == 1, "Se gira hacia el jugador")
	world.queue_free()
	await process_frame

	# --- El abanico de 90 grados: fuera de él (muy por encima o más allá del alcance) no hay daño.
	world = _make_world(-1000.0, 1000.0)
	spearman = SPEARMAN_SCENE.instantiate()
	spearman.position = Vector2(0.0, 610.0)
	world.add_child(spearman)
	player = _make_player(world, Vector2(40.0, 690.0))
	hp_before = player.health.current_health
	await _wait_physics(160)
	_check(spearman.state != SpearmanEnemy.State.WINDUP and spearman.state != SpearmanEnemy.State.THRUST, "El lancero detecta al jugador más abajo y completa su ciclo")
	_check(player.health.current_health == hp_before, "Un jugador por debajo del abanico no recibe daño")
	player.global_position = Vector2(360.0, 592.0)
	await _wait_physics(300)
	_check(player.health.current_health == hp_before, "Un jugador más allá del alcance (%.0f px) no recibe daño" % spearman.reach)
	world.queue_free()
	await process_frame

	# --- Geometría: alcance +50 % y sector de 90 grados.
	world = _make_world(-1000.0, 1000.0)
	spearman = SPEARMAN_SCENE.instantiate()
	spearman.position = Vector2(0.0, 610.0)
	world.add_child(spearman)
	await _wait_physics(3)
	_check(is_equal_approx(SpearmanEnemy.REACH, 180.0) and is_equal_approx(SpearmanEnemy.REACH_NARROW, 225.0), "El alcance sube un 50 % (180 / 225 px)")
	var points := spearman.fan_points(spearman.reach)
	_check(points[0] == Vector2.ZERO and absf(rad_to_deg(points[1].angle()) + 90.0) < 0.1 and absf(rad_to_deg(points[points.size() - 1].angle())) < 0.1, "La estocada es un abanico de 90 grados (de la horizontal a la vertical)")
	_check(spearman.get_node_or_null("FanIndicator") != null, "El lancero tiene el indicador del abanico")
	world.queue_free()
	await process_frame

	# --- Variante estrecha: casi no patrulla y llega más lejos.
	world = _make_world(-1000.0, 1000.0)
	var narrow: SpearmanEnemy = SPEARMAN_SCENE.instantiate()
	narrow.narrow = true
	narrow.position = Vector2(0.0, 610.0)
	world.add_child(narrow)
	var normal: SpearmanEnemy = SPEARMAN_SCENE.instantiate()
	normal.position = Vector2(500.0, 610.0)
	world.add_child(normal)
	await _wait_physics(10)
	var narrow_min := 0.0
	var narrow_max := 0.0
	for _frame in 400:
		await physics_frame
		narrow_min = minf(narrow_min, narrow.global_position.x)
		narrow_max = maxf(narrow_max, narrow.global_position.x)
	_check(narrow_max - narrow_min <= 70.0, "El lancero estrecho apenas se mueve (%.0f px)" % (narrow_max - narrow_min))
	_check(narrow.reach > normal.reach, "El lancero estrecho llega más lejos con la lanza")

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
