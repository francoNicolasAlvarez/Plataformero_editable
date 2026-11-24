class_name LeverSwitch
extends Area2D
## Palanca (2026-11-23): al tocarla el jugador se activa (se queda activada).
## Las palancas de un mismo `channel` abren las compuertas (`SwitchGate`) de
## ese canal cuando están todas activas. El nodo está a ras de suelo. Sirve
## para los niveles no lineales: se pueden activar en cualquier orden.

signal activated(lever: LeverSwitch)

@export var channel: String = "A"

var is_on: bool = false

var _handle: Polygon2D
var _lamp: Polygon2D


func _ready() -> void:
	add_to_group("levers")
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(50.0, 60.0)
	shape.shape = rectangle
	shape.position = Vector2(0.0, -30.0)
	add_child(shape)
	_build_visual()
	body_entered.connect(_on_body_entered)


func _build_visual() -> void:
	var base := Polygon2D.new()
	base.color = Color("#55586a")
	base.polygon = PackedVector2Array([Vector2(-18.0, 0.0), Vector2(-14.0, -12.0), Vector2(14.0, -12.0), Vector2(18.0, 0.0)])
	add_child(base)
	var outline := Line2D.new()
	outline.points = base.polygon
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	add_child(outline)
	_handle = Polygon2D.new()
	_handle.color = Color("#d9d9e6")
	_handle.polygon = PackedVector2Array([Vector2(-3.0, -10.0), Vector2(3.0, -10.0), Vector2(3.0, -44.0), Vector2(-3.0, -44.0)])
	_handle.rotation_degrees = -35.0
	add_child(_handle)
	_lamp = Polygon2D.new()
	_lamp.color = Color("#d94b4b")
	var points := PackedVector2Array()
	for i in 12:
		points.append(Vector2.from_angle(TAU * float(i) / 12.0) * 7.0)
	_lamp.polygon = points
	_lamp.position = Vector2(0.0, -52.0)
	_handle.add_child(_lamp)
	_lamp.position = Vector2(0.0, -46.0)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_on and _accepts(body as Player):
		activate()


## Sonido al activarse (los botones usan otro).
func _sound_name() -> String:
	return "ui"


## Las subclases (p. ej. `FloorButton`) pueden exigir otra condición.
func _accepts(_player: Player) -> bool:
	return true


## Las subclases con otro dibujo redefinen este método.
func _apply_visual(on: bool) -> void:
	if _handle != null:
		_handle.rotation_degrees = 35.0 if on else -35.0
	if _lamp != null:
		_lamp.color = Color("#57e389") if on else Color("#d94b4b")


func activate() -> void:
	if is_on:
		return
	is_on = true
	_apply_visual(true)
	Sfx.play(_sound_name(), -4.0)
	activated.emit(self)


## Vuelve a su estado inicial (lo usan los tests; el nivel no lo llama al morir).
func reset() -> void:
	is_on = false
	_apply_visual(false)
