extends SceneTree
## Comprueba que el enemigo a distancia dispara proyectiles horizontales (no
## apuntan al jugador: salen hacia su lado y se esquivan cambiando de altura),
## que dañan al jugador a su misma altura, y que conserva vida y muerte del
## enemigo base.
## Rediseño 2026-11-11: el mago dispara ráfagas de 3 bolas de fuego en abanico
## (estilo FIRE con estela) y el arquero una sola flecha (estilo BOLT), algo
## más rápida y sin estela.
## Ejecutar con:
## godot --headless --path . --script res://tests/enemy_ranged_smoke_test.gd

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

	await _wait_physics(20)
	_check(ranged.is_on_floor(), "El enemigo a distancia cae sobre el suelo")
	_check(ranged.health.max_health == 40, "El enemigo a distancia tiene 40 PV")
	_check(ranged.damage_area.monitoring, "El daño por contacto sigue activo")

	# Cambio 2026-11-11: el disparo es horizontal y no apunta. Con el jugador
	# en otra altura (sobre una repisa) el proyectil pasa por debajo.
	player.global_position = ranged.global_position + Vector2(-220.0, -80.0)
	var perch: Platform = PLATFORM_SCENE.instantiate()
	perch.platform_size = Vector2(80.0, 20.0)
	perch.platform_color = Color("#3d5a80")
	perch.position = player.global_position + Vector2(0.0, 34.0)
	level.add_child(perch)
	_clear_projectiles(level)
	await _wait_physics(55)

	var high_shot := _find_projectile(level)
	_check(high_shot != null, "El enemigo dispara con el jugador en otra altura")
	if high_shot != null:
		_check(
			absf(high_shot.velocity.y) < high_shot.speed * 0.25,
			"El proyectil vuela casi horizontal sin apuntar al jugador"
		)
		_check(high_shot.velocity.x < 0.0, "El proyectil sale hacia el lado donde está el jugador")
		_check(high_shot.style == EnemyProjectile.Style.FIRE, "El mago dispara orbes de energia azul")
		_check(not high_shot.is_sentry_style(), "El mago no usa el estilo rojo del centinela")
		_check(high_shot.get_node_or_null("FlameTrail") is CPUParticles2D, "El orbe lleva estela de energia")
	_clear_projectiles(level)
	perch.free()

	# A la misma altura sí alcanza al jugador: sigue siendo peligroso.
	ranged._shoot_cooldown = 0.05
	player.global_position = ranged.global_position + Vector2(-220.0, 0.0)
	_clear_projectiles(level)
	await _wait_physics(15)

	_check(_find_projectile(level) != null, "El enemigo dispara proyectiles al detectar al jugador")
	ranged.set_process(false)

	await _wait_physics(70)
	_check(player.health.current_health == 2, "Los proyectiles consumen uno de los 3 golpes")

	# Cada disparo del mago es una ráfaga de 3 bolas de fuego en abanico.
	var mage_speed: float = ranged.projectile_speed
	_clear_projectiles(level)
	ranged._shoot(-1.0)
	await _wait_physics(2)
	var volley := _collect_projectiles(level)
	_check(volley.size() == 3, "El mago lanza 3 bolas de fuego por disparo")
	var volley_fire := true
	var volley_side := true
	var volley_up := false
	var volley_down := false
	for shot in volley:
		if shot.style != EnemyProjectile.Style.FIRE:
			volley_fire = false
		if shot.velocity.x >= 0.0:
			volley_side = false
		if shot.velocity.y < -5.0:
			volley_up = true
		if shot.velocity.y > 5.0:
			volley_down = true
	_check(volley_fire, "Toda la ráfaga del mago es de energia")
	_check(volley_side, "La ráfaga entera va hacia el lado del jugador")
	_check(volley_up and volley_down, "El abanico de orbes abre en varias alturas")
	_clear_projectiles(level)

	ranged.take_damage(ranged.health.max_health)
	await _wait_physics(30)
	_check(not is_instance_valid(ranged) or ranged.is_queued_for_deletion(), "El enemigo a distancia puede morir")

	var spread: SpreadEnemy = level.get_node("SpreadEnemy")
	_check(spread.health.max_health == 40, "El enemigo ráfaga tiene 40 PV")
	spread.set_process(false)
	spread._shoot(1.0)
	await _wait_physics(2)
	var arrows := _collect_projectiles(level)
	_check(arrows.size() == 1, "El arquero dispara una sola flecha por disparo")
	if arrows.size() == 1:
		var arrow: EnemyProjectile = arrows[0]
		_check(arrow.style == EnemyProjectile.Style.BOLT, "La flecha usa el estilo BOLT")
		_check(arrow.speed > mage_speed, "La flecha es más rápida que la bola de fuego")
		_check(absf(arrow.velocity.y) < 1.0, "La flecha vuela horizontal")
		_check(is_zero_approx(arrow.rotation), "La flecha apunta hacia donde vuela")
		_check(arrow.get_node_or_null("FlameTrail") == null, "La flecha no lleva estela de fuego")
	_clear_projectiles(level)

	spread.take_damage(spread.health.max_health)
	await _wait_physics(30)
	_check(not is_instance_valid(spread) or spread.is_queued_for_deletion(), "El enemigo ráfaga puede morir")

	var magic_sound := Sfx._get_sound("magic")
	var arrow_sound := Sfx._get_sound("arrow")
	var sentry_sound := Sfx._get_sound("sentry")
	_check(
		magic_sound != null and arrow_sound != null and sentry_sound != null,
		"Hay sonidos para magia, flechas y centinela"
	)
	_check(
		magic_sound != arrow_sound and magic_sound != sentry_sound and arrow_sound != sentry_sound,
		"Cada proyectil usa un sonido distinto"
	)

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _find_projectile(level: Node) -> EnemyProjectile:
	for child in level.get_children():
		if child is EnemyProjectile:
			return child
	return null


func _collect_projectiles(level: Node) -> Array[EnemyProjectile]:
	var found: Array[EnemyProjectile] = []
	for child in level.get_children():
		if child is EnemyProjectile:
			found.append(child)
	return found


func _clear_projectiles(level: Node) -> void:
	for child in level.get_children():
		if child is EnemyProjectile:
			child.free()


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
