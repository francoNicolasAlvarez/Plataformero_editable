extends SceneTree
## Comprueba las mecánicas nuevas del mundo 5 (2026-11-23): corriente
## ascendente, plataforma temporizada, cinta transportadora, palanca y
## compuerta, prensa y baja gravedad. Ejecutar con:
## godot --headless --path . --script res://tests/world5_mechanics_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")
const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var player: Player = level.get_node("Player")
	await _wait_physics(10)
	var far := Vector2(player.global_position.x, player.global_position.y - 6000.0)

	await _test_updraft(level, player, far)
	await _test_timed_platform(level, player, far + Vector2(2000.0, 0.0))
	await _test_conveyor(level, player, far + Vector2(4000.0, 0.0))
	await _test_levers(level, player, far + Vector2(6000.0, 0.0))
	await _test_crusher(level, player, far + Vector2(8000.0, 0.0))
	_test_low_gravity(player)
	await _test_vacuum_sentry(level, player)

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_updraft(level: Node, player: Player, at: Vector2) -> void:
	var zone := UpdraftZone.new()
	zone.zone_size = Vector2(160.0, 1200.0)
	level.add_child(zone)
	zone.global_position = at
	player.health.reset()
	player.global_position = at + Vector2(0.0, 500.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(3)
	var start_y := player.global_position.y
	await _wait_physics(40)
	_check(zone.player_inside, "La corriente detecta al jugador dentro")
	_check(player.velocity.y < -150.0, "Dentro de la corriente el jugador sube (vy=%.0f)" % player.velocity.y)
	_check(player.global_position.y < start_y - 80.0, "El jugador asciende varios píxeles en 40 frames")
	player.global_position = at + Vector2(900.0, 0.0)
	await _wait_physics(5)
	_check(not zone.player_inside, "Fuera de la zona deja de empujar")
	zone.queue_free()


func _test_timed_platform(level: Node, player: Player, at: Vector2) -> void:
	var timed := TimedPlatform.new()
	timed.solid_time = 1.0
	timed.gone_time = 1.0
	level.add_child(timed)
	timed.global_position = at
	player.global_position = at + Vector2(2000.0, 0.0)
	await _wait_physics(2)
	_check(timed.is_solid(), "La plataforma temporizada empieza sólida")
	var saw_warning := false
	var saw_gone := false
	var saw_back := false
	for _frame in 300:
		await physics_frame
		saw_warning = saw_warning or timed.state == Hazard.State.WARNING
		if timed.state == Hazard.State.ACTIVE:
			saw_gone = true
			_check_once("gone_not_solid", not timed.is_solid() and timed._shape.disabled, "Mientras no está, no sostiene (colisión apagada)")
		if saw_gone and timed.state == Hazard.State.COOLDOWN:
			saw_back = true
			break
	_check(saw_warning, "Parpadea antes de desaparecer (aviso)")
	_check(saw_gone, "La plataforma desaparece")
	_check(saw_back, "La plataforma reaparece")
	timed.reset()
	_check(timed.is_solid(), "reset() la deja sólida")
	timed.queue_free()


func _test_conveyor(level: Node, player: Player, at: Vector2) -> void:
	var belt: Platform = PLATFORM_SCENE.instantiate()
	belt.platform_size = Vector2(900.0, 24.0)
	level.add_child(belt)
	belt.global_position = at
	belt.conveyor_speed = 150.0
	_check(is_equal_approx(belt.constant_linear_velocity.x, 150.0), "La cinta guarda su velocidad")
	_check(belt.get_node_or_null("ConveyorBelt") != null, "La cinta dibuja la banda animada")
	player.health.reset()
	player.global_position = at + Vector2(-300.0, -40.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(30)
	var x0 := player.global_position.x
	await _wait_physics(30)
	_check(player.is_on_floor(), "El jugador se apoya en la cinta")
	_check(player.global_position.x - x0 > 40.0, "La cinta arrastra al jugador hacia delante (%.0f px)" % (player.global_position.x - x0))
	var visual := belt.get_node_or_null("ConveyorBelt") as ConveyorVisual
	var seen := {}
	var offsets := {}
	for i in 40:
		visual._process(0.04)
		seen[visual.frame] = true
		offsets[snappedf(visual.tread_offset(), 0.01)] = true
	_check(seen.size() == ConveyorVisual.FRAME_COUNT and offsets.size() == 3, "La animación de la cinta usa 3 fotogramas distintos")
	var forward_offset := visual.tread_offset()
	belt.conveyor_speed = -150.0
	var reversed := belt.get_node_or_null("ConveyorBelt") as ConveyorVisual
	reversed.frame = 1
	_check(reversed.tread_offset() < 0.0 and forward_offset >= 0.0, "Los tacos se desplazan en el sentido de la cinta")
	belt.conveyor_speed = 0.0
	_check(belt.get_node_or_null("ConveyorBelt") == null, "Sin velocidad no hay banda")
	belt.queue_free()


func _test_levers(level: Node, player: Player, at: Vector2) -> void:
	var gate := SwitchGate.new()
	gate.channel = "T"
	level.add_child(gate)
	gate.global_position = at + Vector2(0.0, -100.0)
	var levers: Array[LeverSwitch] = []
	for i in 3:
		var lever := LeverSwitch.new()
		lever.channel = "T"
		level.add_child(lever)
		lever.global_position = at + Vector2(400.0 * float(i + 1), 0.0)
		levers.append(lever)
	await _wait_physics(3)
	_check(not gate.is_open and gate.levers().size() == 3, "La compuerta empieza cerrada y cuenta 3 palancas")
	levers[2].activate()
	levers[0].activate()
	_check(not gate.is_open and gate.active_count() == 2, "Con 2 de 3 palancas sigue cerrada (cualquier orden)")
	player.global_position = at + Vector2(400.0 * 2.0, -20.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(6)
	_check(levers[1].is_on, "Tocar la palanca la activa")
	_check(gate.is_open, "Con las 3 palancas la compuerta se abre")
	await _wait_physics(2)
	_check(gate._shape.disabled, "Abierta, la compuerta deja de bloquear")
	gate.queue_free()
	for lever in levers:
		lever.queue_free()


func _test_crusher(level: Node, player: Player, at: Vector2) -> void:
	var crusher := CrusherTrap.new()
	level.add_child(crusher)
	crusher.global_position = at
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(600.0, 40.0)
	shape.shape = rect
	floor_body.add_child(shape)
	level.add_child(floor_body)
	floor_body.global_position = at + Vector2(0.0, 300.0)
	player.health.reset()
	player.global_position = at + Vector2(0.0, 250.0)
	player.velocity = Vector2.ZERO
	var before := player.health.current_health
	await _wait_physics(8)
	_check(crusher.state == Hazard.State.WARNING, "La prensa avisa al pasar el jugador por debajo")
	await _wait_physics(30)
	_check(player.health.current_health == before, "Durante el aviso no hace daño")
	await _wait_physics(40)
	_check(player.health.current_health < before, "Después del aviso cae y daña al jugador debajo")
	crusher.reset()
	_check(crusher.state == Hazard.State.IDLE, "reset() sube la prensa")
	crusher.queue_free()
	floor_body.queue_free()


func _test_vacuum_sentry(level: Node, player: Player) -> void:
	var sentry := VacuumSentry.new()
	sentry.shoot_interval = 1.0
	sentry.suction_interval = 3.0
	sentry.suction_duration = 2.0
	level.add_child(sentry)
	player.global_position = player.global_position + Vector2(0.0, -6000.0)
	await _wait_physics(5)
	var camera := level.get_node("Camera") as Camera2D
	var screen := camera.get_screen_center_position()
	var camera_view := sentry._view_size()
	_check(sentry.global_position.x < screen.x and sentry.global_position.y > screen.y, "Centinela aspirador: abajo a la izquierda de la pantalla")
	_check(sentry.get_node("Visual").find_children("*", "Polygon2D", true, false).size() > 10, "Centinela aspirador: dibujado por código")
	var blue := false
	for polygon in sentry.get_node("Visual").get_children():
		if polygon is Polygon2D and (polygon as Polygon2D).color.is_equal_approx(VacuumSentry.BLUE):
			blue = true
	_check(blue, "Centinela aspirador: cuerpo azul")
	var projectiles_before := get_nodes_in_group("enemy_projectiles").size()
	sentry._shoot_at_player()
	_check(get_nodes_in_group("enemy_projectiles").size() - projectiles_before >= 5, "Centinela aspirador: dispara un cono de proyectiles")
	await _wait_physics(5)
	var saw_suction := false
	var peak_objects := 0
	for _frame in 400:
		await physics_frame
		if sentry.is_sucking():
			saw_suction = true
			peak_objects = maxi(peak_objects, sentry.object_count())
	_check(saw_suction, "Centinela aspirador: entra periódicamente en fase de succión")
	_check(peak_objects == 2, "Centinela aspirador: nunca más de 2 objetos a la vez (pico %d)" % peak_objects)
	_check(is_equal_approx(sentry.object_interval, 0.5) and sentry.max_objects == 2, "Centinela aspirador: un objeto cada 0,5 s")
	# Los objetos nacen por el borde derecho de la pantalla y dañan al jugador.
	sentry._start_suction()
	sentry._clear_objects()
	sentry._spawn_object()
	var spawned := sentry._objects[0]["node"] as Node2D
	var player_local_y: float = (spawned.get_parent() as Node2D).to_local(player.global_position).y
	_check(spawned.position.y <= player_local_y - 40.0 or spawned.position.y <= -(camera_view.y - sentry.bottom_margin) + 80.0, "Centinela aspirador: los objetos nacen más arriba que el jugador")
	_check(spawned.global_position.y > screen.y - camera_view.y * 0.5 - 40.0 and spawned.global_position.y < screen.y + camera_view.y * 0.5, "Centinela aspirador: los objetos nacen dentro de la pantalla visible")
	var right_screen := screen.x + camera_view.x * 0.5
	_check(spawned.global_position.x > right_screen - 40.0, "Centinela aspirador: los objetos aparecen en el extremo derecho (x=%.0f, borde=%.0f)" % [spawned.global_position.x, right_screen])
	player.health.reset()
	player._invulnerability_left = 0.0
	var hp_before := player.health.current_health
	player.set_physics_process(false)
	player.global_position = spawned.global_position
	sentry._update_objects(0.0)
	_check(player.health.current_health < hp_before, "Centinela aspirador: un objeto que toca al jugador le hace daño")
	player.set_physics_process(true)
	var kinds := {}
	sentry._start_suction()
	for _i in 30:
		sentry._spawn_object()
	for entry in sentry._objects:
		kinds[entry["kind"]] = true
	_check(kinds.size() >= 4, "Centinela aspirador: objetos variados (%d tipos)" % kinds.size())
	_check(sentry._objects.all(func(e): return e["node"].find_children("*", "Polygon2D", true, false).size() >= 2), "Centinela aspirador: cada objeto tiene su silueta")
	sentry.reset()
	await _wait_physics(2)
	_check(sentry.object_count() == 0 and not sentry.is_sucking(), "Centinela aspirador: reset() limpia la succión")
	sentry.queue_free()
	FallingRock.clear_rocks(player.get_tree())
	for projectile in get_nodes_in_group("enemy_projectiles"):
		projectile.queue_free()
	player.global_position = player.global_position + Vector2(0.0, 6000.0)


func _test_low_gravity(player: Player) -> void:
	var original_gravity := player.stats.gravity
	var original_height := player.stats.jump_height
	LevelRules.low_gravity(player)
	_check(player.stats.gravity < original_gravity * 0.6, "Baja gravedad: la gravedad baja")
	_check(player.stats.jump_height > original_height * 1.5, "Baja gravedad: el salto es más alto")
	var shared := load("res://resources/player/player_stats.tres") as PlayerStats
	_check(is_equal_approx(shared.gravity, original_gravity), "El recurso compartido de estadísticas no se modifica")


func _wait_physics(frames: int) -> void:
	for _frame in frames:
		await physics_frame


var _once: Dictionary = {}


func _check_once(key: String, condition: bool, message: String) -> void:
	if _once.has(key):
		return
	_once[key] = true
	_check(condition, message)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
