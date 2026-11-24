@tool
class_name BladeWheel
extends Area2D
## Rueda de cuchillas gigante (2026-11-21): cuatro cuchillas a 90° entre sí
## que giran alrededor del centro. Quita un golpe al tocarla.
## Ajustes en el Inspector:
##  - `clockwise`: sentido de giro (activado = horario, desactivado = antihorario).
##  - `spin_speed`: vueltas por segundo (más alto = más rápida).
##  - `arm_length`: largo de cada cuchilla en px (radio total de la rueda).
##  - `start_angle_degrees`: ángulo inicial (para desfasar varias ruedas).
## En el editor se ve la rueda inmóvil; gira al ejecutar el nivel.

const BLADE_COUNT := 4
const HUB_RADIUS := 30.0

@export var clockwise: bool = true
@export_range(0.05, 3.0, 0.05) var spin_speed: float = 0.5
@export_range(80.0, 600.0, 5.0) var arm_length: float = 200.0:
	set(value):
		arm_length = value
		if is_node_ready():
			_rebuild()
@export_range(0.0, 360.0, 1.0) var start_angle_degrees: float = 0.0:
	set(value):
		start_angle_degrees = value
		if is_node_ready():
			rotation_degrees = value
@export_range(1, 99, 1) var damage: int = 20


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	rotation_degrees = start_angle_degrees
	_rebuild()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	add_to_group("traps")
	add_to_group("blade_wheels")


func _physics_process(delta: float) -> void:
	var direction := 1.0 if clockwise else -1.0
	rotation += direction * spin_speed * TAU * delta
	# Mientras toque al jugador se intenta golpear (la invulnerabilidad evita repetir).
	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(damage, self)


func _rebuild() -> void:
	for child in get_children():
		child.free()

	for i in BLADE_COUNT:
		var angle := float(i) * PI * 0.5
		var points := PackedVector2Array()
		for p in _blade_points():
			points.append(p.rotated(angle))

		var shape_node := CollisionShape2D.new()
		shape_node.name = "BladeShape%d" % i
		var convex := ConvexPolygonShape2D.new()
		convex.points = points
		shape_node.shape = convex
		add_child(shape_node)

		var visual := Polygon2D.new()
		visual.name = "BladeVisual%d" % i
		visual.color = Color("#b9bdc6")
		visual.polygon = points
		add_child(visual)
		var edge := Line2D.new()
		edge.name = "BladeEdge%d" % i
		edge.points = points
		edge.closed = true
		edge.width = 3.0
		edge.default_color = Color.BLACK
		add_child(edge)

	var hub_shape := CollisionShape2D.new()
	hub_shape.name = "HubShape"
	var circle := CircleShape2D.new()
	circle.radius = HUB_RADIUS
	hub_shape.shape = circle
	add_child(hub_shape)
	var hub_points := PackedVector2Array()
	for i in 20:
		hub_points.append(Vector2.from_angle(TAU * float(i) / 20.0) * HUB_RADIUS)
	var hub := Polygon2D.new()
	hub.name = "HubVisual"
	hub.color = Color("#ec3b5a")
	hub.polygon = hub_points
	add_child(hub)
	var hub_edge := Line2D.new()
	hub_edge.name = "HubEdge"
	hub_edge.points = hub_points
	hub_edge.closed = true
	hub_edge.width = 3.0
	hub_edge.default_color = Color.BLACK
	add_child(hub_edge)


## Cuchilla apuntando a +x: base ancha junto al eje y punta en `arm_length`.
func _blade_points() -> PackedVector2Array:
	var base := HUB_RADIUS * 0.6
	return PackedVector2Array([
		Vector2(base, -26.0),
		Vector2(arm_length * 0.55, -34.0),
		Vector2(arm_length, 0.0),
		Vector2(arm_length * 0.55, 34.0),
		Vector2(base, 26.0),
	])
