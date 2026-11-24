extends SceneTree
## Comprueba el sombrero mejicano simplificado del dummy y el walker (domo +
## línea de ala sobre la cabeza pisable), que el jugador parado encima no
## recibe daño mientras el contacto lateral sí daña, que los enemigos son
## humanoides proporcionales (piernas, brazos y cabeza) y que ya no muestran
## barra de vida. También valida el mago azul y el arquero.
## Ejecutar con:
## godot --headless --path . --script res://tests/enemy_visual_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")
const DUMMY_SCENE := preload("res://scenes/enemies/training_dummy.tscn")

const SOMBRERO_WIDTH := 68.0

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_sombrero_geometry()
	await _test_stand_on_sombrero()
	await _test_enemy_visuals()
	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_sombrero_geometry() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var walker: WalkerEnemy = level.get_node("WalkerEnemy")
	await _wait_physics(10)

	var head := walker.get_node_or_null("HeadShape") as CollisionShape2D
	_check(head != null, "El walker tiene zona de cabeza pisable")
	if head != null:
		var rect := head.shape as RectangleShape2D
		_check(
			rect != null and is_equal_approx(rect.size.x, SOMBRERO_WIDTH),
			"La zona pisable del walker mide lo mismo que el sombrero (%d px)" % int(SOMBRERO_WIDTH)
		)
		_check(head.position.y < -24.0, "La zona pisable del walker está sobre la cabeza")

	var body_scale: Vector2 = walker.visual.scale
	_check(is_equal_approx(body_scale.x, 1.25), "Los enemigos son un 25% más grandes")
	var hat: Node2D = walker.visual.get_node("SombreroDome")
	_check(
		is_equal_approx(body_scale.x * hat.scale.x, 0.75),
		"El sombrero queda un 25% más pequeño que el cuerpo"
	)
	_check(is_equal_approx(head.position.y, -42.0), "La cabeza pisable acompaña al sombrero agrandado")

	var damage_rect := walker.damage_shape.shape as RectangleShape2D
	var damage_top: float = walker.damage_shape.position.y - damage_rect.size.y * 0.5
	_check(damage_top >= -16.0, "El área de daño del walker no cubre el sombrero")
	_check(
		walker.damage_shape.position.y + damage_rect.size.y * 0.5 >= 20.0,
		"El área de daño del walker sigue cubriendo el cuerpo"
	)
	_check(walker.get_node_or_null("HealthBar") == null, "El walker ya no muestra barra de vida")
	_check(
		walker.visual.get_node_or_null("SombreroDome") is Polygon2D,
		"El sombrero del walker es un domo simple"
	)
	_check(
		walker.visual.get_node_or_null("SombreroBrimLine") is Polygon2D,
		"El ala del sombrero es solo una línea horizontal"
	)
	level.queue_free()

	var dummy := DUMMY_SCENE.instantiate()
	root.add_child(dummy)
	await _wait_physics(2)
	_check(
		dummy.get_node_or_null("HeadShape") is CollisionShape2D,
		"El dummy también lleva sombrero pisable"
	)
	_check(
		dummy.visual.get_node_or_null("SombreroDome") is Polygon2D,
		"El sombrero del dummy tiene domo dibujado"
	)
	_check(
		dummy.visual.get_node_or_null("SombreroBrimLine") is Polygon2D,
		"El ala del sombrero del dummy es una línea simple"
	)
	_check(
		dummy.visual.get_node_or_null("SombreroBandPattern") == null,
		"El sombrero ya no lleva banda ni pompones"
	)
	_check(dummy.get_node_or_null("HealthBar") == null, "El dummy ya no muestra barra de vida")
	dummy.queue_free()


func _test_stand_on_sombrero() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var walker: WalkerEnemy = level.get_node("WalkerEnemy")
	var player: Player = level.get_node("Player")
	walker.set_physics_process(false)
	await _wait_physics(20)

	var head := walker.get_node("HeadShape") as CollisionShape2D
	var head_top: float = head.position.y - (head.shape as RectangleShape2D).size.y * 0.5
	player.global_position = walker.global_position + Vector2(0.0, head_top - 24.0 - 6.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(45)

	_check(player.is_on_floor(), "El jugador se queda de pie sobre el sombrero")
	_check(player.health.current_health == 3, "Pararse sobre el sombrero no daña al jugador")

	# El contacto lateral sigue doliendo: el sombrero no vuelve al enemigo inofensivo.
	player.health.heal(2)
	player.global_position = walker.global_position + Vector2(25.0, 0.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(6)
	_check(player.health.current_health == 2, "El contacto lateral con el walker sigue dañando")
	level.queue_free()


func _test_enemy_visuals() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var ranged: RangedEnemy = level.get_node("RangedEnemy")
	var spread: SpreadEnemy = level.get_node("SpreadEnemy")
	await _wait_physics(5)

	_check(
		ranged.visual.get_node_or_null("WizardHat") != null,
		"El enemigo a distancia es un mago con sombrero de mago"
	)
	_check(ranged.visual.get_node_or_null("Beard") != null, "El mago lleva barba")
	_check(
		ranged.visual.get_node_or_null("Staff/OrbGlow") != null,
		"El bastón del mago porta la bola de fuego"
	)
	_check(
		ranged.visual.get_node_or_null("LegLeft") != null
		and ranged.visual.get_node_or_null("ArmRight") != null,
		"El mago tiene cuerpo humano con piernas y brazos"
	)
	_check(ranged.get_node_or_null("HealthBar") == null, "El mago ya no muestra barra de vida")
	_check(
		is_equal_approx(ranged.visual.scale.x, 1.25) and is_equal_approx(spread.visual.scale.x, 1.25),
		"Mago y arquero también son un 25% más grandes"
	)
	_check(spread.visual.get_node_or_null("ArcherHood") != null, "El enemigo ráfaga es un arquero encapuchado")
	_check(spread.visual.get_node_or_null("Bow") != null, "El arquero lleva arco")
	_check(
		spread.visual.get_node_or_null("LegLeft") != null
		and spread.visual.get_node_or_null("ArmRight") != null,
		"El arquero tiene cuerpo humano con piernas y brazos"
	)
	_check(spread.get_node_or_null("HealthBar") == null, "El arquero ya no muestra barra de vida")
	level.queue_free()


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
