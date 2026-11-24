extends SceneTree
## Comprueba el soporte de mando (2026-11-13): las acciones de juego tienen
## eventos de botón/eje además de las teclas y el rebind no los elimina.
## Ejecutar con:
## godot --headless --path . --script res://tests/gamepad_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	GamepadBindings.apply()
	for action in ["move_left", "move_right", "move_down", "jump", "dash",
			"pause"]:
		_check(_has_joypad_event(action), "La acción %s acepta mando" % action)

	_check(_has_button("jump", JOY_BUTTON_A), "Saltar usa el botón A")
	_check(_has_button("dash", JOY_BUTTON_X), "El impulso usa el botón X")
	_check(_has_button("pause", JOY_BUTTON_START), "Pausa usa Start")
	_check(not InputMap.has_action("item_1") and not InputMap.has_action("inventory"), "No hay acciones de objetos ni inventario")
	_check(_has_axis("move_left", JOY_AXIS_LEFT_X, -1.0), "Mover a la izquierda usa el stick")
	_check(_has_axis("move_right", JOY_AXIS_LEFT_X, 1.0), "Mover a la derecha usa el stick")
	_check(_has_axis("move_down", JOY_AXIS_LEFT_Y, 1.0), "Caer rápido usa el stick")

	GameSettings.set_key("jump", KEY_J)
	_check(_has_button("jump", JOY_BUTTON_A), "Rebind de teclas conserva el botón del mando")
	GameSettings.set_key("jump", KEY_SPACE)

	GamepadBindings.apply()
	_check(_count_joypad_events("jump") == 1, "Aplicar el mapeo dos veces no duplica eventos")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _has_joypad_event(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func _has_button(action: String, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false


func _has_axis(action: String, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion \
				and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false


func _count_joypad_events(action: String) -> int:
	var total := 0
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			total += 1
	return total


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
