class_name Drawbridge
extends AnimatableBody2D
## Puente levadizo (2026-11-24, mundo 6): empieza levantado (un muro vertical que
## bloquea el paso). Cuando todas las palancas/botones de su `channel` están
## activos baja en 0,8 s y se puede cruzar; pasados `raise_after` s vuelve a
## subir y deja los interruptores listos para activarse de nuevo (0 = se queda
## abajo). Con `hinge_side` 1 el tablero cuelga de la bisagra hacia la derecha,
## con -1 hacia la izquierda. El nodo está en la bisagra.

signal lowered
signal raised

@export var channel: String = "A"
@export var bridge_size: Vector2 = Vector2(260.0, 24.0)
@export var hinge_side: float = 1.0
@export_range(0.0, 60.0, 0.5) var raise_after: float = 8.0
@export var bridge_color: Color = Color("#8a5a32")

var is_down: bool = false

var _time_left: float = 0.0
var _tween: Tween
var _label: Label
var _body: Node2D


func _ready() -> void:
	add_to_group("drawbridges")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = bridge_size
	shape.shape = rectangle
	shape.position = Vector2(hinge_side * bridge_size.x * 0.5, 0.0)
	add_child(shape)
	_body = Node2D.new()
	add_child(_body)
	var half := bridge_size * 0.5
	var plank := Polygon2D.new()
	plank.color = bridge_color
	var cx := hinge_side * half.x
	plank.polygon = PackedVector2Array([Vector2(cx - half.x, -half.y), Vector2(cx + half.x, -half.y), Vector2(cx + half.x, half.y), Vector2(cx - half.x, half.y)])
	_body.add_child(plank)
	var outline := Line2D.new()
	outline.points = plank.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	_body.add_child(outline)
	for i in 6:
		var x := cx - half.x + (float(i) + 0.5) * bridge_size.x / 6.0
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(x, -half.y), Vector2(x, half.y)])
		line.width = 2.0
		line.default_color = Color(0.2, 0.12, 0.05, 0.7)
		_body.add_child(line)
	_label = Label.new()
	_label.size = Vector2(150.0, 20.0)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	rotation = _up_rotation()
	_label.rotation = -rotation
	_place_label()


func _up_rotation() -> float:
	return -hinge_side * PI * 0.5


func _place_label() -> void:
	_label.rotation = -rotation
	_label.position = Vector2(-75.0, -bridge_size.x - 30.0) if not is_down else Vector2(hinge_side * bridge_size.x * 0.5 - 75.0, -44.0)


func _physics_process(delta: float) -> void:
	_label.rotation = -rotation
	if not is_down:
		var total := 0
		var active := 0
		for lever in get_tree().get_nodes_in_group("levers"):
			if lever is LeverSwitch and (lever as LeverSwitch).channel == channel:
				total += 1
				if (lever as LeverSwitch).is_on:
					active += 1
		_label.text = "PUENTE %d/%d" % [active, total]
		if total > 0 and active >= total:
			lower()
	elif raise_after > 0.0:
		_time_left -= delta
		_label.text = "PUENTE %ds" % ceili(maxf(_time_left, 0.0))
		if _time_left <= 0.0:
			raise_bridge()


func lower() -> void:
	if is_down:
		return
	is_down = true
	_time_left = raise_after
	_animate(0.0)
	_place_label()
	lowered.emit()


func raise_bridge() -> void:
	if not is_down:
		return
	is_down = false
	for lever in get_tree().get_nodes_in_group("levers"):
		if lever is LeverSwitch and (lever as LeverSwitch).channel == channel:
			(lever as LeverSwitch).reset()
	_animate(_up_rotation())
	_place_label()
	raised.emit()


## Vuelve a su estado inicial (levantado) al morir el jugador.
func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	is_down = false
	rotation = _up_rotation()
	_place_label()


func _animate(target_rotation: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation", target_rotation, 0.8).set_trans(Tween.TRANS_SINE)
	Sfx.play("portal", -10.0)
