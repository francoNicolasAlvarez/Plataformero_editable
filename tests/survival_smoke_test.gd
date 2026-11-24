extends SceneTree
## Prueba la vida del jugador, el daño por contacto de un enemigo móvil, la
## invulnerabilidad, el HUD y la pantalla de muerte.
## Ejecutar con:
## godot --headless --path . --script res://tests/survival_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	var player: Player = level.get_node("Player")
	var walker: WalkerEnemy = level.get_node("WalkerEnemy")
	var timer_label: Label = level.get_node("HUD/TimerLabel")
	var game_over: Label = level.get_node("HUD/GameOver")
	var health_icons: Label = level.get_node("HUD/HealthIcons")
	var lives_label: Label = level.get_node("HUD/LivesLabel")
	var damage_flash: ColorRect = level.get_node("HUD/DamageFlash")

	walker.set_physics_process(false)
	await _wait_physics(20)

	_check(player.health.max_health == 3, "El jugador tiene 3 golpes de vida")
	_check(player.health.current_health == 3, "El jugador empieza con los 3 golpes")
	_check(level.get_node_or_null("HUD/PlayerHealth") == null, "La barra de vida fue eliminada del HUD")
	_check(timer_label.visible and timer_label.text.begins_with("TIEMPO:"), "El HUD muestra la cuenta regresiva")
	_check(not game_over.visible, "La pantalla de muerte empieza oculta")
	_check(health_icons.text == "\u2665\u2665\u2665", "El HUD dibuja un corazón por golpe disponible")
	_check(lives_label.text.contains("3"), "El HUD muestra las tres vidas del nivel")

	player.global_position = walker.global_position + Vector2(-30.0, 0.0)
	await _wait_physics(2)

	_check(player.health.current_health == 2, "El primer golpe deja dos golpes disponibles")
	_check(health_icons.text == "\u2665\u2665\u2661", "El HUD pierde un corazón al recibir daño")
	_check(damage_flash.modulate.a > 0.5, "El daño produce un destello rojo en pantalla")
	_check(player.velocity.y < 0.0, "El daño aplica un retroceso vertical")
	_check(absf(player.velocity.x) > 100.0, "El daño empuja al jugador en horizontal")

	player.take_damage(20, walker)
	_check(player.health.current_health == 2, "La invulnerabilidad evita daño repetido")

	await _wait_physics(70)
	player.take_damage(20, walker)
	await _wait_physics(2)
	_check(player.health.current_health == 1, "El segundo golpe deja un solo golpe disponible")
	_check(not player.health.is_dead, "El jugador sigue vivo tras el segundo golpe")

	await _wait_physics(70)
	player.take_damage(20, walker)
	await _wait_physics(2)
	_check(player.health.is_dead, "El tercer golpe elimina al jugador")
	_check(game_over.visible, "Aparece el mensaje de muerte")
	_check(player.visual.animation == &"death", "El jugador reproduce la animación de muerte")

	await _wait_physics(40)
	_check(absf(player.visual.rotation) > 0.2, "El cuerpo cae de costado al morir")
	_check(player.visual.modulate.a < 0.9, "La animación de muerte se desvanece")

	await _wait_physics(40)
	_check(not player.health.is_dead, "El jugador reaparece tras unos segundos")
	_check(player.health.current_health == 3, "Reaparecer restaura los tres golpes de vida")
	_check(not game_over.visible, "El mensaje de muerte desaparece al reaparecer")
	_check(lives_label.text.contains("2"), "Morir consume una de las tres vidas")

	level._lives = 0
	player._invulnerability_left = 0.0
	player.take_damage(9999)
	await _wait_physics(2)
	_check(game_over.visible, "Sin vidas aparece el mensaje de game over")
	_check(game_over.text.contains("SIN VIDAS"), "Sin vidas se avisa del game over")
	await _wait_physics(60)
	var choice := level.get_node_or_null("HUD/GameOverChoice") as GameOverScreen
	_check(choice != null, "Sin vidas aparece la pantalla de muerte")
	var early_alpha := choice.black.modulate.a if choice != null else 0.0
	_check(early_alpha < 0.99, "La pantalla se desvanece a negro poco a poco")
	await _wait_physics(150)
	_check(choice != null and choice.black.modulate.a > 0.99, "La pantalla termina totalmente negra")
	_check(choice != null and choice.content.modulate.a > 0.99, "Después aparece el panel con las opciones")
	_check(choice != null and choice.find_child("RetryLevelButton", true, false) != null, "Se puede reintentar el nivel")
	_check(choice != null and choice.find_child("MainMenuButton", true, false) != null, "Hay opción de volver al menú principal")
	_check(choice != null and choice.find_child("QuitButton", true, false) != null, "Hay opción de cerrar el juego")
	# El nivel base es el 1, primer nivel de su grupo: no hay reinicio de grupo ni "volver al nivel 1".
	_check(choice != null and choice.find_child("RestartGroupButton", true, false) == null, "En el primer nivel del grupo no se ofrece reiniciar el grupo")
	_check(choice != null and choice.find_child("FirstLevelButton", true, false) == null, "En la zona 1 no se ofrece volver a la zona 1")
	var late := GameOverScreen.new()
	late.build("2-3", "Espejo", 2, 3, "01:02.34", 3)
	root.add_child(late)
	_check(late.find_child("FirstLevelButton", true, false) != null, "En una zona avanzada se ofrece volver a la zona 1")
	_check(late.find_child("RestartGroupButton", true, false) != null, "En un nivel avanzado se ofrece reiniciar el grupo")
	_check((late.find_child("RetryLevelButton", true, false) as Button).text == "REINTENTAR NIVEL 2-3", "El botón de reintentar nombra el nivel por zona y número")
	_check((late.find_child("RestartGroupButton", true, false) as Button).text == "VOLVER A EMPEZAR ZONA 2", "El botón de reiniciar nombra la zona")
	_check((late.find_child("FirstLevelButton", true, false) as Button).text == "VOLVER A ZONA 1", "El botón de volver a la zona 1")
	_check((late.find_child("SubtitleLabel", true, false) as Label).text.contains("nivel 2-3"), "El subtítulo usa el código zona-nivel")
	var fired := [false]
	late.first_level_requested.connect(func() -> void: fired[0] = true)
	(late.find_child("FirstLevelButton", true, false) as Button).pressed.emit()
	_check(fired[0], "El botón de volver a la zona 1 emite su señal")
	late.queue_free()
	_check(level.first_level_of_group() == 1, "El grupo del nivel 1 empieza en el nivel 1")
	level.level_variant = 4
	_check(level.first_level_of_group() == 1, "El grupo del nivel 4 empieza en el nivel 1")
	level.level_variant = 8
	_check(level.first_level_of_group() == 6, "El grupo del nivel 8 empieza en el nivel 6")
	level.level_variant = 1

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
