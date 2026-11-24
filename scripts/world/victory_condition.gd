class_name VictoryCondition
extends Node2D
## Condición de victoria alternativa (2026-11-24): bloquea el portal de salida
## hasta que se cumpla algo claro. Modos:
##  - CHANNEL: todas las palancas/botones del `channel` activos.
##  - KEYS: todas las llaves (`KeyPickup`) recogidas.
##  - ENEMIES: no queda ningún enemigo del grupo `arena_enemies`.
## Muestra el progreso sobre el portal ("LLAVES 1/3"). El nodo se coloca en la
## posición del portal; lo busca en el grupo `exit_portals`.

signal fulfilled

enum Mode { CHANNEL, KEYS, ENEMIES }

@export var mode: Mode = Mode.KEYS
@export var channel: String = "A"

var is_fulfilled: bool = false

var _portal: ExitPortal
var _label: Label
var _scan_left: float = 0.0
var _enemy_total: int = 0


func _ready() -> void:
	add_to_group("victory_conditions")
	_label = Label.new()
	_label.size = Vector2(240.0, 22.0)
	_label.position = Vector2(-120.0, -118.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color("#ffe9a8"))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	_bind.call_deferred()


func _bind() -> void:
	_portal = get_tree().get_first_node_in_group("exit_portals") as ExitPortal
	if _portal != null:
		global_position = _portal.global_position
		_portal.set_locked(true)
	_enemy_total = get_tree().get_nodes_in_group("arena_enemies").size()
	_evaluate()


func _physics_process(delta: float) -> void:
	if is_fulfilled:
		return
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = 0.15
		_evaluate()


## Devuelve (hecho, total) según el modo.
func progress() -> Vector2i:
	match mode:
		Mode.CHANNEL:
			var total := 0
			var done := 0
			for lever in get_tree().get_nodes_in_group("levers"):
				if lever is LeverSwitch and (lever as LeverSwitch).channel == channel:
					total += 1
					if (lever as LeverSwitch).is_on:
						done += 1
			return Vector2i(done, total)
		Mode.KEYS:
			var keys := get_tree().get_nodes_in_group("keys")
			var got := 0
			for key in keys:
				if (key as KeyPickup).is_collected:
					got += 1
			return Vector2i(got, keys.size())
	var alive := get_tree().get_nodes_in_group("arena_enemies").size()
	return Vector2i(maxi(_enemy_total - alive, 0), _enemy_total)


func _word() -> String:
	match mode:
		Mode.CHANNEL:
			return "INTERRUPTORES"
		Mode.KEYS:
			return "LLAVES"
	return "ENEMIGOS DERROTADOS"


func _evaluate() -> void:
	var p := progress()
	_label.text = "%s %d/%d" % [_word(), p.x, p.y]
	if p.y > 0 and p.x >= p.y and not is_fulfilled:
		is_fulfilled = true
		_label.text = "¡SALIDA ABIERTA!"
		if _portal != null:
			_portal.set_locked(false)
		Sfx.play("portal", -6.0)
		fulfilled.emit()
