extends SceneTree
## Comprueba el menú principal, las opciones de brillo/volumen/controles y la
## pantalla de instrucciones. Ejecutar con:
## godot --headless --path . --script res://tests/menu_smoke_test.gd

const MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Con el mundo 1 superado, los niveles del mundo 2 quedan habilitados.
	SaveGame.mark_world_cleared(1)
	var menu := MENU_SCENE.instantiate()
	root.add_child(menu)

	var main_panel: PanelContainer = menu.get_node("MainPanel")
	var options_panel: PanelContainer = menu.get_node("OptionsPanel")
	var brightness: HSlider = menu.get_node("OptionsPanel/PanelMargin/VBox/BrightnessRow/BrightnessSlider")
	var volume: HSlider = menu.get_node("OptionsPanel/PanelMargin/VBox/VolumeRow/VolumeSlider")
	var status: Label = menu.get_node("OptionsPanel/PanelMargin/VBox/StatusLabel")
	var controls_grid: GridContainer = menu.get_node("OptionsPanel/PanelMargin/VBox/ControlsGrid")
	var total_label: Label = menu.get_node("MainPanel/PanelMargin/VBox/TotalLabel")

	await _wait_process(2)

	_check(ResourceLoader.exists("res://scenes/levels/level_one.tscn"), "El menú puede iniciar el nivel 1")
	_check(main_panel.visible, "El panel principal empieza visible")
	_check(not options_panel.visible, "Las opciones empiezan ocultas")
	_check(menu.get_node_or_null("MainPanel/PanelMargin/VBox/UpgradesButton") == null, "El menú ya no tiene mejoras roguelite")
	_check(menu.get_node_or_null("MainPanel/PanelMargin/VBox/ControlGuide") == null, "El panel principal ya no muestra la guía de controles")
	_check(is_equal_approx(brightness.min_value, GameSettings.MIN_BRIGHTNESS * 100.0), "El brillo tiene un mínimo seguro")
	_check(brightness.max_value == GameSettings.MAX_BRIGHTNESS * 100.0, "El brillo tiene un máximo seguro")
	_check(volume.max_value == 100.0, "El volumen llega al 100%")

	menu._on_options_pressed()
	_check(options_panel.visible, "El botón Opciones abre el panel")
	_check(not main_panel.visible, "El panel principal se oculta en opciones")

	brightness.value = 120.0
	volume.value = 55.0
	_check(is_equal_approx(GameSettings.brightness, 1.2), "El brillo se guarda en los ajustes")
	_check(is_equal_approx(GameSettings.master_volume, 0.55), "El volumen se guarda en los ajustes")

	GameSettings.set_key("jump", KEY_F)
	_check(GameSettings.get_keycode("jump") == KEY_F, "Los controles se pueden reasignar")
	GameSettings.reset_controls()
	_check(GameSettings.get_keycode("jump") == KEY_SPACE, "Los controles se pueden restaurar")
	_check(GameSettings.get_keycode("pause") == KEY_ENTER, "La pausa también se puede reasignar")
	_check(controls_grid.get_child_count() == GameSettings.CONTROLS.size() * 2, "Todas las acciones tienen su fila en Opciones")

	# Las flechas son teclas secundarias fijas y sobreviven a los remapeos.
	var arrow_kept := false
	for input_event in InputMap.action_get_events("move_left"):
		if input_event is InputEventKey and input_event.physical_keycode == KEY_LEFT:
			arrow_kept = true
	_check(arrow_kept, "Las flechas siguen moviendo al jugador tras aplicar los ajustes")
	_check(
		total_label.text.contains("NIVEL") and total_label.text.contains("DE 8")
		and total_label.text.contains("ZONA"),
		"El menú muestra el nivel, los 40 niveles y el mundo"
	)
	var level_select: ScrollContainer = menu.get_node_or_null("LevelSelectPanel/Margin/VBox/LevelSelect")
	_check(level_select != null, "El menú tiene un selector con scroll")
	var world_grid: GridContainer = menu.get_node_or_null("LevelSelectPanel/Margin/VBox/LevelSelect/WorldGrid")
	_check(world_grid != null and world_grid.get_child_count() == 8, "El selector agrupa 8 mundos")
	_check(menu.find_children("World?Label", "Label", true, false).size() == 8, "Cada mundo tiene etiqueta")
	_check(menu.find_children("Level?Button", "Button", true, false).size() == 9, "Los 9 primeros botones son de un dígito")
	_check(menu.find_children("Level??Button", "Button", true, false).size() == 31, "Los otros 31 botones son de dos dígitos")
	var level_buttons := menu.find_children("Level*Button", "Button", true, false)
	_check(level_buttons.size() == 40, "El menú ofrece selección directa de los 40 niveles")
	var first_button: Button = menu.get_node("LevelSelectPanel/Margin/VBox/LevelSelect/WorldGrid/World1Box/World1Row/Level1Button")
	var eighth_button: Button = menu.get_node("LevelSelectPanel/Margin/VBox/LevelSelect/WorldGrid/World2Box/World2Row/Level8Button")
	var ninth_button: Button = menu.get_node("LevelSelectPanel/Margin/VBox/LevelSelect/WorldGrid/World3Box/World3Row/Level11Button")
	_check(first_button.text == "1-1" and not first_button.disabled, "El nivel 1 es accesible y muestra su código")
	_check(not eighth_button.disabled, "Los 8 niveles creados están habilitados")
	_check(ninth_button.disabled, "Los niveles pendientes están desactivados")
	SaveGame.start_at_level(3)
	_check(SaveGame.level == 3, "La selección de nivel guarda el nivel elegido")
	_check(not SaveGame.completed and SaveGame.total_time == 0.0 and SaveGame.deaths == 0,
		"Empezar en un nivel elegido reinicia las estadísticas")
	SaveGame.begin_new_run()

	menu._on_reset_controls_pressed()
	_check(status.text.contains("restaurados"), "El menú confirma la restauración")
	menu._close_options()
	_check(main_panel.visible, "Volver regresa al panel principal")

	var instructions_panel: PanelContainer = menu.get_node("InstructionsPanel")
	var instructions_button: Button = menu.get_node("MainPanel/PanelMargin/VBox/InstructionsButton")
	_check(not instructions_panel.visible, "Las instrucciones empiezan ocultas")
	_check(instructions_button.text.contains("CÓMO JUGAR"), "El menú tiene un botón de instrucciones")
	var instructions_guide: ControlGuide = instructions_panel.find_child("ControlGuide", true, false)
	_check(instructions_guide.columns == 2, "Las instrucciones muestran todos los controles")
	var objective: Label = instructions_panel.find_child("ObjectiveText", true, false)
	var objects: Label = instructions_panel.find_child("ObjectsText", true, false)
	var time_text: Label = instructions_panel.find_child("TimeText", true, false)
	var items: Label = instructions_panel.find_child("ItemsText", true, false)
	_check(objective.text.contains("portal"), "Las instrucciones explican el objetivo")
	_check(
		objects.text.contains("Hierba") and objects.text.contains("Portal") and not objects.text.contains("Moneda"),
		"Las instrucciones listan los objetos del nivel sin monedas"
	)
	_check(objects.text.contains("voladores"), "Las instrucciones mencionan a los enemigos voladores")
	_check(time_text.text.contains("70"), "Las instrucciones explican la restricción de tiempo")
	_check(not items.text.contains("Poción") and not items.text.contains("Ración") and not items.text.contains("Tab"), "Las instrucciones ya no mencionan objetos utilizables")
	_check(
		items.text.contains("siempre") and items.text.contains("Caer"),
		"Las instrucciones explican el doble salto permanente y la caída rápida"
	)
	menu._on_instructions_pressed()
	_check(instructions_panel.visible and not main_panel.visible, "El botón Instrucciones abre el panel")
	menu._close_instructions()
	_check(main_panel.visible and not instructions_panel.visible, "Volver cierra las instrucciones")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _wait_process(frames: int) -> void:
	for _frame in frames:
		await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
