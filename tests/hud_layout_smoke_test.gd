extends SceneTree
## Prueba el rediseño del HUD: barra superior con la información del jugador y
## del nivel, franja inferior con avisos y área central libre.
## Ejecutar con:
## godot --headless --path . --script res://tests/hud_layout_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/level_three.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(10)
	var hud := level.get_node("HUD")

	var top: Rect2 = Rect2(0.0, 0.0, HudLayout.SCREEN.x, HudLayout.TOP_BAR_HEIGHT)
	var bottom: Rect2 = Rect2(0.0, HudLayout.SCREEN.y - HudLayout.BOTTOM_BAR_HEIGHT, HudLayout.SCREEN.x, HudLayout.BOTTOM_BAR_HEIGHT)
	var screen: Rect2 = Rect2(Vector2.ZERO, HudLayout.SCREEN)

	_check(hud.get_node_or_null("TopBar") != null and hud.get_node_or_null("BottomBar") != null, "Existen la barra superior y la franja inferior")
	_check(hud.get_node_or_null("LevelInfo") != null and hud.get_node("LevelInfo").text.contains("NIVEL"), "La barra superior muestra el nivel")

	for node_name in ["HealthIcons", "LivesLabel", "TimerLabel", "LevelProgress", "LevelInfo", "MedalLabel"]:
		var control := hud.get_node(node_name) as Control
		_check(top.encloses(control.get_rect()), "%s está dentro de la barra superior" % node_name)
	for node_name in ["PortalHint"]:
		var control := hud.get_node(node_name) as Control
		_check(bottom.encloses(control.get_rect()), "%s está dentro de la franja inferior" % node_name)

	# Información del jugador a la izquierda, del nivel a la derecha.
	_check(hud.get_node("HealthIcons").get_rect().position.x < 60.0, "Los corazones están en el extremo izquierdo")
	_check(hud.get_node("LevelInfo").get_rect().end.x > screen.size.x - 40.0, "El nivel está en el extremo derecho")
	_check(hud.get_node("TimerLabel").get_rect().get_center().x > 480.0 and hud.get_node("TimerLabel").get_rect().get_center().x < 672.0, "La cuenta regresiva queda centrada")

	# Ningún elemento permanente invade el área central.
	var play := HudLayout.play_area()
	var intruders := 0
	for child in hud.get_children():
		var control := child as Control
		if control == null or not control.visible or control.name in ["DamageFlash", "TopBar", "BottomBar", "LevelBanner"]:
			continue
		if control.get_rect().intersects(play):
			intruders += 1
			print("   invade el área central: ", control.name)
	_check(intruders == 0, "El área central no tiene elementos permanentes del HUD")
	_check(play.size.y > 550.0, "El área de juego conserva más de 550 px de alto")

	# Tamaños reducidos.
	_check(hud.get_node("TimerLabel").get_theme_font_size("font_size") <= 20, "La cuenta regresiva es más pequeña")
	_check(hud.get_node("MedalLabel").get_theme_font_size("font_size") <= 12, "La medalla es más pequeña")

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
