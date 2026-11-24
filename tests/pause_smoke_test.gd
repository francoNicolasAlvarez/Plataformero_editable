extends SceneTree
## Comprueba la pausa con Enter (2026-11-16): congela el nivel, abre un menú
## con Continuar, Guía, Configuración, Volver al menú principal y Salir; la
## guía conserva las teclas dibujadas y Configuración replica brillo, volumen
## y controles del menú principal. Ejecutar con:
## godot --headless --path . --script res://tests/pause_smoke_test.gd

const LEVEL_SCENE := preload("res://scenes/levels/test_level.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)

	await _wait_physics(20)

	var player: Player = level.get_node("Player")
	var pause_overlay: PauseOverlay = level.get_node("PauseOverlay")
	var menu_panel: PanelContainer = pause_overlay.get_node("Center/MenuPanel")
	var guide_panel: PanelContainer = pause_overlay.get_node("Center/GuidePanel")
	var settings_panel: PanelContainer = pause_overlay.get_node("Center/SettingsPanel")
	var guide: ControlGuide = pause_overlay.get_node("Center/GuidePanel/Margin/VBox/Scroll/ControlGuide")
	var timer_label: Label = level.get_node("HUD/TimerLabel")

	_check(InputMap.has_action("pause"), "La acción de pausa existe en el Input Map")
	_check(pause_overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "El overlay de pausa ignora la pausa del árbol")
	_check(not pause_overlay.visible, "La pausa empieza oculta")
	_check(not paused, "El juego empieza sin pausa")
	_check(level.get_node_or_null("HUD/ControlHints") == null, "La guía de comandos fue retirada del nivel")
	_check(menu_panel.visible and not guide_panel.visible and not settings_panel.visible, "El menú de pausa es el panel inicial")
	_check(_button_text(pause_overlay, "ContinueButton") == "CONTINUAR", "El menú ofrece continuar")
	_check(_button_text(pause_overlay, "GuideButton") == "GUÍA", "El menú ofrece la guía")
	_check(_button_text(pause_overlay, "SettingsButton") == "CONFIGURACIÓN", "El menú ofrece configuración")
	_check(_button_text(pause_overlay, "MainMenuButton") == "VOLVER AL MENÚ PRINCIPAL", "El menú permite volver al inicio")
	_check(_button_text(pause_overlay, "QuitButton") == "SALIR", "El menú permite salir del juego")
	var main_menu_button: Button = pause_overlay.get_node("Center/MenuPanel/Margin/VBox/MainMenuButton")
	var quit_button: Button = pause_overlay.get_node("Center/MenuPanel/Margin/VBox/QuitButton")
	_check(not main_menu_button.pressed.get_connections().is_empty(), "Volver al menú principal está conectado")
	_check(not quit_button.pressed.get_connections().is_empty(), "Salir está conectado")

	# Pausa: el jugador y el cronómetro se congelan aunque se pida moverse.
	var position_before := player.global_position
	var timer_before := timer_label.text
	_press_pause(pause_overlay)
	_check(pause_overlay.visible, "Enter muestra el overlay de pausa")
	_check(paused, "Enter congela el SceneTree")

	Input.action_press("move_right")
	await _wait_physics(30)
	_check(player.global_position == position_before, "El jugador no se mueve en pausa")
	_check(timer_label.text == timer_before, "El cronómetro no avanza en pausa")
	Input.action_release("move_right")

	# Guía: todo el contenido de controles vive ahora en su propia opción.
	pause_overlay._show_guide()
	_check(guide_panel.visible and not menu_panel.visible, "La opción Guía abre su panel")
	await process_frame
	var viewport_height := root.get_visible_rect().size.y
	_check(guide_panel.size.y <= viewport_height, "La guía cabe en la pantalla")
	_check(guide != null, "La guía muestra los controles")
	_check(guide.columns == 1, "La guía de la pausa usa una columna")
	_check(_count_keycaps(guide) == 9, "La guía dibuja las teclas de todos los comandos")
	pause_overlay._show_main_menu()
	_check(menu_panel.visible and not guide_panel.visible, "Volver regresa al menú de pausa")

	# Configuración: misma funcionalidad que Opciones del menú principal.
	pause_overlay._show_settings()
	_check(settings_panel.visible and not menu_panel.visible, "La opción Configuración abre su panel")
	await process_frame
	_check(settings_panel.size.y <= viewport_height, "Configuración cabe en la pantalla")
	var brightness: HSlider = settings_panel.get_node("Margin/VBox/BrightnessRow/BrightnessSlider")
	var volume: HSlider = settings_panel.get_node("Margin/VBox/VolumeRow/VolumeSlider")
	var controls_grid: GridContainer = settings_panel.get_node("Margin/VBox/ControlsGrid")
	_check(brightness.max_value == GameSettings.MAX_BRIGHTNESS * 100.0, "Configuración incluye el brillo")
	_check(volume.max_value == 100.0, "Configuración incluye el volumen")
	_check(controls_grid.get_child_count() == GameSettings.CONTROLS.size() * 2, "Configuración incluye todos los controles")
	brightness.value = 120.0
	volume.value = 55.0
	_check(is_equal_approx(GameSettings.brightness, 1.2), "El brillo se puede cambiar en pausa")
	_check(is_equal_approx(GameSettings.master_volume, 0.55), "El volumen se puede cambiar en pausa")
	var jump_before := GameSettings.get_keycode("jump")
	pause_overlay._start_rebind("jump")
	pause_overlay._show_main_menu()
	pause_overlay._show_settings()
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_Z
	key_event.pressed = true
	pause_overlay._input(key_event)
	_check(GameSettings.get_keycode("jump") == jump_before, "Salir de Configuración cancela un rebinding pendiente")
	GameSettings.reset_controls()
	pause_overlay._show_main_menu()
	_check(menu_panel.visible and not settings_panel.visible, "Volver cierra Configuración")

	# Reanudar: el mismo Enter devuelve el control y el jugador responde.
	_press_pause(pause_overlay)
	_check(not pause_overlay.visible, "Enter reanuda el juego")
	_check(not paused, "Reanudar descongela el SceneTree")

	Input.action_press("move_right")
	await _wait_physics(30)
	Input.action_release("move_right")
	_check(player.global_position.x > position_before.x, "El jugador se mueve tras reanudar")

	# Tras morir la pausa queda bloqueada (no debe congelar la transición).
	player.take_damage(9999)
	await _wait_physics(2)
	_check(level.is_run_over(), "La muerte marca la partida como terminada")
	_press_pause(pause_overlay)
	_check(not pause_overlay.visible, "No se puede pausar tras morir")
	_check(not paused, "El árbol no queda pausado tras morir")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _button_text(pause_overlay: PauseOverlay, name: String) -> String:
	var button := pause_overlay.get_node_or_null("Center/MenuPanel/Margin/VBox/%s" % name) as Button
	return button.text if button != null else ""


func _press_pause(pause_overlay: PauseOverlay) -> void:
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	pause_overlay._unhandled_input(event)


func _count_keycaps(node: Node) -> int:
	## Cuenta los keycaps dibujados (PanelContainer) dentro de la guía.
	var count := 0
	for child in node.get_children():
		if child is PanelContainer:
			count += 1
		count += _count_keycaps(child)
	return count


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
