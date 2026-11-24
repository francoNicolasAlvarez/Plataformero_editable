extends SceneTree
## Prueba los acabados visuales añadidos el 2026-11-11: vestido de
## plataformas, sombra y squash & stretch del jugador, chispas de la hierba, aura del portal y capas de paralaje en los tres niveles.
## Desde el 2026-11-16 también valida los contornos negros de plataformas,
## pinchos, controles, portal y sierras, y la textura procedural sutil de las
## plataformas fijas y móviles.
## Ejecutar con:
## godot --headless --path . --script res://tests/visual_polish_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")
const LEVEL_TWO_SCENE := preload("res://scenes/levels/level_two.tscn")
const LEVEL_THREE_SCENE := preload("res://scenes/levels/level_three.tscn")
const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/world/moving_platform.tscn")
const SPIKE_SCENE := preload("res://scenes/world/spike_trap.tscn")
const SAW_SCENE := preload("res://scenes/world/saw_trap.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/world/checkpoint.tscn")
const PORTAL_SCENE := preload("res://scenes/world/exit_portal.tscn")
const HERB_SCENE := preload("res://scenes/pickups/healing_herb.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_platform_dressing()
	await _test_shape_outlines()
	await _test_player_polish()
	await _test_pickup_sparkles()
	await _test_portal_aura()
	await _test_level_parallax()
	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_platform_dressing() -> void:
	var platform: Platform = PLATFORM_SCENE.instantiate()
	platform.platform_size = Vector2(200.0, 24.0)
	root.add_child(platform)
	await _wait_physics(2)

	var top := platform.get_node_or_null("TopHighlight") as Polygon2D
	var bottom := platform.get_node_or_null("BottomShadow") as Polygon2D
	_check(top != null, "Las plataformas tienen franja iluminada arriba")
	_check(bottom != null, "Las plataformas tienen sombra en la base")
	if top != null:
		_check(
			top.color.v > platform.platform_color.v,
			"La franja superior aclara el color base"
		)
	if bottom != null:
		_check(
			bottom.color.a < 1.0,
			"La sombra de la base es translǧcida"
		)

	var texture := platform.get_node_or_null("TextureDetail") as Node2D
	_check(texture != null, "La plataforma tiene textura procedural")
	if texture != null:
		_check(texture.get_child_count() >= 3, "La textura dibuja vetas y motas")
		var outline := platform.get_node_or_null("Outline") as Line2D
		_check(
			outline != null and texture.get_index() < outline.get_index(),
			"La textura queda bajo el contorno de la plataforma"
		)
		var first_vein := texture.get_node_or_null("Vein0") as Line2D
		_check(
			first_vein != null and first_vein.default_color.a < 0.5,
			"La textura de la plataforma es sutil"
		)
		if first_vein != null:
			_check(
				is_equal_approx(first_vein.points[1].x, 96.0),
				"La textura sigue el ancho de la plataforma"
			)

	var moving := MOVING_PLATFORM_SCENE.instantiate()
	root.add_child(moving)
	await _wait_physics(2)
	var moving_texture := moving.get_node_or_null("TextureDetail") as Node2D
	_check(moving_texture != null, "La plataforma móvil tiene textura procedural")
	if moving_texture != null:
		var moving_outline := moving.get_node_or_null("Outline") as Line2D
		_check(
			moving_outline != null and moving_texture.get_index() < moving_outline.get_index(),
			"La textura de la plataforma móvil queda bajo el contorno"
		)
	moving.queue_free()
	platform.queue_free()


func _test_shape_outlines() -> void:
	var platform: Platform = PLATFORM_SCENE.instantiate()
	platform.platform_size = Vector2(200.0, 24.0)
	root.add_child(platform)
	await _wait_physics(2)
	var platform_outline := platform.get_node_or_null("Outline") as Line2D
	_check_outline(platform_outline, "La plataforma")
	if platform_outline != null:
		_check(
			is_equal_approx(platform_outline.points[1].x, 100.0),
			"El contorno de la plataforma sigue su tamaño"
		)
	platform.queue_free()

	var moving := MOVING_PLATFORM_SCENE.instantiate()
	root.add_child(moving)
	await _wait_physics(2)
	_check_outline(moving.get_node_or_null("Outline") as Line2D, "La plataforma móvil")
	moving.queue_free()

	var spike := SPIKE_SCENE.instantiate()
	root.add_child(spike)
	await _wait_physics(2)
	_check_outline(spike.get_node_or_null("Outline") as Line2D, "Los pinchos")
	spike.queue_free()

	var checkpoint := CHECKPOINT_SCENE.instantiate()
	root.add_child(checkpoint)
	await _wait_physics(2)
	_check_outline(checkpoint.get_node_or_null("Visual/Base/Outline") as Line2D, "La base del control")
	_check_outline(checkpoint.get_node_or_null("Visual/Pole/Outline") as Line2D, "El mástil del control")
	_check_outline(checkpoint.get_node_or_null("Visual/Flag/Outline") as Line2D, "La bandera del control")
	checkpoint.queue_free()

	var portal := PORTAL_SCENE.instantiate()
	root.add_child(portal)
	await _wait_physics(2)
	_check_outline(portal.get_node_or_null("Visual/Outer/Outline") as Line2D, "El borde exterior del portal")
	_check_outline(portal.get_node_or_null("Visual/Middle/Outline") as Line2D, "El anillo medio del portal")
	_check_outline(portal.get_node_or_null("Visual/Core/Outline") as Line2D, "El núcleo del portal")
	portal.queue_free()

	var saw := SAW_SCENE.instantiate()
	root.add_child(saw)
	await _wait_physics(2)
	_check_outline(saw.get_node_or_null("Visual/Wheel/Outline") as Line2D, "La sierra")
	_check_outline(saw.get_node_or_null("Visual/Core/Outline") as Line2D, "El eje de la sierra")
	saw.queue_free()


func _check_outline(outline: Line2D, label: String) -> void:
	_check(outline != null, "%s: tiene contorno" % label)
	if outline == null:
		return
	_check(outline.closed, "%s: contorno cerrado" % label)
	_check(
		outline.default_color.is_equal_approx(Color(0.0, 0.0, 0.0, 1.0)),
		"%s: contorno negro" % label
	)


func _test_player_polish() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var player: Player = level.get_node("Player")
	# Se espera a que el jugador aterrice del spawn y su squash inicial se
	# recupere por completo antes de forzar otro.
	await _wait_physics(30)

	_check(player.get_node_or_null("Shadow") is Polygon2D, "El jugador tiene sombra en los pies")
	var dust := player.get_node_or_null("DustPuff") as CPUParticles2D
	_check(dust != null, "El jugador tiene polvo de partículas")
	if dust != null:
		_check(dust.one_shot, "El polvo del jugador es de un solo disparo")

	player._squash(Vector2(1.4, 0.6), 0.05)
	await _wait_physics(20)
	_check(
		player.visual_root.scale.is_equal_approx(Vector2.ONE),
		"El squash & stretch recupera la escala original"
	)
	level.queue_free()


func _test_pickup_sparkles() -> void:
	var herb: HealingHerb = HERB_SCENE.instantiate()
	root.add_child(herb)
	await _wait_physics(2)
	_check(
		herb.visual.get_node_or_null("Sparkle") is CPUParticles2D,
		"La hierba curativa destella partículas"
	)
	herb.queue_free()


func _test_portal_aura() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(2)
	var portal := level.get_node("ExitPortal")
	_check(
		portal.get_node_or_null("PortalAura") is CPUParticles2D,
		"El portal tiene aura de partículas"
	)
	level.queue_free()


func _test_level_parallax() -> void:
	var level_one := LEVEL_SCENE.instantiate()
	root.add_child(level_one)
	await _wait_physics(2)

	var hills := level_one.get_node("BackgroundDecor") as Parallax2D
	_check(hills != null, "Las colinas del nivel 1 usan Parallax2D")
	if hills != null:
		_check(hills.scroll_scale.x < 1.0, "Las colinas del nivel 1 se mueven más lento que la cámara")
		_check(
			hills.get_child_count() >= 12,
			"Las colinas del nivel 1 cubren todo el recorrido"
		)

	var clouds := level_one.get_node_or_null("LevelOneExtension/CloudParallax") as Parallax2D
	_check(clouds != null, "Las nubes del nivel 1 usan Parallax2D")
	if clouds != null:
		_check(clouds.scroll_scale.x < 1.0, "Las nubes del nivel 1 se mueven más lento que la cámara")
		_check(clouds.get_child_count() >= 6, "Hay nubes repartidas por el nivel 1")
	level_one.queue_free()

	var level_two := LEVEL_TWO_SCENE.instantiate()
	root.add_child(level_two)
	await _wait_physics(2)
	var two_world := level_two.get_node("LevelTwoGenerated")
	_check(
		two_world.get_node_or_null("HillParallax") is Parallax2D,
		"Las colinas del nivel 2 usan Parallax2D"
	)
	_check(
		two_world.get_node_or_null("CloudParallax") is Parallax2D,
		"Las nubes del nivel 2 usan Parallax2D"
	)
	level_two.queue_free()

	var level_three := LEVEL_THREE_SCENE.instantiate()
	root.add_child(level_three)
	await _wait_physics(2)
	var three_world := level_three.get_node("LevelThreeGenerated")
	_check(
		three_world.get_node_or_null("StarParallax") is Parallax2D,
		"Las estrellas del nivel 3 usan Parallax2D"
	)
	_check(
		three_world.get_node_or_null("MoonParallax") is Parallax2D,
		"La luna del nivel 3 usa Parallax2D"
	)
	_check(
		three_world.get_node_or_null("HillParallax") is Parallax2D,
		"Las colinas del nivel 3 usan Parallax2D"
	)
	level_three.queue_free()


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
