extends SceneTree
## Percepción de enemigos (2026-11-27): `EnemySenses` cachea al jugador y los
## enemigos solo empiezan un ataque cuando están dentro de la pantalla.
## Ejecutar con:
## godot --headless --path . --script res://tests/enemy_senses_smoke_test.gd

const RANGED := preload("res://scenes/enemies/ranged_enemy.tscn")
const BRUTE := preload("res://scenes/enemies/brute_enemy.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var camera := Camera2D.new()
	world.add_child(camera)
	camera.make_current()
	var target := Node2D.new()
	target.add_to_group("player")
	world.add_child(target)
	await _wait_physics(2)

	# Caché del jugador.
	_check(EnemySenses.player(world) == target, "EnemySenses encuentra al jugador")
	_check(EnemySenses.player(world) == target, "La segunda consulta usa la caché")
	var probe := Node2D.new()
	world.add_child(probe)
	var rect := EnemySenses.visible_rect(probe)
	_check(rect.size.x > 1000.0 and rect.size.y > 600.0, "El área visible es la pantalla (%s)" % rect.size)
	probe.global_position = Vector2(500.0, 0.0)
	_check(EnemySenses.on_screen(probe), "Un punto dentro de la pantalla es visible")
	probe.global_position = Vector2(700.0, 0.0)
	_check(not EnemySenses.on_screen(probe), "Un punto fuera de la pantalla no es visible")
	_check(EnemySenses.can_engage(probe, Vector2(100.0, 0.0), 430.0, 170.0) == false, "Fuera de pantalla no puede atacar aunque esté en rango")

	# Mago fuera de pantalla (por la izquierda) con el jugador dentro de su rango.
	var mage := RANGED.instantiate() as RangedEnemy
	mage.anchored = true
	world.add_child(mage)
	mage.global_position = Vector2(-680.0, 0.0)
	target.global_position = Vector2(-380.0, 0.0)
	await _wait_physics(150)
	_check(get_nodes_in_group("enemy_projectiles").is_empty(), "Un mago fuera de pantalla no dispara")

	# Al entrar en pantalla NO dispara al instante: primero el aviso.
	camera.global_position = Vector2(-300.0, 0.0)
	await _wait_physics(20)
	_check(get_nodes_in_group("enemy_projectiles").is_empty() and mage.is_telegraphing(), "Al entrar en pantalla avisa antes de disparar")
	await _wait_physics(60)  # el aviso dura 0,6 s; el orbe vive 3 s
	_check(not get_nodes_in_group("enemy_projectiles").is_empty(), "El mago visible sí dispara")
	mage.queue_free()
	for projectile in get_nodes_in_group("enemy_projectiles"):
		projectile.queue_free()
	await _wait_physics(2)

	# Bruto fuera de pantalla por debajo (cámara que sigue en vertical).
	camera.global_position = Vector2.ZERO
	var brute := BRUTE.instantiate() as BruteEnemy
	brute.gravity = 0.0  # Sin suelo en el test: que no caiga.
	world.add_child(brute)
	brute.global_position = Vector2(0.0, 560.0)
	target.global_position = Vector2(300.0, 340.0)
	await _wait_physics(330)
	_check(get_nodes_in_group("thrown_boulders").is_empty() and _count_boulders(world) == 0, "Un bruto fuera de pantalla no lanza peñascos")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _count_boulders(node: Node) -> int:
	return node.find_children("*", "ThrownBoulder", true, false).size()


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
