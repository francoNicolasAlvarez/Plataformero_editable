extends SceneTree
## Comprueba el enemigo volador (2026-11-13): cruza en horizontal, ondula en
## vertical, no usa gravedad ni colisión con el mundo y se autodestruye al
## salir por el borde visible en su dirección (2026-11-16).
## Ejecutar con:
## godot --headless --path . --script res://tests/flying_enemy_smoke_test.gd

const ENEMY_SCENE := preload("res://scenes/enemies/flying_enemy.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var camera := Camera2D.new()
	camera.position = Vector2(500.0, 300.0)
	root.add_child(camera)
	camera.make_current()
	await _wait_physics(1)

	var enemy := ENEMY_SCENE.instantiate() as FlyingEnemy
	_check(is_equal_approx(enemy.wave_amplitude, 84.0), "La onda vertical tiene el doble de amplitud")
	_check(is_equal_approx(enemy.wave_frequency, 4.4), "La onda vertical es el doble de rápida")
	enemy.position = Vector2(100.0, 300.0)
	enemy.horizontal_speed = 200.0
	enemy.wave_amplitude = 84.0
	enemy.wave_frequency = 4.4
	enemy.despawn_margin = 0.0
	enemy.direction = 1
	root.add_child(enemy)
	await _wait_physics(2)

	_check(enemy is FlyingEnemy, "La escena crea un FlyingEnemy")
	_check(enemy is TrainingDummy, "El volador reutiliza la base de enemigos")
	_check(enemy.is_in_group("flying_enemies"), "El volador se registra en el grupo flying_enemies")
	_check(enemy.collision_mask == 0, "El volador no colisiona con el mundo")
	_check(enemy.damage_area.collision_mask == 2, "El área de daño detecta al jugador")
	_check(enemy.contact_damage > 0, "El volador hace daño por contacto")

	var start_position := enemy.position
	await _wait_physics(18)
	_check(enemy.position.x > start_position.x + 10.0, "El volador cruza la pantalla en horizontal")
	_check(absf(enemy.position.y - start_position.y) > 3.0, "El volador ondula en vertical")

	enemy.direction = -1
	var turn_position := enemy.position
	await _wait_physics(15)
	_check(enemy.position.x < turn_position.x - 5.0, "La dirección del volador se puede invertir")

	var center := camera.get_screen_center_position()
	var half_width := root.get_visible_rect().size.x * 0.5 / camera.zoom.x
	enemy.position = Vector2(center.x + half_width + 5.0, 300.0)
	enemy.direction = 1
	await _wait_physics(4)
	_check(
		not is_instance_valid(enemy),
		"El volador se autodestruye al salir por el borde visible en su dirección"
	)

	var left_enemy := ENEMY_SCENE.instantiate() as FlyingEnemy
	left_enemy.position = Vector2(center.x - half_width - 5.0, 300.0)
	left_enemy.direction = -1
	left_enemy.despawn_margin = 0.0
	root.add_child(left_enemy)
	await _wait_physics(4)
	_check(not is_instance_valid(left_enemy), "El volador también desaparece por el borde izquierdo")

	var extra_a := ENEMY_SCENE.instantiate() as FlyingEnemy
	extra_a.position = Vector2(300.0, 300.0)
	root.add_child(extra_a)
	var extra_b := ENEMY_SCENE.instantiate() as FlyingEnemy
	extra_b.position = Vector2(360.0, 320.0)
	root.add_child(extra_b)
	await _wait_physics(2)
	FlyingSpawner.clear_flying_enemies(self)
	await _wait_physics(2)
	_check(
		get_nodes_in_group("flying_enemies").is_empty(),
		"Los enemigos voladores pueden eliminarse todos al morir el jugador"
	)

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
