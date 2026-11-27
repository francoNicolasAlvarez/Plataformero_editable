@tool
class_name LaunchPad
extends Area2D
## Lanzador (2026-11-21): empuja al jugador sin hacerle daño.
##  - Modo BACKWARD: lo lanza hacia atrás (contrario al sentido en que iba o,
##    si estaba parado, contrario a hacia donde miraba). Siempre con un poco
##    de salto (`launch_up`).
##  - Modo FIXED: lo lanza siempre hacia `launch_direction`.
## Las flechas del dibujo señalan la dirección. El nodo está en el centro de la zona.

enum Mode { BACKWARD, FIXED }

@export var mode: Mode = Mode.BACKWARD:
	set(value):
		mode = value
		_refresh()
## Solo en modo FIXED (se normaliza).
@export var launch_direction: Vector2 = Vector2(-1.0, -0.4):
	set(value):
		launch_direction = value
		_refresh()
@export_range(100.0, 2000.0, 10.0) var launch_speed: float = 750.0
## Solo en modo BACKWARD: parte vertical del lanzamiento (0 = horizontal, 1 = 45°).
@export_range(0.0, 1.5, 0.05) var launch_up: float = 0.4
@export_range(0.0, 1.0, 0.05) var control_lock: float = 0.35
@export var zone_size: Vector2 = Vector2(90.0, 30.0):
	set(value):
		zone_size = Vector2(maxf(value.x, 8.0), maxf(value.y, 8.0))
		_refresh()
@export_range(0.0, 2.0, 0.1) var cooldown: float = 0.4

var _visual: Node2D
var _cooldown_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	DrawLayers.behind_ground(self)  # base tapada por el suelo (2026-11-27)
	collision_layer = 0
	collision_mask = 2
	_refresh()
	if Engine.is_editor_hint():
		set_process(false)
		return
	add_to_group("traps")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if _visual != null:
		_visual.modulate.a = 0.7 + 0.3 * sin(_time * 6.0)


func _refresh() -> void:
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "Shape"
		add_child(shape_node)
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape_node.shape = rect

	if _visual != null:
		_visual.free()
	_visual = Node2D.new()
	_visual.name = "Visual"
	var half := zone_size * 0.5
	var pad := Polygon2D.new()
	pad.color = Color(1.0, 0.6, 0.15, 0.4)
	pad.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	_visual.add_child(pad)
	var edge := Line2D.new()
	edge.points = pad.polygon
	edge.closed = true
	edge.width = 3.0
	edge.default_color = Color(1.0, 0.8, 0.35, 0.95)
	_visual.add_child(edge)
	# En BACKWARD el sentido depende del jugador: flechas a ambos lados.
	var directions: Array = [launch_direction.normalized()]
	if mode == Mode.BACKWARD:
		directions = [Vector2.LEFT, Vector2.RIGHT]
	var arrow_size := minf(half.y * 1.2, 16.0)
	for direction in directions:
		var arrow := Polygon2D.new()
		arrow.color = Color(1.0, 0.95, 0.7, 0.95)
		arrow.polygon = PackedVector2Array([Vector2(arrow_size, 0.0), Vector2(-arrow_size * 0.6, -arrow_size * 0.7), Vector2(-arrow_size * 0.2, 0.0), Vector2(-arrow_size * 0.6, arrow_size * 0.7)])
		arrow.rotation = (direction as Vector2).angle()
		arrow.position = (direction as Vector2) * minf(half.x * 0.5, 26.0)
		_visual.add_child(arrow)
	add_child(_visual)


## Dirección del lanzamiento para un jugador concreto.
func launch_vector_for(player: Player) -> Vector2:
	if mode == Mode.FIXED:
		return launch_direction.normalized() * launch_speed
	var side := -signf(player.velocity.x)
	if is_zero_approx(side):
		# Parado: hacia atrás = contrario a hacia donde mira.
		side = 1.0 if player.visual.flip_h else -1.0
	return Vector2(side, -launch_up).normalized() * launch_speed


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or _cooldown_left > 0.0:
		return
	var player := body as Player
	if player.health.is_dead:
		return
	_cooldown_left = cooldown
	player.launch(launch_vector_for(player), control_lock)
	Sfx.play("jump", -6.0)
	Fx.make_burst(get_parent() as Node2D, player.global_position, Color(1.0, 0.75, 0.3))
