class_name HudLayout
extends RefCounted
## Rediseño del HUD (2026-11-18). La pantalla (1152x648) se divide en tres
## zonas: una barra superior de 46 px con TODA la información del jugador y del
## nivel, una franja inferior de 26 px con avisos y objetos rápidos, y el área
## central de juego, que queda libre de elementos permanentes del HUD (solo
## mensajes temporales: cartel de nivel, control activado, muerte, etc.).
##
## Barra superior: izquierda = jugador (corazones y vidas), centro = cuenta
## regresiva y progreso, derecha = nivel y medalla. Los nodos existentes
## conservan nombre y ruta (son contrato de scripts y tests); solo se
## recolocan y reducen. Los textos se hacen más pequeños y se leen sobre fondo
## oscuro con borde de acento.

const SCREEN := Vector2(1152.0, 648.0)
const TOP_BAR_HEIGHT := 46.0
const BOTTOM_BAR_HEIGHT := 26.0
const MARGIN := 14.0
const ACCENT := Color(0.431373, 0.960784, 1.0, 0.55)
const BAR_COLOR := Color(0.04, 0.06, 0.11, 0.86)


static func play_area() -> Rect2:
	## Zona central libre de HUD permanente.
	return Rect2(0.0, TOP_BAR_HEIGHT, SCREEN.x, SCREEN.y - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT)


static func apply(hud: CanvasLayer, level_title: String) -> void:
	_ensure_bar(hud, "TopBar", Rect2(0.0, 0.0, SCREEN.x, TOP_BAR_HEIGHT), false)
	_ensure_bar(hud, "BottomBar", Rect2(0.0, SCREEN.y - BOTTOM_BAR_HEIGHT, SCREEN.x, BOTTOM_BAR_HEIGHT), true)

	# Izquierda: jugador.
	_place(hud.get_node("HealthIcons"), Rect2(MARGIN, 6.0, 92.0, 32.0), 22, HORIZONTAL_ALIGNMENT_LEFT, 3)
	_place(hud.get_node("LivesLabel"), Rect2(MARGIN + 96.0, 14.0, 110.0, 20.0), 13, HORIZONTAL_ALIGNMENT_LEFT, 2)

	# Centro: cuenta regresiva y progreso.
	_place(hud.get_node("TimerLabel"), Rect2(376.0, 1.0, 400.0, 26.0), 20, HORIZONTAL_ALIGNMENT_CENTER, 3)
	var bar := hud.get_node("LevelProgress") as Control
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.offset_left = 396.0
	bar.offset_right = 756.0
	bar.offset_top = 29.0
	bar.offset_bottom = 42.0
	var progress_label := bar.get_node("ProgressLabel") as Label
	progress_label.add_theme_font_size_override("font_size", 10)

	# Derecha: nivel y medalla.
	var info := hud.get_node_or_null("LevelInfo") as Label
	if info == null:
		info = Label.new()
		info.name = "LevelInfo"
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(info)
	info.text = level_title
	info.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0, 1.0))
	_place(info, Rect2(SCREEN.x - MARGIN - 340.0, 4.0, 340.0, 22.0), 15, HORIZONTAL_ALIGNMENT_RIGHT, 3)
	_place(hud.get_node("MedalLabel"), Rect2(SCREEN.x - MARGIN - 380.0, 26.0, 380.0, 16.0), 11, HORIZONTAL_ALIGNMENT_RIGHT, 2)

	# Franja inferior: aviso del portal.
	_place(hud.get_node("PortalHint"), Rect2(MARGIN, SCREEN.y - BOTTOM_BAR_HEIGHT + 4.0, 520.0, 18.0), 12, HORIZONTAL_ALIGNMENT_LEFT, 2)

	# Las barras van detrás de los textos pero delante del destello de daño.
	hud.move_child(hud.get_node("BottomBar"), 1)
	hud.move_child(hud.get_node("TopBar"), 1)


static func _place(control: Control, rect: Rect2, font_size: int, align: int, outline: int) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y
	var label := control as Label
	if label != null:
		label.horizontal_alignment = align
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))


static func _ensure_bar(hud: CanvasLayer, node_name: String, rect: Rect2, accent_on_top: bool) -> void:
	var bar := hud.get_node_or_null(node_name) as Panel
	if bar == null:
		bar = Panel.new()
		bar.name = node_name
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(bar)
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.offset_left = rect.position.x
	bar.offset_top = rect.position.y
	bar.offset_right = rect.end.x
	bar.offset_bottom = rect.end.y
	var style := StyleBoxFlat.new()
	style.bg_color = BAR_COLOR
	style.border_color = ACCENT
	if accent_on_top:
		style.border_width_top = 2
	else:
		style.border_width_bottom = 2
	bar.add_theme_stylebox_override("panel", style)
