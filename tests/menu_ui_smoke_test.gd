extends SceneTree
## Comprueba el rediseño del menú principal (2026-11-17): orden y textos de los
## cinco botones, selección de nivel en panel propio con niveles bloqueados,
## confirmación de salida, ajustes nuevos (música, efectos, pantalla), estilos
## de botón, fondo y que los paneles quepan en 1152x648. Ejecutar con:
## godot --headless --path . --script res://tests/menu_ui_smoke_test.gd

const MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const VIEW := Rect2(0.0, 0.0, 1152.0, 648.0)

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var menu := MENU_SCENE.instantiate()
	root.add_child(menu)
	await _wait_process(3)

	var vbox: VBoxContainer = menu.get_node("MainPanel/PanelMargin/VBox")
	var order: Array[String] = []
	for child in vbox.get_children():
		if child is Button:
			order.append(child.text)
	_check(order.size() == 5, "El menú principal tiene exactamente cinco botones")
	_check(order[0] == "INICIO", "El primer botón es INICIO")
	_check(order[1] == "SELECCIÓN DE NIVEL", "El segundo botón es SELECCIÓN DE NIVEL")
	_check(order[2] == "CÓMO JUGAR", "El tercer botón es CÓMO JUGAR")
	_check(order[3] == "OPCIONES", "El cuarto botón es OPCIONES")
	_check(order[4] == "CERRAR JUEGO", "El quinto botón es CERRAR JUEGO")
	_check(menu.get_viewport().gui_get_focus_owner() == vbox.get_node("PlayButton"), "El primer botón recibe el foco al abrir")
	_check(menu.get_node_or_null("MenuBackdrop") != null, "El menú tiene fondo propio")
	_check(not menu.get_node("Moon").visible, "La luna nocturna antigua queda oculta bajo el nuevo cielo")

	# Estilos: colores de la paleta y estados de botón.
	var play: Button = vbox.get_node("PlayButton")
	var normal := play.get_theme_stylebox("normal") as StyleBoxFlat
	var hover := play.get_theme_stylebox("hover") as StyleBoxFlat
	var pressed := play.get_theme_stylebox("pressed") as StyleBoxFlat
	_check(normal != null and normal.bg_color == MenuStyle.GRASS, "El botón principal usa el verde de la paleta")
	_check(hover != null and hover.bg_color == MenuStyle.ACCENT, "El botón seleccionado usa el acento ámbar")
	_check(pressed != null and pressed.bg_color == MenuStyle.OCHRE, "El botón presionado tiene estilo propio")
	_check(play.get_theme_stylebox("disabled") is StyleBoxFlat, "Los botones desactivados tienen estilo propio")
	var quit_style := (vbox.get_node("QuitButton") as Button).get_theme_stylebox("normal") as StyleBoxFlat
	_check(quit_style.bg_color == MenuStyle.OCHRE_DARK, "Cerrar juego se distingue con el color ocre")

	# Panel principal dentro de pantalla.
	_check(VIEW.encloses((menu.get_node("MainPanel") as Control).get_global_rect()), "El panel principal cabe en la pantalla")

	# Selección de nivel.
	var level_panel: PanelContainer = menu.get_node("LevelSelectPanel")
	_check(not level_panel.visible, "La selección de nivel empieza oculta")
	menu._on_level_select_pressed()
	await _wait_process(3)
	_check(level_panel.visible and not menu.get_node("MainPanel").visible, "El botón abre la selección de nivel")
	_check(VIEW.encloses(level_panel.get_global_rect()), "La selección de nivel cabe en la pantalla")
	var focused := menu.get_viewport().gui_get_focus_owner()
	_check(focused != null and focused.name == "Level1Button", "La selección enfoca el nivel actual")
	var info: Label = level_panel.find_child("LevelInfoLabel", true, false)
	_check(info.text.contains("1-1"), "El panel informa del nivel enfocado")
	var world_two_first: Button = level_panel.find_child("Level6Button", true, false)
	_check(world_two_first.disabled, "El mundo 2 está bloqueado hasta superar el mundo 1")
	_check(level_panel.find_child("World2Label", true, false).text.contains("BLOQUEADO"), "El mundo bloqueado se marca en su etiqueta")
	_check(level_panel.find_child("UnlockRuleLabel", true, false) != null, "El panel explica la regla de desbloqueo")
	menu._on_level_button_pressed(6)
	await _wait_process(2)
	_check(not root.has_node("SceneFadeLayer"), "Un nivel de mundo bloqueado no inicia partida")
	menu._show_level_info(6)
	_check(info.text.contains("Bloqueado") and info.text.contains("seguidos"), "El panel indica qué superar para desbloquear")
	var locked: Button = level_panel.find_child("Level26Button", true, false)
	_check(locked.disabled, "Los niveles no implementados están bloqueados")
	menu._on_level_button_pressed(26)
	await _wait_process(2)
	_check(not root.has_node("SceneFadeLayer"), "Un nivel bloqueado no inicia partida")
	menu._show_level_info(26)
	_check(info.text.contains("bloqueado"), "El nivel bloqueado se indica en el panel")
	menu._close_level_select()
	_check(menu.get_node("MainPanel").visible and not level_panel.visible, "Volver regresa al menú desde la selección")

	# Con el mundo 1 superado, el 2 se abre al reconstruir el menú.
	menu.queue_free()
	await _wait_process(2)
	SaveGame.mark_world_cleared(1)
	menu = MENU_SCENE.instantiate()
	root.add_child(menu)
	await _wait_process(3)
	var unlocked: Button = menu.find_child("Level6Button", true, false)
	_check(not unlocked.disabled, "Superar el mundo 1 desbloquea el mundo 2")
	_check(menu.find_child("World1Label", true, false).text.contains("SUPERADO"), "El mundo superado se marca")
	level_panel = menu.get_node("LevelSelectPanel")
	info = level_panel.find_child("LevelInfoLabel", true, false)

	# Confirmación de salida.
	var quit_panel: PanelContainer = menu.get_node("QuitPanel")
	menu._on_quit_pressed()
	await _wait_process(2)
	_check(quit_panel.visible and not menu.get_node("MainPanel").visible, "Cerrar juego pide confirmación")
	var cancel: Button = quit_panel.find_child("CancelQuitButton", true, false)
	_check(menu.get_viewport().gui_get_focus_owner() == cancel, "La confirmación enfoca CANCELAR por defecto")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	menu._unhandled_input(esc)
	_check(not quit_panel.visible and menu.get_node("MainPanel").visible, "Esc cancela la confirmación sin cerrar el juego")
	menu._unhandled_input(esc)
	_check(quit_panel.visible, "Esc en el menú principal pide confirmar, no cierra directo")
	menu._close_quit_panel()

	# Opciones nuevas.
	menu._on_options_pressed()
	await _wait_process(3)
	var options: PanelContainer = menu.get_node("OptionsPanel")
	_check(VIEW.encloses(options.get_global_rect()), "Las opciones caben en la pantalla con las filas nuevas")
	var music: HSlider = options.find_child("MusicSlider", true, false)
	var sfx: HSlider = options.find_child("SfxSlider", true, false)
	var fullscreen: CheckButton = options.find_child("FullscreenCheck", true, false)
	_check(music != null and sfx != null and fullscreen != null, "Opciones incluye música, efectos y pantalla completa")
	music.value = 40.0
	sfx.value = 60.0
	_check(is_equal_approx(GameSettings.music_volume, 0.4), "El volumen de música se guarda en los ajustes")
	_check(is_equal_approx(GameSettings.sfx_volume, 0.6), "El volumen de efectos se guarda en los ajustes")
	fullscreen.button_pressed = true
	_check(GameSettings.fullscreen, "Pantalla completa se guarda en los ajustes")
	fullscreen.button_pressed = false
	_check(not GameSettings.fullscreen, "Se puede volver a modo ventana")
	GameSettings.set_music_volume(1.0)
	GameSettings.set_sfx_volume(1.0)
	_check(options.find_child("BrightnessSlider", true, false) != null, "El brillo se conserva en Opciones")
	menu._close_options()

	# Cómo jugar sigue accesible y la guía usa las teclas reales.
	menu._on_instructions_pressed()
	var guide: ControlGuide = menu.get_node("InstructionsPanel").find_child("ControlGuide", true, false)
	_check(guide != null, "Cómo jugar muestra la guía de controles")
	var objective: Label = menu.get_node("InstructionsPanel").find_child("ObjectiveText", true, false)
	_check(objective.text.contains("menor tiempo"), "La guía explica el objetivo contrarreloj")
	menu._close_instructions()

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
