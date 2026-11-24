class_name SwitchGate
extends StaticBody2D
## Compuerta (2026-11-23): bloquea el paso hasta que todas las palancas
## (`LeverSwitch`) de su `channel` están activas; entonces se abre (desaparece
## con un fundido) para siempre. Muestra un contador "PALANCAS n/total".
## El nodo está en el centro de la compuerta.

signal opened

@export var channel: String = "A"
@export var gate_size: Vector2 = Vector2(48.0, 288.0)
@export var gate_color: Color = Color("#6f6a85")
## Palabra del contador ("PALANCAS", "BOTONES"...).
@export var counter_word: String = "PALANCAS"

var is_open: bool = false

var _shape: CollisionShape2D
var _visual: Node2D
var _label: Label


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("gates")
	_build()
	# Diferido: las palancas pueden crearse después que la compuerta.
	_connect_levers.call_deferred()
	_label.text = "%s 0/?" % counter_word


func _connect_levers() -> void:
	for lever in get_tree().get_nodes_in_group("levers"):
		_connect_lever(lever)
	_refresh()


func _connect_lever(lever: Node) -> void:
	if lever is LeverSwitch and (lever as LeverSwitch).channel == channel and not (lever as LeverSwitch).activated.is_connected(_on_lever_activated):
		(lever as LeverSwitch).activated.connect(_on_lever_activated)


func levers() -> Array:
	var result: Array = []
	for lever in get_tree().get_nodes_in_group("levers"):
		if lever is LeverSwitch and (lever as LeverSwitch).channel == channel:
			result.append(lever)
	return result


func active_count() -> int:
	var count := 0
	for lever in levers():
		if (lever as LeverSwitch).is_on:
			count += 1
	return count


func _on_lever_activated(_lever: LeverSwitch) -> void:
	_refresh()


func _refresh() -> void:
	var total := levers().size()
	var active := active_count()
	_label.text = "%s %d/%d" % [counter_word, active, total]
	if not is_open and total > 0 and active >= total:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_shape.set_deferred("disabled", true)
	Sfx.play("portal", -10.0)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.6)
	_label.text = "ABIERTO"
	opened.emit()


func _build() -> void:
	_shape = CollisionShape2D.new()
	_shape.name = "GateShape"
	var rectangle := RectangleShape2D.new()
	rectangle.size = gate_size
	_shape.shape = rectangle
	add_child(_shape)
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var half := gate_size * 0.5
	var slab := Polygon2D.new()
	slab.color = gate_color
	slab.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	_visual.add_child(slab)
	var bars := 4
	for i in bars:
		var bar := Line2D.new()
		var y := -half.y + (float(i) + 0.5) * gate_size.y / float(bars)
		bar.points = PackedVector2Array([Vector2(-half.x, y), Vector2(half.x, y)])
		bar.width = 3.0
		bar.default_color = Color(0.1, 0.1, 0.15, 0.7)
		_visual.add_child(bar)
	var outline := Line2D.new()
	outline.points = slab.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	_visual.add_child(outline)
	_label = Label.new()
	_label.name = "Counter"
	_label.position = Vector2(-64.0, -half.y - 28.0)
	_label.size = Vector2(128.0, 22.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)
