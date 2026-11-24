extends SceneTree
## Comprueba los controles (checkpoints) del modo plataformas: activación,
## curación completa, punto de reaparición y consumo de una vida al morir.
## Ejecutar con:
## godot --headless --path . --script res://tests/checkpoint_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	var lives_label: Label = level.get_node("HUD/LivesLabel")

	await _wait_physics(20)

	var checkpoints := get_nodes_in_group("checkpoints")
	_check(checkpoints.size() == 1, "El nivel 1 tiene un único control a mitad del recorrido")
	_check(lives_label.text.contains("3"), "El nivel empieza con tres vidas")

	var checkpoint := checkpoints[0] as Checkpoint
	_check(not checkpoint.is_active, "El control empieza inactivo")

	player.take_damage(20)
	await _wait_physics(2)
	_check(player.health.current_health == 2, "El jugador recibe daño antes del control")

	player.global_position = checkpoint.global_position
	await _wait_physics(10)
	_check(checkpoint.is_active, "Pisar la bandera activa el control")
	_check(player.health.current_health == 3, "El control cura toda la vida")
	var rest_banner: Label = level.get_node_or_null("HUD/CheckpointBanner")
	_check(rest_banner != null and rest_banner.text.contains("DESCANSO"),
		"El control muestra un aviso de descanso")

	await _wait_physics(70)
	level._timer.set_remaining(12.0)
	player.take_damage(9999)
	await _wait_until_alive(player)

	_check(not player.health.is_dead, "Tras morir el jugador reaparece")
	_check(player.health.current_health == 3, "Reaparece con la vida completa")
	_check(lives_label.text.contains("2"), "La muerte consume una vida")
	_check(
		absf(player.global_position.x - checkpoint.global_position.x) < 80.0,
		"Reaparece en el último control activado"
	)
	_check(
		level._timer.remaining >= level._timer.limit - 1.0,
		"Reaparecer reinicia la cuenta regresiva al límite completo"
	)

	await _wait_physics(70)
	level._timer.set_remaining(45.0)
	var elapsed_before: float = level._timer.elapsed
	player.take_damage(9999)
	await _wait_until_alive(player)
	_check(
		level._timer.remaining >= level._timer.limit - 1.0,
		"Cada muerte reinicia la cuenta regresiva"
	)
	_check(
		level._timer.elapsed >= elapsed_before,
		"El tiempo real de la medalla no se reinicia al morir"
	)

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _wait_until_alive(player: Player) -> void:
	for _frame in 120:
		if not player.health.is_dead:
			return
		await physics_frame


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
