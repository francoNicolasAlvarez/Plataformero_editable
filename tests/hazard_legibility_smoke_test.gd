extends SceneTree
## Comprueba la legibilidad de las trampas (2026-11-13): las sierras avisan
## parpadeando antes de moverse y los pinchos tienen un brillo pulsante.
## Ejecutar con:
## godot --headless --path . --script res://tests/hazard_legibility_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_two.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(8)

	var saws := get_nodes_in_group("saws")
	var loose_spikes: Array[Node] = []
	for spike in get_nodes_in_group("spikes"):
		if not spike.get_parent() is Platform:
			loose_spikes.append(spike)
	_check(saws.size() >= 8, "El nivel 2 tiene sierras que avisan")
	_check(loose_spikes.size() >= 5, "El nivel 2 tiene pinchos legibles sobre el suelo")

	if not saws.is_empty():
		var saw: Area2D = saws[0]
		var visual: Node2D = saw.get_node("Visual")
		_check(float(saw.get("warmup_time")) > 0.0, "La sierra define un tiempo de aviso")
		var alpha_a: float = visual.modulate.a
		await _wait_physics(3)
		var alpha_b: float = visual.modulate.a
		_check(
			not is_equal_approx(alpha_a, alpha_b) and alpha_b >= 0.5 and alpha_b <= 1.0,
			"La sierra parpadea durante el aviso"
		)
		var start_position: Vector2 = saw.position
		await _wait_physics(60)
		_check(visual.modulate.a > 0.99, "El aviso de la sierra termina")
		_check(saw.position.distance_to(start_position) > 1.0, "La sierra se mueve tras el aviso")

	if not loose_spikes.is_empty():
		var spike: Area2D = loose_spikes[0]
		var visual: Polygon2D = spike.get_node("Visual")
		var alpha_a: float = visual.modulate.a
		await _wait_physics(12)
		var alpha_b: float = visual.modulate.a
		_check(
			not is_equal_approx(alpha_a, alpha_b) and alpha_b >= 0.6 and alpha_b <= 1.0,
			"Los pinchos tienen un brillo pulsante"
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
