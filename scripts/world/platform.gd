@tool
class_name Platform
extends AnimatableBody2D
## Asset modular de plataformas (2026-11-13): reúne los cinco tipos pedidos
## para los niveles nuevos y sustituye a la plataforma estática anterior.
## Tipos: STATIC (fija), HORIZONTAL (vaivén izquierda-derecha), CIRCULAR
## (órbita en sentido horario), SPIKED (fija con pinchos solo en los bordes)
## y ROTATING (oscila sobre su eje sin superar 30°).
## El tamaño y el color se editan desde el Inspector; la colisión y el dibujo
## se regeneran solos (contorno negro añadido el 2026-11-16). Las
## plataformas móviles quedan fuera de la regla de espaciado estático
## (PlatformSpacing.is_moving()).

enum Kind { STATIC, HORIZONTAL, CIRCULAR, SPIKED, ROTATING }

const SPIKE_SCENE := preload("res://scenes/world/spike_trap.tscn")
const PLATFORM_TEXTURE := preload("res://scripts/world/platform_texture.gd")
const MAX_TILT_RADIANS := PI / 6.0
const SPIKE_SOURCE_WIDTH := 140.0

@export var kind: Kind = Kind.STATIC:
	set(value):
		kind = value
		if is_inside_tree():
			sync_to_physics = is_moving()
		_refresh()

@export var platform_size: Vector2 = Vector2(200.0, 24.0):
	set(value):
		platform_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh()

@export var platform_color: Color = Color("#355070"):
	set(value):
		platform_color = value
		_refresh()

@export var travel: Vector2 = Vector2(140.0, 0.0)
@export_range(0.1, 5.0, 0.05) var speed: float = 1.0
@export_range(0.0, 300.0, 1.0) var circle_radius: float = 0.0
@export_range(0.0, 5.0, 0.05) var circle_speed: float = 1.0
@export_range(-6.0, 6.0, 0.05) var rotation_speed: float = 0.0
@export_range(1, 99, 1) var spike_damage: int = 15
## Cinta transportadora (2026-11-23): arrastra a quien está encima a esta
## velocidad horizontal (px/s; el signo es el sentido). 0 = plataforma normal.
@export_range(-800.0, 800.0, 5.0) var conveyor_speed: float = 0.0:
	set(value):
		conveyor_speed = value
		constant_linear_velocity = Vector2(value, 0.0)
		_refresh()

var _origin: Vector2
var _time: float = 0.0
var _base_rotation: float = 0.0


func _ready() -> void:
	_origin = position
	_base_rotation = clampf(rotation, -MAX_TILT_RADIANS, MAX_TILT_RADIANS)
	rotation = _base_rotation
	sync_to_physics = is_moving()
	_refresh()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_moving():
		return
	_time += delta
	match kind:
		Kind.HORIZONTAL:
			position = _origin + travel * (0.5 - 0.5 * cos(_time * speed))
		Kind.CIRCULAR:
			var angle := _time * circle_speed
			position = _origin + Vector2(cos(angle), sin(angle)) * circle_radius
		Kind.ROTATING:
			rotation = _base_rotation + sin(_time * rotation_speed) * MAX_TILT_RADIANS


func is_moving() -> bool:
	return kind == Kind.HORIZONTAL or kind == Kind.CIRCULAR or kind == Kind.ROTATING


func _refresh() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if visual != null:
		var half := platform_size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		visual.color = platform_color

	# Vestido 2026-11-11: franja iluminada en el borde superior y sombra en la
	# base para que las plataformas lean como bloques con volumen.
	var top := get_node_or_null("TopHighlight") as Polygon2D
	if top == null:
		top = Polygon2D.new()
		top.name = "TopHighlight"
		add_child(top)
	var bottom := get_node_or_null("BottomShadow") as Polygon2D
	if bottom == null:
		bottom = Polygon2D.new()
		bottom.name = "BottomShadow"
		add_child(bottom)

	var half := platform_size * 0.5
	var top_height := clampf(platform_size.y * 0.22, 2.0, 5.0)
	top.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, -half.y + top_height),
		Vector2(-half.x, -half.y + top_height),
	])
	top.color = platform_color.lightened(0.22)

	var bottom_height := clampf(platform_size.y * 0.16, 2.0, 4.0)
	var base_dark := platform_color.darkened(0.45)
	bottom.polygon = PackedVector2Array([
		Vector2(-half.x, half.y - bottom_height),
		Vector2(half.x, half.y - bottom_height),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	bottom.color = Color(base_dark.r, base_dark.g, base_dark.b, 0.65)

	# Textura procedural sutil (2026-11-16): vetas y motas bajo los remates.
	PLATFORM_TEXTURE.apply(self, platform_size, platform_color)

	# Black outline (2026-11-16): separates the platform from the background
	# and from other basic geometric shapes.
	var outline := get_node_or_null("Outline") as Line2D
	if outline == null:
		outline = Line2D.new()
		outline.name = "Outline"
		add_child(outline)
	outline.width = 3.0
	outline.default_color = Color(0.0, 0.0, 0.0, 1.0)
	outline.closed = true
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
	outline.end_cap_mode = Line2D.LINE_CAP_ROUND
	outline.antialiased = true
	outline.points = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	move_child(outline, -1)

	if collision != null:
		var shape := collision.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			collision.shape = shape
		shape.size = platform_size

	_refresh_conveyor()
	_refresh_spikes()


func _refresh_conveyor() -> void:
	## Banda de fábrica animada (3 fotogramas) sobre la plataforma; el sentido
	## sigue el signo de `conveyor_speed`.
	var belt := get_node_or_null("ConveyorBelt")
	if belt != null:
		belt.free()
	if is_zero_approx(conveyor_speed):
		return
	var visual := ConveyorVisual.new()
	visual.name = "ConveyorBelt"
	add_child(visual)
	visual.configure(platform_size, conveyor_speed)
	var outline := get_node_or_null("Outline")
	if outline != null:
		move_child(outline, -1)


func _refresh_spikes() -> void:
	var edge_width := minf(platform_size.x * 0.28, 56.0)
	var spike_y := -platform_size.y * 0.5 - 8.0
	for side in [-1.0, 1.0]:
		var spike_name := "SpikeLeft" if side < 0.0 else "SpikeRight"
		var spike := get_node_or_null(spike_name) as Area2D
		if spike == null:
			spike = SPIKE_SCENE.instantiate() as Area2D
			spike.name = spike_name
			add_child(spike)
		spike.position = Vector2(side * (platform_size.x * 0.5 - edge_width * 0.5), spike_y)
		spike.scale = Vector2(edge_width / SPIKE_SOURCE_WIDTH, 1.0)
		spike.set("damage", spike_damage)
		spike.visible = kind == Kind.SPIKED
		var spike_shape := spike.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if spike_shape != null:
			spike_shape.set_deferred("disabled", kind != Kind.SPIKED)
		spike.set_deferred("monitoring", kind == Kind.SPIKED)
