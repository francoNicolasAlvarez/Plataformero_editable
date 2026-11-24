class_name ControlGuide
extends VBoxContainer
## Guía visual de controles con teclas dibujadas (keycaps) en vez de texto
## plano. Se muestra en el menú principal y en la pausa del nivel, nunca
## durante el juego. Lee las teclas actuales de GameSettings para reflejar
## las remapeadas en Opciones.

@export var columns: int = 1:
	set(value):
		columns = maxi(1, value)
		_rebuild()

# Acción(es) + descripción de cada fila de la guía. "extras" añade keycaps
# fijos (las flechas siempre mueven al jugador además de la tecla principal).
const GUIDE_ROWS := [
	{"keys": ["move_left", "move_right"], "extras": ["←", "→"], "label": "Moverse"},
	{"keys": ["jump"], "label": "Saltar / doble salto"},
	{"keys": ["move_down"], "extras": ["↓"], "label": "Caer rápido"},
	{"keys": ["dash"], "label": "Impulso (atraviesa enemigos)"},
	{"keys": ["pause"], "label": "Pausa"},
]

const KEYCAP_BG := Color(0.93, 0.96, 1.0)
const KEYCAP_BORDER := Color(0.30, 0.50, 0.68)
const KEYCAP_TEXT := Color(0.09, 0.15, 0.24)
const DESC_TEXT := Color(0.87, 0.93, 1.0)


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "CONTROLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.35))
	title.add_theme_font_size_override("font_size", 15)
	add_child(title)

	# Reparte las filas en columnas para que quepa en el menú (2 columnas).
	var column_count := maxi(1, columns)
	var rows_box := HBoxContainer.new()
	rows_box.add_theme_constant_override("separation", 26)
	add_child(rows_box)
	var column_nodes: Array[VBoxContainer] = []
	for i in column_count:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_theme_constant_override("separation", 7)
		rows_box.add_child(column)
		column_nodes.append(column)

	for row_index in GUIDE_ROWS.size():
		var column := column_nodes[row_index % column_count]
		column.add_child(_build_row(GUIDE_ROWS[row_index]))


func _build_row(row: Dictionary) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	for action in row.keys:
		hbox.add_child(_build_keycap(_key_text(action)))
	for extra in row.get("extras", []):
		hbox.add_child(_build_keycap(extra))

	var desc := Label.new()
	desc.text = row.label
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", DESC_TEXT)
	desc.add_theme_font_size_override("font_size", 13)
	hbox.add_child(desc)
	return hbox


## Dibuja una tecla: panel claro con borde, sombra baja y texto centrado.
func _build_keycap(text: String) -> PanelContainer:
	var keycap := PanelContainer.new()
	keycap.custom_minimum_size = Vector2(44.0, 28.0)
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = KEYCAP_BG
	style.border_color = KEYCAP_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	keycap.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", KEYCAP_TEXT)
	label.add_theme_font_size_override("font_size", 12)
	keycap.add_child(label)
	return keycap


## Nombre corto de la tecla actual de una acción (respeta remapeos).
func _key_text(action: String) -> String:
	GameSettings.ensure_loaded()
	var keycode := GameSettings.get_keycode(action)
	match keycode:
		KEY_SPACE:
			return "Espacio"
		KEY_SHIFT:
			return "Shift"
		KEY_CTRL:
			return "Ctrl"
		KEY_TAB:
			return "Tab"
		KEY_ENTER, KEY_KP_ENTER:
			return "Enter"
		_:
			var text := OS.get_keycode_string(keycode)
			return text if not text.is_empty() else "?"
