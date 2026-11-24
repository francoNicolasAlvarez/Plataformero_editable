extends SceneTree
## Comprueba que las monedas ya no existen en ningún nivel y que la hierba
## curativa sigue recogiéndose. Ejecutar con:
## godot --headless --path . --script res://tests/pickup_smoke_test.gd

const LEVEL_PATHS := [
	"res://scenes/levels/level_one.tscn",
	"res://scenes/levels/level_two.tscn",
	"res://scenes/levels/level_three.tscn",
	"res://scenes/levels/level_four.tscn",
]
const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(
		not ResourceLoader.exists("res://scenes/pickups/coin.tscn"),
		"La escena de la moneda fue eliminada"
	)
	for path in LEVEL_PATHS:
		var level: Node = load(path).instantiate()
		root.add_child(level)
		await _wait_physics(4)
		_check(
			get_nodes_in_group("coins").is_empty(),
			"El nivel %s no tiene monedas" % level.name
		)
		level.queue_free()
		await _wait_physics(2)

	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var player: Player = level.get_node("Player")

	await _wait_physics(20)

	player.take_damage(20)
	await _wait_physics(2)
	var herb: HealingHerb = get_nodes_in_group("healing_pickups")[0]
	player.global_position = herb.global_position
	await _wait_physics(8)

	_check(player.health.current_health == 3, "La hierba curativa recupera el golpe perdido")
	_check(not is_instance_valid(herb), "La hierba desaparece al recogerse")

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
