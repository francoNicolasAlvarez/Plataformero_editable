class_name GamepadBindings
extends RefCounted
## Mapeo de mando fijo y complementario a las teclas (2026-11-13). Se aplica
## al cargar los ajustes y tras cada rebind para que el mando siga funcionando.

const BUTTON_ACTIONS := {
	"jump": JOY_BUTTON_A,
	"dash": JOY_BUTTON_X,
	"pause": JOY_BUTTON_START,
}

const AXIS_ACTIONS := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}

const DPAD_ACTIONS := {
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
	"move_down": JOY_BUTTON_DPAD_DOWN,
}


static func apply() -> void:
	for action in BUTTON_ACTIONS.keys():
		apply_action(action)
	for action in AXIS_ACTIONS.keys():
		apply_action(action)
	for action in DPAD_ACTIONS.keys():
		apply_action(action)


static func apply_action(action: String) -> void:
	if not InputMap.has_action(action):
		return
	if BUTTON_ACTIONS.has(action):
		_add_button(action, BUTTON_ACTIONS[action])
	if DPAD_ACTIONS.has(action):
		_add_button(action, DPAD_ACTIONS[action])
	if AXIS_ACTIONS.has(action):
		var data: Array = AXIS_ACTIONS[action]
		_add_axis(action, int(data[0]), float(data[1]))


static func _add_button(action: String, button: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


static func _add_axis(action: String, axis: int, value: float) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion \
				and event.axis == axis and is_equal_approx(event.axis_value, value):
			return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)
