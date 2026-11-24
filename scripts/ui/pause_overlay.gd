class_name PauseOverlay
extends CanvasLayer
## Menú de pausa del nivel (actualizado 2026-11-16). Enter abre un menú con
## Continuar, Guía, Configuración, Volver al menú principal y Salir. La guía
## de controles (con teclas dibujadas) y la configuración de brillo/volumen/
## controles viven en paneles separados. Al pausar se congela el SceneTree
## (cronómetro, enemigos y jugador) salvo este overlay, que corre en
## PROCESS_MODE_ALWAYS.

signal pause_changed(is_paused: bool)

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"

@onready var menu_panel: PanelContainer = $Center/MenuPanel
@onready var guide_panel: PanelContainer = $Center/GuidePanel
@onready var settings_panel: PanelContainer = $Center/SettingsPanel
@onready var continue_button: Button = $Center/MenuPanel/Margin/VBox/ContinueButton
@onready var footer_label: Label = $Center/MenuPanel/Margin/VBox/Footer
@onready var brightness_slider: HSlider = $Center/SettingsPanel/Margin/VBox/BrightnessRow/BrightnessSlider
@onready var brightness_value: Label = $Center/SettingsPanel/Margin/VBox/BrightnessRow/BrightnessValue
@onready var volume_slider: HSlider = $Center/SettingsPanel/Margin/VBox/VolumeRow/VolumeSlider
@onready var volume_value: Label = $Center/SettingsPanel/Margin/VBox/VolumeRow/VolumeValue
@onready var controls_grid: GridContainer = $Center/SettingsPanel/Margin/VBox/ControlsGrid
@onready var status_label: Label = $Center/SettingsPanel/Margin/VBox/StatusLabel

var _awaiting_action: String = ""
var _control_buttons: Dictionary = {}


func _ready() -> void:
	visible = false
	menu_panel.visible = true
	guide_panel.visible = false
	settings_panel.visible = false
	var key_name := OS.get_keycode_string(GameSettings.get_keycode("pause"))
	if not key_name.is_empty():
		footer_label.text = "Pulsa %s para continuar" % key_name
	_build_control_rows()
	_sync_options()
	$Center/MenuPanel/Margin/VBox/ContinueButton.pressed.connect(toggle_pause)
	$Center/MenuPanel/Margin/VBox/GuideButton.pressed.connect(_show_guide)
	$Center/MenuPanel/Margin/VBox/SettingsButton.pressed.connect(_show_settings)
	$Center/MenuPanel/Margin/VBox/MainMenuButton.pressed.connect(_go_to_main_menu)
	$Center/MenuPanel/Margin/VBox/QuitButton.pressed.connect(_quit_game)
	$Center/GuidePanel/Margin/VBox/BackButton.pressed.connect(_show_main_menu)
	$Center/SettingsPanel/Margin/VBox/Buttons/BackButton.pressed.connect(_show_main_menu)
	$Center/SettingsPanel/Margin/VBox/Buttons/ResetControlsButton.pressed.connect(_on_reset_controls_pressed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	volume_slider.value_changed.connect(_on_volume_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if guide_panel.visible or settings_panel.visible:
			_show_main_menu()
		else:
			toggle_pause()
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


func toggle_pause() -> void:
	## Alterna la pausa. Se ignora si la partida ya terminó (muerte, portal
	## o tiempo agotado) para no congelar las transiciones del nivel.
	var level := get_parent()
	if level != null and level.has_method("is_run_over") and level.is_run_over():
		return

	var is_paused := not visible
	visible = is_paused
	get_tree().paused = is_paused
	if is_paused:
		_show_main_menu()
		continue_button.grab_focus()
	else:
		_awaiting_action = ""
	Sfx.play("ui", -12.0)
	pause_changed.emit(is_paused)


func _show_main_menu() -> void:
	_awaiting_action = ""
	_refresh_control_buttons()
	menu_panel.visible = true
	guide_panel.visible = false
	settings_panel.visible = false
	if visible:
		continue_button.grab_focus()


func _show_guide() -> void:
	_awaiting_action = ""
	_refresh_control_buttons()
	menu_panel.visible = false
	guide_panel.visible = true
	settings_panel.visible = false
	$Center/GuidePanel/Margin/VBox/BackButton.grab_focus()


func _show_settings() -> void:
	_awaiting_action = ""
	_refresh_control_buttons()
	menu_panel.visible = false
	guide_panel.visible = false
	settings_panel.visible = true
	_sync_options()
	GameSettings.apply_brightness(_brightness_canvas())
	status_label.text = "Ajusta los valores y pulsa Volver para guardar."
	brightness_slider.grab_focus()


func _go_to_main_menu() -> void:
	_awaiting_action = ""
	visible = false
	get_tree().paused = false
	pause_changed.emit(false)
	SceneFade.change_scene(get_tree(), MAIN_MENU_PATH)


func _quit_game() -> void:
	_awaiting_action = ""
	visible = false
	get_tree().paused = false
	pause_changed.emit(false)
	get_tree().quit()


func _build_control_rows() -> void:
	for action in GameSettings.CONTROLS:
		var label := Label.new()
		label.text = GameSettings.CONTROL_LABELS[action]
		label.custom_minimum_size = Vector2(150.0, 0.0)
		label.add_theme_color_override("font_color", Color("#c9dcf0"))
		label.add_theme_font_size_override("font_size", 13)
		controls_grid.add_child(label)

		var button := Button.new()
		button.custom_minimum_size = Vector2(210.0, 30.0)
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
	_update_option_labels()


func _update_option_labels() -> void:
	brightness_value.text = "%d%%" % roundi(brightness_slider.value)
	volume_value.text = "%d%%" % roundi(volume_slider.value)


func _on_brightness_changed(value: float) -> void:
	GameSettings.set_brightness(value / 100.0)
	GameSettings.apply_brightness(_brightness_canvas())
	_update_option_labels()


func _on_volume_changed(value: float) -> void:
	GameSettings.set_master_volume(value / 100.0)
	_update_option_labels()


func _on_reset_controls_pressed() -> void:
	GameSettings.reset_controls()
	_awaiting_action = ""
	status_label.text = "Controles restaurados."
	_refresh_control_buttons()


func _brightness_canvas() -> CanvasModulate:
	var level := get_parent()
	if level == null:
		return null
	return level.get_node_or_null("Brightness") as CanvasModulate
