class_name ChannelLock
extends Node2D
## Candado de enemigo (2026-11-24): protege a un enemigo (`target`, ruta a un
## nodo hermano) con un escudo cian. Mientras queden palancas o botones sin
## activar en su `channel` el enemigo es invulnerable (meta `channel_locked`:
## las rocas lanzadas rebotan en él); al activarlos todos el escudo estalla y el
## enemigo cae. Es la forma de "eliminar" enemigos cumpliendo una condición
## clara. Muestra "n/total" sobre el enemigo.

signal released

@export var channel: String = "A"
@export var target: NodePath
@export var counter_word: String = ""

var is_released: bool = false

var _enemy: Node2D
var _label: Label
var _time: float = 0.0


func _ready() -> void:
	add_to_group("channel_locks")
	z_index = 5
	_label = Label.new()
	_label.size = Vector2(120.0, 20.0)
	_label.position = Vector2(-60.0, -86.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color("#9be8ff"))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)
	_bind.call_deferred()


func _bind() -> void:
	_enemy = get_node_or_null(target) as Node2D
	if _enemy != null:
		_enemy.set_meta("channel_locked", true)
	_refresh()


func _physics_process(_delta: float) -> void:
	if is_released:
		return
	if _enemy == null:
		_bind()
		if _enemy == null:
			return
	if not is_instance_valid(_enemy):
		queue_free()
		return
	global_position = _enemy.global_position
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	if not is_released:
		queue_redraw()


func counts() -> Vector2i:
	var total := 0
	var active := 0
	for lever in get_tree().get_nodes_in_group("levers"):
		if lever is LeverSwitch and (lever as LeverSwitch).channel == channel:
			total += 1
			if (lever as LeverSwitch).is_on:
				active += 1
	return Vector2i(active, total)


func _refresh() -> void:
	if is_released or _enemy == null:
		return
	var c := counts()
	_label.text = "%s %d/%d" % [counter_word, c.x, c.y] if not counter_word.is_empty() else "%d/%d" % [c.x, c.y]
	if c.y > 0 and c.x >= c.y:
		release()


func release() -> void:
	if is_released:
		return
	is_released = true
	_label.visible = false
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.set_meta("channel_locked", false)
		Fx.make_burst(get_parent(), _enemy.global_position, Color(0.6, 0.9, 1.0, 0.95))
		var health := _enemy.get_node_or_null("Health") as Health
		if health != null:
			health.take_damage(9999)
		else:
			_enemy.queue_free()
	released.emit()
	queue_redraw()


func _draw() -> void:
	if is_released:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	draw_circle(Vector2(0.0, -4.0), 44.0, Color(0.4, 0.85, 1.0, 0.10 + 0.08 * pulse))
	draw_arc(Vector2(0.0, -4.0), 44.0, 0.0, TAU, 40, Color(0.7, 0.95, 1.0, 0.8), 3.0)
