extends SceneTree
## Comprueba el centinela del nivel 6 (2026-11-16): se mantiene en la esquina
## superior derecha, sigue a la cámara y dispara 5 proyectiles en cono
## equidistante apuntado al jugador cada 2 segundos. Ejecutar con:
## godot --headless --path . --script res://tests/sky_sentry_smoke_test.gd

const SENTRY_SCENE := preload("res://scenes/enemies/sky_sentry.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var holder := Node2D.new()
	holder.name = "Holder"
	root.add_child(holder)

	var camera := Camera2D.new()
	camera.position = Vector2(600.0, 360.0)
	holder.add_child(camera)
	camera.make_current()

	var target := Node2D.new()
	target.name = "Target"
	target.add_to_group("player")
	target.global_position = Vector2(900.0, 600.0)
	holder.add_child(target)

	var sentry := SENTRY_SCENE.instantiate() as SkySentry
	holder.add_child(sentry)
	await _wait_physics(3)

	_check(sentry.is_in_group("sky_sentries"), "El centinela se registra en su grupo")
	_check(sentry.is_in_group("enemies"), "El centinela cuenta como enemigo")
	_check(is_equal_approx(sentry.shoot_interval, 4.0 / 0.75), "El centinela dispara cada 5,33 s (frecuencia a la mitad)")
	_check(sentry.get_node("Visual").scale.x > 1.5, "El centinela del nivel 6 es más grande")

	var center := camera.get_screen_center_position()
	var half_width := root.get_visible_rect().size.x * 0.5 / camera.zoom.x
	var expected_x := center.x + half_width - sentry.right_margin
	_check(
		absf(sentry.global_position.x - expected_x) < 2.0,
		"El centinela se mantiene en la esquina superior derecha"
	)
	_check(sentry.global_position.y < 150.0, "El centinela está pegado al borde superior")

	camera.position.x = 1000.0
	await _wait_physics(12)
	center = camera.get_screen_center_position()
	expected_x = center.x + half_width - sentry.right_margin
	_check(
		absf(sentry.global_position.x - expected_x) < 2.0,
		"El centinela se mueve con la cámara manteniéndose en la esquina derecha"
	)

	sentry.bob_amplitude = 0.0
	await _wait_physics(2)
	sentry.call("_shoot_at_player")
	await _wait_physics(2)
	var projectiles: Array[EnemyProjectile] = []
	for child in holder.get_children():
		if child is EnemyProjectile:
			projectiles.append(child)
	_check(projectiles.size() == 5, "El centinela dispara 5 proyectiles a la vez")
	if projectiles.size() == 5:
		var to_target := (target.global_position - sentry.global_position).normalized()
		var angles: Array[float] = []
		for projectile in projectiles:
			angles.append(projectile.velocity.angle())
			_check(
				is_equal_approx(projectile.velocity.length(), sentry.projectile_speed),
				"Cada proyectil usa la velocidad del centinela"
			)
			_check(projectile.is_sentry_style(), "El ataque del centinela usa el estilo rojo")
			_check(
				String(projectile.sprite.texture.resource_path).ends_with("sentry_bolt.svg"),
				"El proyectil del centinela usa la textura roja"
			)
		_check(
			projectiles[0].impact_color.r > 0.9 and projectiles[0].impact_color.g < 0.5,
			"El estallido del centinela es rojo"
		)
		var trail := projectiles[0].get_node_or_null("FlameTrail") as CPUParticles2D
		if trail != null and trail.color_ramp != null:
			_check(
				trail.color_ramp.colors[1].r > 0.9 and trail.color_ramp.colors[1].g < 0.5,
				"La estela del centinela es roja"
			)
		angles.sort()
		var center_index := 2
		var center_dot := Vector2(cos(angles[center_index]), sin(angles[center_index])).dot(to_target)
		_check(center_dot > 0.98, "El cono de disparo está centrado en el jugador")
		var step := angles[1] - angles[0]
		_check(step > 0.01, "Los proyectiles están separados en el cono")
		var evenly_spaced := true
		for index in range(1, angles.size() - 1):
			if absf((angles[index + 1] - angles[index]) - step) > 0.02:
				evenly_spaced = false
				break
		_check(evenly_spaced, "Los 5 proyectiles se reparten de forma equidistante")

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
