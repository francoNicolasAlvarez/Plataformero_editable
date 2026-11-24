extends SceneTree
## Comprueba el impulso (2026-11-18): dura la mitad, no gasta el doble salto y
## atraviesa enemigos y proyectiles sin daño (las trampas siguen dañando).
## Ejecutar con: godot --headless --path . --script res://tests/dash_pass_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_one.tscn")
const PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")
const SPIKE_SCENE := preload("res://scenes/world/spike_trap.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(10)
	var player: Player = level.get_node("Player")
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait_physics(2)

	_check(is_equal_approx(player.stats.dash_time, 0.135), "El impulso dura 0,135 s (un 25 % menos)")
	var distance := player.stats.dash_speed * player.stats.dash_time
	_check(distance > 145.0 and distance < 160.0, "El impulso recorre unos 154 px (%.0f)" % distance)

	var walker := (load("res://scenes/enemies/walker_enemy.tscn") as PackedScene).instantiate() as TrainingDummy
	level.add_child(walker)
	walker.global_position = player.global_position + Vector2(400.0, 0.0)
	await _wait_physics(3)

	var hp := player.health.current_health
	player.take_damage(1, walker)
	_check(player.health.current_health == hp - 1, "Sin impulso un enemigo hace daño")
	player._invulnerability_left = 0.0
	player.health.current_health = hp

	player._dash_time_left = 0.1
	player.take_damage(1, walker)
	_check(player.health.current_health == hp, "Durante el impulso un enemigo no hace daño")

	var projectile := PROJECTILE_SCENE.instantiate()
	level.add_child(projectile)
	projectile.global_position = player.global_position
	projectile.speed = 0.0
	await _wait_physics(3)
	_check(is_instance_valid(projectile) and player.health.current_health == hp, "El proyectil atraviesa al jugador sin dañar ni desaparecer")
	projectile.queue_free()

	var spike := SPIKE_SCENE.instantiate()
	level.add_child(spike)
	player._dash_time_left = 0.1
	player.take_damage(1, spike)
	_check(player.health.current_health == hp - 1, "Las trampas siguen dañando durante el impulso")

	player._dash_time_left = 0.0
	player._invulnerability_left = 0.0
	player.health.current_health = player.health.max_health
	player._dash_time_left = 0.1
	player.health.take_damage(9999)
	_check(player.health.is_dead, "El impulso no protege de los pozos (daño letal directo)")


	# Físicamente: con el impulso se cruza a un enemigo sólido; sin él, no.
	var blocker := (load("res://scenes/enemies/training_dummy.tscn") as PackedScene).instantiate() as TrainingDummy
	level.add_child(blocker)
	_check(blocker.intangible_during_dash, "Los enemigos tienen la propiedad intangible_during_dash")
	player._dash_time_left = 0.0
	player._intangible_left = 0.0
	player._invulnerability_left = 5.0
	player.global_position = Vector2(400.0, 600.0)
	player.velocity = Vector2.ZERO
	blocker.global_position = Vector2(470.0, 600.0)
	blocker.set_physics_process(false)
	await _wait_physics(10)
	Input.action_press("move_right")
	await _wait_physics(40)
	_check(player.global_position.x < blocker.global_position.x + 10.0, "Sin impulso el enemigo sólido bloquea al jugador")
	Input.action_press("dash")
	await _wait_physics(3)
	Input.action_release("dash")
	await _wait_physics(30)
	Input.action_release("move_right")
	_check(player.global_position.x > blocker.global_position.x + 30.0, "Con el impulso el jugador atraviesa al enemigo (x=%.0f)" % player.global_position.x)
	await _wait_physics(15)
	_check(not player.is_intangible(), "La intangibilidad termina poco después del impulso")
	_check(player.get_collision_exceptions().is_empty(), "Se retiran las excepciones de colisión al terminar")
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
