class_name GameSettings
extends RefCounted
## Ajustes persistentes de brillo, volumen y controles. En headless no toca
## disco ni audio para no interferir con las pruebas.

const CONFIG_PATH := "user://settings.cfg"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const MIN_BRIGHTNESS := 0.55
const MAX_BRIGHTNESS := 1.35
const CONTROLS := ["move_left", "move_right", "move_down", "jump", "dash", "pause"]
const DEFAULT_KEYS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_down": KEY_S,
	"jump": KEY_SPACE,
	"dash": KEY_CTRL,
	"pause": KEY_ENTER,
}
const CONTROL_LABELS := {
	"move_left": "Izquierda",
	"move_right": "Derecha",
	"move_down": "Caer rápido",
	"jump": "Saltar",
	"dash": "Impulso",
	"pause": "Pausa",
}
# Teclas secundarias fijas que se conservan aunque se remapee la principal
# (las flechas siempre mueven al jugador, además de la tecla configurada).
const EXTRA_KEYS := {
	"move_left": [KEY_LEFT],
	"move_right": [KEY_RIGHT],
	"move_down": [KEY_DOWN],
}

static var brightness: float = 1.0
static var master_volume: float = 0.8
static var music_volume: float = 1.0
static var sfx_volume: float = 1.0
static var fullscreen: bool = false
static var bindings: Dictionary = {}
static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_reset_bindings()
	GamepadBindings.apply()
	if _is_headless():
		return

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	brightness = clampf(
		float(config.get_value("video", "brightness", brightness)),
		MIN_BRIGHTNESS,
		MAX_BRIGHTNESS
	)
	master_volume = clampf(
		float(config.get_value("audio", "master_volume", master_volume)),
		0.0,
		1.0
	)
	music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	for action in CONTROLS:
		var keycode := int(config.get_value("controls", action, bindings[action]))
		if keycode > 0:
			bindings[action] = keycode
	_apply_bindings()
	if fullscreen:
		apply_display()


static func save() -> void:
	if _is_headless():
		return
	var config := ConfigFile.new()
	config.set_value("video", "brightness", brightness)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("video", "fullscreen", fullscreen)
	for action in CONTROLS:
		config.set_value("controls", action, int(bindings[action]))
	config.save(CONFIG_PATH)


static func set_brightness(value: float) -> void:
	brightness = clampf(value, MIN_BRIGHTNESS, MAX_BRIGHTNESS)
	save()


static func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save()


static func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save()


static func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save()


static func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_display()
	save()


static func apply_display() -> void:
	if _is_headless():
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


static func ensure_audio_buses() -> void:
	## Crea los buses Music y SFX (cuelgan de Master) si todavía no existen.
	if _is_headless():
		return
	for bus_name in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


static func apply_brightness(canvas: CanvasModulate) -> void:
	if canvas == null:
		return
	canvas.color = Color(brightness, brightness, brightness, 1.0)


static func apply_audio() -> void:
	if _is_headless():
		return
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	ensure_audio_buses()
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_apply_bus_volume(BUS_SFX, sfx_volume)


static func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0.001)


static func get_keycode(action: String) -> int:
	ensure_loaded()
	return int(bindings.get(action, DEFAULT_KEYS.get(action, KEY_NONE)))


static func get_key_label(action: String) -> String:
	var keycode := get_keycode(action)
	return OS.get_keycode_string(keycode) if keycode != KEY_NONE else "Sin asignar"


static func set_key(action: String, keycode: int) -> void:
	if not DEFAULT_KEYS.has(action) or keycode == KEY_NONE:
		return
	ensure_loaded()
	bindings[action] = keycode
	_set_action_key(action, keycode)
	save()


static func reset_controls() -> void:
	_reset_bindings()
	_apply_bindings()
	save()


static func _reset_bindings() -> void:
	bindings.clear()
	for action in CONTROLS:
		bindings[action] = int(DEFAULT_KEYS[action])


static func _apply_bindings() -> void:
	for action in CONTROLS:
		_set_action_key(action, int(bindings[action]))


static func _set_action_key(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
	# Conserva las teclas secundarias (flechas) junto a la principal.
	for extra_key in EXTRA_KEYS.get(action, []):
		var extra_event := InputEventKey.new()
		extra_event.physical_keycode = extra_key
		InputMap.action_add_event(action, extra_event)
	GamepadBindings.apply_action(action)


static func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
