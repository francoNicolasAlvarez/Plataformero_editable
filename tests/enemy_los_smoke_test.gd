extends SceneTree
## Comprueba que el enemigo a distancia dispara aunque no haya línea de visión
## (2026-11-18): una pared ya no impide el ataque.
## Ejecutar con:
## godot --headless --path . --script res://tests/enemy_los_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")
const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var ranged: RangedEnemy = level.get_node("RangedEnemy")
	var player: Player = level.get_node("Player")
	ranged.patrol_speed = 0.0

	await _wait_physics(20)

	player.global_position = ranged.global_position + Vector2(-220.0, 0.0)

	var wall: Platform = PLATFORM_SCENE.instantiate()
	wall.platform_size = Vector2(40.0, 300.0)
	wall.platform_color = Color("#3d5a80")
	wall.position = ranged.global_position + Vector2(-110.0, -60.0)
	level.add_child(wall)

	for child in level.get_children():
		if child is EnemyProjectile:
			child.free()

	await _wait_physics(120)
	ranged._shoot_cooldown = 0.0
	await _wait_physics(10)
	_check(_count_projectiles(level) >= 1, "Con una pared en medio el enemigo dispara igualmente")
	_check(is_equal_approx(ranged.shoot_interval, 3.4), "La frecuencia de disparo baja un 50 % (3,4 s)")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _count_projectiles(level: Node) -> int:
	var total := 0
	for child in level.get_children():
		if child is EnemyProjectile:
			total += 1
	return total


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
