extends Control
## Menú principal. INICIO continúa desde el último nivel guardado (o empieza
## una nueva expedición si el juego ya se completó); SELECCIÓN DE NIVEL abre
## los 40 niveles por mundos; CÓMO JUGAR muestra la guía; OPCIONES ajusta
## brillo, volúmenes, pantalla y controles; CERRAR JUEGO pide confirmación.
## 2026-11-17: estilo y fondo nuevos (MenuStyle/MenuBackdrop), selección de
## nivel en panel propio, confirmación de salida y opciones de audio/pantalla.

const FADE_TIME := 0.15
const MEDAL_COLORS := {
	MedalRules.GOLD: Color("#FFD54A"),
	MedalRules.SILVER: Color("#D8E1E8"),
	MedalRules.BRONZE: Color("#C77B3A"),
}

@onready var brightness_slider: HSlider = $OptionsPanel/PanelMargin/VBox/BrightnessRow/BrightnessSlider
@onready var brightness_value: Label = $OptionsPanel/PanelMargin/VBox/BrightnessRow/BrightnessValue
@onready var volume_slider: HSlider = $OptionsPanel/PanelMargin/VBox/VolumeRow/VolumeSlider
@onready var volume_value: Label = $OptionsPanel/PanelMargin/VBox/VolumeRow/VolumeValue
@onready var controls_grid: GridContainer = $OptionsPanel/PanelMargin/VBox/ControlsGrid
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var instructions_panel: PanelContainer = $InstructionsPanel
@onready var main_panel: PanelContainer = $MainPanel
@onready var total_label: Label = $MainPanel/PanelMargin/VBox/TotalLabel
@onready var status_label: Label = $OptionsPanel/PanelMargin/VBox/StatusLabel
@onready var play_button: Button = $MainPanel/PanelMargin/VBox/PlayButton

var _awaiting_action: String = ""
var _control_buttons: Dictionary = {}
var _level_buttons: Dictionary = {}
var _level_panel: PanelContainer
var _level_info: Label
var _quit_panel: PanelContainer
var _quit_cancel_button: Button
var _music_slider: HSlider
var _music_value: Label
var _sfx_slider: HSlider
var _sfx_value: Label
var _fullscreen_check: CheckButton


func _ready() -> void:
	GameSettings.ensure_loaded()
	SaveGame.ensure_loaded()
	GameSettings.apply_brightness($Brightness)
	GameSettings.apply_audio()
	Sfx.stop_music(0.4)
	options_panel.visible = false
	instructions_panel.visible = false
	_add_backdrop()
	var world_number := LevelRegistry.get_world_for_level(SaveGame.level).number
	total_label.text = "NIVEL %s · ZONA %d DE %d" % [
		LevelRegistry.get_level(SaveGame.level).code(),
		world_number,
		LevelRegistry.WORLD_COUNT,
	]
	_refresh_play_button()
	_build_control_rows()
	_build_level_selector()
	_build_extra_options()
	_build_quit_panel()
	_sync_options()
	play_button.pressed.connect(_on_play_pressed)
	$MainPanel/PanelMargin/VBox/SelectLevelButton.pressed.connect(_on_level_select_pressed)
	$MainPanel/PanelMargin/VBox/OptionsButton.pressed.connect(_on_options_pressed)
	$MainPanel/PanelMargin/VBox/InstructionsButton.pressed.connect(_on_instructions_pressed)
	$MainPanel/PanelMargin/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_sfx_slider.drag_ended.connect(func(_changed: bool) -> void: Sfx.play("ui", -12.0))
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	$OptionsPanel/PanelMargin/VBox/Buttons/ResetControlsButton.pressed.connect(_on_reset_controls_pressed)
	$OptionsPanel/PanelMargin/VBox/Buttons/BackButton.pressed.connect(_close_options)
	$InstructionsPanel/PanelMargin/VBox/BackButton.pressed.connect(_close_instructions)
	_apply_style()
	play_button.grab_focus()
	# Tras el primer foco, para que abrir el menú no suene.
	_wire_feedback()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _quit_panel.visible:
			_close_quit_panel()
		elif _level_panel.visible:
			_close_level_select()
		elif instructions_panel.visible:
			_close_instructions()
		elif options_panel.visible:
			_close_options()
		else:
			_on_quit_pressed()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if _awaiting_action.is_empty():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var key := event as InputEventKey
	if key.physical_keycode == KEY_ESCAPE:
		_cancel_rebind()
	else:
		GameSettings.set_key(_awaiting_action, key.physical_keycode)
		status_label.text = "Control actualizado."
		_awaiting_action = ""
		_refresh_control_buttons()
	get_viewport().set_input_as_handled()


