class_name GameOverScreen
extends Control
## Pantalla de muerte al perder las tres vidas (2026-11-18). La imagen se
## desvanece suavemente a negro, aparece un resplandor rojizo y, encima, un
## panel con el resumen y las opciones. Solo emite señales: quien la crea
## decide qué hacer (recargar nivel, menú, cerrar).
## Botones (nombres de nodo estables para los tests): RetryLevelButton,
## RestartGroupButton (solo si el nivel no es el primero de su zona),
## FirstLevelButton (solo si no se está ya en la zona 1), MainMenuButton y
## QuitButton.

signal retry_requested
signal group_restart_requested
signal first_level_requested
signal main_menu_requested
signal quit_requested

const FADE_TIME := 1.0
const CONTENT_FADE_TIME := 0.6
const EMBER := Color("#E5533D")
const EMBER_DARK := Color("#5A1A14")
const BUTTON_SIZE := Vector2(380.0, 44.0)

var content: Control
var glow: TextureRect
var black: ColorRect
var buttons: Array[Button] = []


## `level_code` es el código "zona-nivel" (p. ej. "3-4"); `world_number` e
## `index_in_world` son sus dos partes.
func build(level_code: String, level_name: String, world_number: int, index_in_world: int,
		time_text: String, deaths: int) -> void:
	name = "GameOverChoice"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	black = ColorRect.new()
	black.name = "BlackFade"
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.modulate.a = 0.0
	add_child(black)

	glow = TextureRect.new()
	glow.name = "Glow"
	glow.texture = _make_glow_texture()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.modulate.a = 0.0
	add_child(glow)

	var center := CenterContainer.new()
	center.name = "Content"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.modulate.a = 0.0
	add_child(center)
	content = center

	var panel := PanelContainer.new()
	panel.name = "Panel"
	var box := MenuStyle.panel_box()
	box.bg_color = Color(0.05, 0.03, 0.04, 0.88)
	box.border_color = EMBER_DARK.lightened(0.25)
	box.set_border_width_all(2)
	box.border_width_top = 4
	box.content_margin_left = 34.0
	box.content_margin_right = 34.0
	box.content_margin_top = 20.0
	box.content_margin_bottom = 22.0
	panel.add_theme_stylebox_override("panel", box)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	column.add_child(_label("♡  ♡  ♡", 22, EMBER_DARK.lightened(0.3)))

	var title := _label("FIN DE LA PARTIDA", 44, EMBER)
	title.name = "TitleLabel"
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 3)
	column.add_child(title)

	column.add_child(_divider())

	var subtitle := _label("Te has quedado sin vidas en el nivel %s · %s" % [level_code, level_name], 15, MenuStyle.CREAM)
	subtitle.name = "SubtitleLabel"
	column.add_child(subtitle)
	var stats := _label("Tiempo %s   ·   Muertes en este nivel: %d" % [time_text, deaths], 13, MenuStyle.SKY_PALE)
	stats.name = "StatsLabel"
	column.add_child(stats)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 6.0)
	column.add_child(spacer)

	_add_button(column, "RetryLevelButton", "REINTENTAR NIVEL %s" % level_code, MenuStyle.Variant.PRIMARY, retry_requested)
	if index_in_world != 1:
		_add_button(column, "RestartGroupButton", "VOLVER A EMPEZAR ZONA %d" % world_number, MenuStyle.Variant.SECONDARY, group_restart_requested)
	if world_number != 1:
		_add_button(column, "FirstLevelButton", "VOLVER A ZONA 1", MenuStyle.Variant.SECONDARY, first_level_requested)
	_add_button(column, "MainMenuButton", "VOLVER AL MENÚ PRINCIPAL", MenuStyle.Variant.SECONDARY, main_menu_requested)
	_add_button(column, "QuitButton", "CERRAR JUEGO", MenuStyle.Variant.DANGER, quit_requested)


## Desvanecimiento leve a negro y luego el panel (devuelve el tween por si se
## quiere esperar). El foco pasa al primer botón cuando el panel es visible.
func play() -> Tween:
	var tween := create_tween()
	tween.tween_property(black, "modulate:a", 1.0, FADE_TIME).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 0.85, CONTENT_FADE_TIME)
	tween.parallel().tween_property(content, "modulate:a", 1.0, CONTENT_FADE_TIME)
	tween.tween_callback(func() -> void:
		if not buttons.is_empty():
			buttons[0].grab_focus())
	return tween


func _add_button(parent: Control, node_name: String, text: String, variant: int, signal_to_emit: Signal) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override("font_size", 15)
	MenuStyle.style_button(button, variant)
	button.pressed.connect(func() -> void: signal_to_emit.emit())
	parent.add_child(button)
	buttons.append(button)
	# Mantiene el orden de foco vertical entre los botones.


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _divider() -> Control:
	## Línea con rombo central a modo de adorno.
	var holder := CenterContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	holder.add_child(row)
	for side in 3:
		if side == 1:
			row.add_child(_label("◆", 12, EMBER))
			continue
		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(120.0, 2.0)
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.color = EMBER_DARK.lightened(0.2)
		row.add_child(line)
	return holder


func _make_glow_texture() -> GradientTexture2D:
	## Resplandor radial rojizo en el centro que se pierde en negro hacia los bordes.
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.32, 0.07, 0.05, 1.0),
		Color(0.12, 0.03, 0.03, 1.0),
		Color(0.0, 0.0, 0.0, 1.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture
