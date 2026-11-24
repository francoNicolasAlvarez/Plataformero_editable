extends SceneTree
## Comprueba las señales de ataque (2026-11-18): el mago acumula energía en el
## bastón, el arquero tensa el arco con la flecha encajada, el centinela cierra
## tres círculos (rápido, medio, lento) sobre el ojo antes de disparar y el
## bruto tiene la roca a los pies y tiembla antes de lanzarla.
## Ejecutar con:
## godot --headless --path . --script res://tests/attack_telegraph_smoke_test.gd

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const MAGE_SCENE := preload("res://scenes/enemies/ranged_enemy.tscn")
const ARCHER_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")
const BRUTE_SCENE := preload("res://scenes/enemies/brute_enemy.tscn")
const SENTRY_SCENE := preload("res://scenes/enemies/sky_sentry.tscn")

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
	rectangle.size = Vector2(4000.0, 100.0)
	shape.shape = rectangle
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 690.0)
	world.add_child(floor_body)
	return world


func _make_player(world: Node2D, position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	world.add_child(player)
	player.set_physics_process(false)
	return player


func _run() -> void:
	# --- Mago: luz de carga sobre el bastón.
	var world := _make_world()
	var player := _make_player(world, Vector2(240.0, 592.0))
	var mage: RangedEnemy = MAGE_SCENE.instantiate()
	mage.position = Vector2(0.0, 608.0)
	mage.set_physics_process(false)
	world.add_child(mage)
	await _wait_physics(3)
	var charge := mage.get_node_or_null("Visual/Staff/EnergyCharge") as EnergyCharge
	var orb_glow := mage.get_node("Visual/Staff/OrbGlow") as Polygon2D
	_check(charge != null, "El mago tiene un efecto de luz de carga en el bastón")
	mage._shoot_cooldown = 2.0
	await _wait_physics(5)
	_check(not charge.active and not mage.is_telegraphing(), "El mago no acumula energía con mucho tiempo de espera")
	mage._shoot_cooldown = 0.5
	await _wait_physics(4)
	var early_glow := orb_glow.scale.x
	_check(charge.active and mage.is_telegraphing(), "El mago acumula energía antes de disparar")
	mage._shoot_cooldown = 0.12
	await _wait_physics(2)
	_check(charge.progress > 0.6 and orb_glow.scale.x > early_glow, "La carga crece hasta el disparo (%.2f)" % charge.progress)
	await _wait_physics(30)
	_check(not charge.active and is_equal_approx(orb_glow.scale.x, 1.0), "La luz se apaga al disparar")
	world.queue_free()
	await process_frame

	# --- Arquero: arco tensado con la flecha encajada.
	world = _make_world()
	player = _make_player(world, Vector2(240.0, 592.0))
	var archer: SpreadEnemy = ARCHER_SCENE.instantiate()
	archer.position = Vector2(0.0, 608.0)
	archer.set_physics_process(false)
	world.add_child(archer)
	await _wait_physics(3)
	var arrow := archer.get_node_or_null("Visual/Bow/NockedArrow") as Node2D
	var string := archer.get_node("Visual/Bow/BowString") as Polygon2D
	_check(arrow != null and not arrow.visible, "El arquero tiene una flecha encajada oculta")
	var rest_pull := string.polygon[1].x
	archer._shoot_cooldown = 0.55
	await _wait_physics(3)
	var early_x := arrow.position.x
	_check(arrow.visible, "La flecha aparece en el arco al preparar el disparo")
	archer._shoot_cooldown = 0.1
	await _wait_physics(2)
	_check(arrow.position.x < early_x - 2.0, "La flecha se retrae al tensar el arco")
	_check(string.polygon[1].x < rest_pull - 3.0, "La cuerda se tensa hacia atrás")
	await _wait_physics(30)
	_check(not arrow.visible and is_equal_approx(string.polygon[1].x, rest_pull), "La flecha sale y la cuerda vuelve a reposo")
	world.queue_free()
	await process_frame

	# --- Centinela: tres círculos a tres velocidades.
	world = _make_world()
	var sentry: SkySentry = SENTRY_SCENE.instantiate()
	world.add_child(sentry)
	await _wait_physics(3)
	var rings := sentry.get_node_or_null("ChargeRings") as SentryRings
	_check(rings != null, "El centinela tiene tres círculos de carga")
	sentry._cooldown = 3.0
	await _wait_physics(3)
	_check(not rings.active, "Los círculos no aparecen antes de tiempo")
	sentry._cooldown = SentryRings.total_time() - 0.1
	await _wait_physics(2)
	_check(rings.active and sentry.is_charging(), "Los círculos aparecen al empezar la carga")
	rings.set_elapsed(0.3)
	_check(rings.ring_radius(0) < rings.ring_radius(1) and rings.ring_radius(1) < rings.ring_radius(2), "A los 0,3 s el rápido se ha encogido más que el medio y éste más que el lento")
	rings.set_elapsed(0.5)
	_check(rings.is_closed(0) and not rings.is_closed(1) and not rings.is_closed(2), "A los 0,5 s solo el rápido se ha cerrado")
	rings.set_elapsed(0.9)
	_check(rings.is_closed(0) and rings.is_closed(1) and not rings.is_closed(2), "A los 0,9 s se han cerrado el rápido y el medio")
	rings.set_elapsed(SentryRings.total_time())
	_check(rings.is_closed(2) and is_equal_approx(rings.ring_radius(2), SentryRings.END_RADIUS), "Al cerrarse el lento envuelve el ojo")
	player = _make_player(world, Vector2(-300.0, 592.0))
	var children_before := world.get_child_count()
	sentry._cooldown = 0.01
	await _wait_physics(4)
	_check(not rings.active, "Los círculos desaparecen al disparar")
	_check(world.get_child_count() > children_before, "Al cerrarse los tres círculos dispara los proyectiles")
	world.queue_free()
	await process_frame

	# --- Bruto: roca a los pies y temblor.
	world = _make_world()
	player = _make_player(world, Vector2(300.0, 592.0))
	var brute: BruteEnemy = BRUTE_SCENE.instantiate()
	brute.position = Vector2(0.0, 608.0)
	world.add_child(brute)
	await _wait_physics(3)
	var rock := brute.get_node_or_null("Visual/FeetRock") as Node2D
	_check(rock != null and not rock.visible, "El bruto tiene una roca a sus pies, oculta mientras no lanza")
	brute._cooldown = 3.0
	await _wait_physics(5)
	_check(not brute.is_telegraphing() and is_zero_approx(brute.visual.position.x), "El bruto no tiembla con mucho tiempo de espera")
	brute._cooldown = 0.6
	var max_shake := 0.0
	for _frame in 20:
		await physics_frame
		max_shake = maxf(max_shake, absf(brute.visual.position.x))
	_check(rock.visible and brute.is_telegraphing(), "La roca aparece a sus pies antes de lanzar")
	_check(max_shake > 0.5, "El bruto tiembla antes de lanzar (%.1f px)" % max_shake)
	await _wait_physics(60)
	_check(not rock.visible and is_zero_approx(brute.visual.position.x), "Al lanzar la roca desaparece y deja de temblar")
	world.queue_free()
	await process_frame

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