func _add_backdrop() -> void:
	# El cielo diurno sustituye al fondo nocturno; los nodos antiguos se
	# conservan ocultos (la luna tiene z_index y se dibujaría encima).
	$Moon.visible = false
	$Stars.visible = false
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	move_child(backdrop, $Stars.get_index() + 1)


func _refresh_play_button() -> void:
	## Con progreso guardado el botón avisa de que continúa; el nivel 1 sigue
	## accesible desde SELECCIÓN DE NIVEL.
	if SaveGame.level > SaveGame.FIRST_LEVEL and not SaveGame.completed:
		play_button.text = "CONTINUAR · NIVEL %s" % LevelRegistry.get_level(SaveGame.level).code()
	else:
		play_button.text = "INICIO"


func _build_level_selector() -> void:
	## Selector de los 40 niveles agrupados en 8 mundos (2026-11-17), ahora en
	## su propio panel. Los niveles pendientes se muestran desactivados hasta
	## que tengan escena; las medallas conseguidas se marcan con un punto.
	_level_panel = PanelContainer.new()
	_level_panel.name = "LevelSelectPanel"
	_level_panel.visible = false
	_center_panel(_level_panel, 920.0)
	add_child(_level_panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	_level_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "Title"
	title.text = "SELECCIÓN DE NIVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.name = "LevelSelect"
	scroll.custom_minimum_size = Vector2(0.0, 340.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.name = "WorldGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	for world in LevelRegistry.all_worlds():
		var world_box := VBoxContainer.new()
		world_box.name = "World%dBox" % world.number
		world_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		world_box.add_theme_constant_override("separation", 3)
		var world_label := Label.new()
		world_label.name = "World%dLabel" % world.number
		world_label.text = "%d · %s" % [world.number, world.display_name]
		if SaveGame.is_world_cleared(world.number):
			world_label.text += "  ·  SUPERADO"
		elif not SaveGame.is_world_unlocked(world.number):
			world_label.text += "  ·  BLOQUEADO"
		world_label.add_theme_color_override("font_color", world.accent.lightened(0.35))
		world_label.add_theme_font_size_override("font_size", 13)
		world_box.add_child(world_label)
		var row := HBoxContainer.new()
		row.name = "World%dRow" % world.number
		row.add_theme_constant_override("separation", 6)
		for config in world.levels:
			row.add_child(_make_level_button(config))
		world_box.add_child(row)
		grid.add_child(world_box)
	scroll.add_child(grid)
	vbox.add_child(scroll)

	var rule := Label.new()
	rule.name = "UnlockRuleLabel"
	rule.text = "Practica cada nivel por separado. Para abrir la siguiente zona, completa todos los niveles de la zona seguidos en una misma pasada."
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.add_theme_font_size_override("font_size", 12)
	rule.add_theme_color_override("font_color", MenuStyle.SKY_PALE)
	vbox.add_child(rule)

	_level_info = Label.new()
	_level_info.name = "LevelInfoLabel"
	_level_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_info.custom_minimum_size = Vector2(0.0, 24.0)
	_level_info.add_theme_color_override("font_color", MenuStyle.CREAM)
	vbox.add_child(_level_info)

	var back := Button.new()
	back.name = "BackButton"
	back.text = "VOLVER"
	back.custom_minimum_size = Vector2(0.0, 42.0)
	back.pressed.connect(_close_level_select)
	vbox.add_child(back)
	_show_level_info(SaveGame.level)


func _make_level_button(config: LevelConfig) -> Button:
	var button := Button.new()
	button.name = "Level%dButton" % config.number
	button.text = config.code()
	button.disabled = not config.is_implemented() or not SaveGame.is_level_unlocked(config.number)
	button.custom_minimum_size = Vector2(64.0, 44.0)
	button.add_theme_font_size_override("font_size", 16)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if config.is_implemented():
		button.pressed.connect(_on_level_button_pressed.bind(config.number))
	button.focus_entered.connect(_show_level_info.bind(config.number))
	button.mouse_entered.connect(_show_level_info.bind(config.number))
	var medal := SaveGame.get_medal(config.number)
	if MEDAL_COLORS.has(medal):
		var dot := ColorRect.new()
		dot.name = "MedalDot"
		dot.color = MEDAL_COLORS[medal]
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		dot.offset_left = -15.0
		dot.offset_top = 5.0
		dot.offset_right = -5.0
		dot.offset_bottom = 15.0
		button.add_child(dot)
	_level_buttons[config.number] = button
	return button


func _show_level_info(level_number: int) -> void:
	var config := LevelRegistry.get_level(level_number)
	if config == null:
		_level_info.text = ""
		return
	if not config.is_implemented():
		_level_info.text = "%s · bloqueado (por construir)" % config.code()
		return
	if not SaveGame.is_level_unlocked(level_number):
		_level_info.text = "%s · %s" % [config.code(), SaveGame.unlock_hint(config.world_number)]
		return
	var text := config.label()
	if SaveGame.has_level_record(level_number):
		text += "  ·  Mejor: %s" % SaveGame.format_time_precise(SaveGame.get_best_time(level_number))
		text += "  ·  %s" % MedalRules.display(SaveGame.get_medal(level_number))
	else:
		text += "  ·  Sin marca"
	_level_info.text = text


func _build_extra_options() -> void:
	## Volúmenes de música y efectos y pantalla completa (2026-11-17), debajo
	## del volumen general.
	var vbox: VBoxContainer = $OptionsPanel/PanelMargin/VBox
	var index: int = vbox.get_node("VolumeRow").get_index() + 1
	var music := _make_slider_row("Music", "Música")
	_music_slider = music[0]
	_music_value = music[1]
	vbox.move_child(music[2], index)
	var sfx := _make_slider_row("Sfx", "Efectos")
	_sfx_slider = sfx[0]
	_sfx_value = sfx[1]
	vbox.move_child(sfx[2], index + 1)
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.name = "FullscreenCheck"
	_fullscreen_check.text = "Pantalla completa"
	_fullscreen_check.add_theme_color_override("font_color", MenuStyle.CREAM)
	vbox.add_child(_fullscreen_check)
	vbox.move_child(_fullscreen_check, index + 2)

	# Con más filas el panel debe caber en 648 px: los controles van en 2 columnas.
	controls_grid.columns = 4


func _make_slider_row(base_name: String, text: String) -> Array:
	var vbox: VBoxContainer = $OptionsPanel/PanelMargin/VBox
	var row := HBoxContainer.new()
	row.name = "%sRow" % base_name
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.name = "%sTitle" % base_name
	label.text = text
	label.custom_minimum_size = Vector2(90.0, 0.0)
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1.0))
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = "%sSlider" % base_name
	slider.custom_minimum_size = Vector2(0.0, 24.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.max_value = 100.0
	slider.step = 1.0
	row.add_child(slider)
	var value_label := Label.new()
	value_label.name = "%sValue" % base_name
	value_label.custom_minimum_size = Vector2(58.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", MenuStyle.ACCENT)
	row.add_child(value_label)
	vbox.add_child(row)
	return [slider, value_label, row]


func _build_quit_panel() -> void:
	_quit_panel = PanelContainer.new()
	_quit_panel.name = "QuitPanel"
	_quit_panel.visible = false
	_center_panel(_quit_panel, 440.0)
	add_child(_quit_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	_quit_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	var title := Label.new()
	title.name = "Title"
	title.text = "¿CERRAR EL JUEGO?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var note := Label.new()
	note.text = "Tu progreso ya está guardado."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", MenuStyle.CREAM)
	vbox.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	vbox.add_child(buttons)
	_quit_cancel_button = Button.new()
	_quit_cancel_button.name = "CancelQuitButton"
	_quit_cancel_button.text = "CANCELAR"
	_quit_cancel_button.custom_minimum_size = Vector2(0.0, 44.0)
	_quit_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quit_cancel_button.pressed.connect(_close_quit_panel)
	buttons.add_child(_quit_cancel_button)
	var confirm := Button.new()
	confirm.name = "ConfirmQuitButton"
	confirm.text = "CERRAR"
	confirm.custom_minimum_size = Vector2(0.0, 44.0)
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(_confirm_quit)
	buttons.add_child(confirm)


func _center_panel(panel: Control, width: float) -> void:
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -width / 2.0
	panel.offset_right = width / 2.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH


func _apply_style() -> void:
	for panel in [main_panel, options_panel, instructions_panel, _level_panel, _quit_panel]:
		panel.add_theme_stylebox_override("panel", MenuStyle.panel_box())
	MenuStyle.style_title($MainPanel/PanelMargin/VBox/Title, 44)
	MenuStyle.style_title($InstructionsPanel/PanelMargin/VBox/Title, 30)
	MenuStyle.style_title($OptionsPanel/PanelMargin/VBox/Title, 30)
	MenuStyle.style_title(_level_panel.get_node("Margin/VBox/Title"), 30)
	MenuStyle.style_title(_quit_panel.find_child("Title", true, false), 26)
	$MainPanel/PanelMargin/VBox/Subtitle.add_theme_color_override("font_color", MenuStyle.CREAM)

	for button in find_children("*", "Button", true, false):
		if button is CheckButton:
			continue
		var variant := MenuStyle.Variant.SECONDARY
		if button == play_button or button.name.begins_with("Level") and button.name != "SelectLevelButton":
			variant = MenuStyle.Variant.PRIMARY
		elif button.name == "QuitButton" or button.name == "ConfirmQuitButton":
			variant = MenuStyle.Variant.DANGER
		MenuStyle.style_button(button, variant)

	# Menos ancho por fila de controles (2 columnas de pares etiqueta/tecla).
	for child in controls_grid.get_children():
		if child is Label:
			child.custom_minimum_size = Vector2(100.0, 0.0)
		elif child is Button:
			child.custom_minimum_size = Vector2(150.0, 32.0)


func _wire_feedback() -> void:
	## Sonido discreto al mover el foco y al confirmar, para todos los botones.
	for button in find_children("*", "Button", true, false):
		button.focus_entered.connect(Sfx.play.bind("ui", -17.0))
		button.pressed.connect(Sfx.play.bind("ui_confirm", -10.0))


func _fade_in(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.create_tween().tween_property(panel, "modulate:a", 1.0, FADE_TIME)


func _build_control_rows() -> void:
	for action in GameSettings.CONTROLS:
		var label := Label.new()
		label.text = GameSettings.CONTROL_LABELS[action]
		label.custom_minimum_size = Vector2(150.0, 0.0)
		label.add_theme_color_override("font_color", Color("#c9dcf0"))
		controls_grid.add_child(label)

		var button := Button.new()
		button.custom_minimum_size = Vector2(210.0, 38.0)
		button.pressed.connect(_start_rebind.bind(action))
		controls_grid.add_child(button)
		_control_buttons[action] = button
	_refresh_control_buttons()


func _refresh_control_buttons() -> void:
	for action in GameSettings.CONTROLS:
		var button: Button = _control_buttons[action]
		if action == _awaiting_action:
			button.text = "Presiona una tecla..."
		else:
			button.text = GameSettings.get_key_label(action)


func _start_rebind(action: String) -> void:
	_awaiting_action = action
	status_label.text = "Pulsa la nueva tecla para %s (Esc cancela)." % GameSettings.CONTROL_LABELS[action]
	_refresh_control_buttons()


func _cancel_rebind() -> void:
	_awaiting_action = ""
	status_label.text = "Asignación cancelada."
	_refresh_control_buttons()


func _sync_options() -> void:
	brightness_slider.value = GameSettings.brightness * 100.0
	volume_slider.value = GameSettings.master_volume * 100.0
	_music_slider.value = GameSettings.music_volume * 100.0
	_sfx_slider.value = GameSettings.sfx_volume * 100.0
	_fullscreen_check.button_pressed = GameSettings.fullscreen
	_update_option_labels()


func _update_option_labels() -> void:
	brightness_value.text = "%d%%" % roundi(brightness_slider.value)
	volume_value.text = "%d%%" % roundi(volume_slider.value)
	_music_value.text = "%d%%" % roundi(_music_slider.value)
	_sfx_value.text = "%d%%" % roundi(_sfx_slider.value)


func _on_brightness_changed(value: float) -> void:
	GameSettings.set_brightness(value / 100.0)
	GameSettings.apply_brightness($Brightness)
	_update_option_labels()


func _on_volume_changed(value: float) -> void:
	GameSettings.set_master_volume(value / 100.0)
	_update_option_labels()


func _on_music_changed(value: float) -> void:
	GameSettings.set_music_volume(value / 100.0)
	_update_option_labels()


func _on_sfx_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value / 100.0)
	_update_option_labels()


func _on_fullscreen_toggled(enabled: bool) -> void:
	GameSettings.set_fullscreen(enabled)


func _on_level_button_pressed(level_number: int) -> void:
	if not LevelRegistry.is_implemented(level_number) or not SaveGame.is_level_unlocked(level_number):
		return
	SaveGame.start_at_level(level_number)
	SceneFade.change_scene(get_tree(), LevelRegistry.scene_path_for(level_number))


func _on_play_pressed() -> void:
	if SaveGame.completed:
		SaveGame.begin_new_run()
	var level_number := clampi(SaveGame.level, SaveGame.FIRST_LEVEL, SaveGame.LAST_LEVEL)
	if not SaveGame.is_level_unlocked(level_number):
		level_number = SaveGame.FIRST_LEVEL
	while level_number <= SaveGame.LAST_LEVEL and not LevelRegistry.is_implemented(level_number):
		level_number += 1
	if level_number > SaveGame.LAST_LEVEL:
		level_number = LevelRegistry.implemented_levels()[0].number
	SaveGame.set_level(level_number)
	SceneFade.change_scene(get_tree(), LevelRegistry.scene_path_for(level_number))


func _on_level_select_pressed() -> void:
	main_panel.visible = false
	_level_panel.visible = true
	_fade_in(_level_panel)
	var target: Button = _level_buttons.get(SaveGame.level, null)
	if target == null or target.disabled:
		target = _level_buttons[LevelRegistry.implemented_levels()[0].number]
	target.grab_focus()


func _close_level_select() -> void:
	_level_panel.visible = false
	main_panel.visible = true
	_fade_in(main_panel)
	$MainPanel/PanelMargin/VBox/SelectLevelButton.grab_focus()


func _on_options_pressed() -> void:
	main_panel.visible = false
	options_panel.visible = true
	_fade_in(options_panel)
	_awaiting_action = ""
	status_label.text = "Ajusta los valores y pulsa Volver para guardar."
	brightness_slider.grab_focus()


func _close_options() -> void:
	_awaiting_action = ""
	options_panel.visible = false
	main_panel.visible = true
	_fade_in(main_panel)
	$MainPanel/PanelMargin/VBox/OptionsButton.grab_focus()


func _on_instructions_pressed() -> void:
	main_panel.visible = false
	instructions_panel.visible = true
	_fade_in(instructions_panel)
	$InstructionsPanel/PanelMargin/VBox/BackButton.grab_focus()


func _close_instructions() -> void:
	instructions_panel.visible = false
	main_panel.visible = true
	_fade_in(main_panel)
	$MainPanel/PanelMargin/VBox/InstructionsButton.grab_focus()


func _on_reset_controls_pressed() -> void:
	GameSettings.reset_controls()
	_awaiting_action = ""
	status_label.text = "Controles restaurados."
	_refresh_control_buttons()


func _on_quit_pressed() -> void:
	## Pide confirmación; el cierre real está en _confirm_quit().
	main_panel.visible = false
	_quit_panel.visible = true
	_fade_in(_quit_panel)
	_quit_cancel_button.grab_focus()


func _close_quit_panel() -> void:
	_quit_panel.visible = false
	main_panel.visible = true
	_fade_in(main_panel)
	$MainPanel/PanelMargin/VBox/QuitButton.grab_focus()


func _confirm_quit() -> void:
	get_tree().quit()
