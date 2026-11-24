class_name MenuStyle
extends RefCounted
## Paleta y estilos del menú principal (2026-11-17). Un único lugar define los
## colores para que botones, paneles y títulos sean coherentes:
##  - SKY (dominante): fondo y botones secundarios.
##  - GRASS: botones de acción jugable (inicio, niveles disponibles).
##  - INK: paneles y texto oscuro; garantiza el contraste.
##  - ACCENT (ámbar): título y elemento seleccionado/hover.
##  - OCHRE: acciones de salida y botón presionado.
## Todo se aplica por código con overrides de tema, sin tocar las escenas.

const SKY_DEEP := Color("#2B6CA3")
const SKY := Color("#4FA3D9")
const SKY_PALE := Color("#BFE3F2")
const GRASS := Color("#3F8240")
const INK := Color("#16303F")
const ACCENT := Color("#FFB93B")
const OCHRE := Color("#C98A3D")
const OCHRE_DARK := Color("#8A5A22")
const CREAM := Color("#FFF6E0")
const DISABLED_BG := Color("#33404A")
const DISABLED_TEXT := Color("#8795A0")

enum Variant { PRIMARY, SECONDARY, DANGER }

const PRESS_META := "menu_press_fx"


static func panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK.r, INK.g, INK.b, 0.92)
	box.border_color = SKY
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	box.shadow_size = 10
	return box


static func button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	return box


static func style_button(button: Button, variant: int = Variant.PRIMARY) -> void:
	## Estados: normal (color de rol), hover/foco (ámbar), presionado (ocre) y
	## desactivado (gris). El foco usa el mismo ámbar que el hover para que
	## teclado, mando y ratón se vean igual.
	var base := SKY_DEEP
	match variant:
		Variant.PRIMARY:
			base = GRASS
		Variant.DANGER:
			base = OCHRE_DARK
	var selected := button_box(ACCENT, CREAM)
	var pressed := button_box(OCHRE, ACCENT)
	button.add_theme_stylebox_override("normal", button_box(base, base.darkened(0.35)))
	button.add_theme_stylebox_override("hover", selected)
	button.add_theme_stylebox_override("focus", selected)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", button_box(DISABLED_BG, DISABLED_BG.darkened(0.3)))
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_hover_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", DISABLED_TEXT)

	# El foco se dibuja encima del estado presionado, así que el feedback de
	# pulsación se hace con un ligero oscurecimiento.
	if not button.has_meta(PRESS_META):
		button.set_meta(PRESS_META, true)
		button.button_down.connect(func() -> void: button.modulate = Color(0.82, 0.82, 0.82))
		button.button_up.connect(func() -> void: button.modulate = Color.WHITE)


static func style_title(label: Label, font_size: int) -> void:
	label.add_theme_color_override("font_color", ACCENT)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	label.add_theme_constant_override("outline_size", maxi(4, font_size / 6))
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_font_size_override("font_size", font_size)
