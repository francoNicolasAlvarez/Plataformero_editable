@tool
class_name TeleportTrap
extends Area2D
## Trampa de teletransporte (2026-11-21): al tocarla, el jugador vuelve al
## inicio del nivel sin perder vida. El inicio se lee del nivel (meta
## "start_point"); si activas `use_custom_target`, va a `custom_target`
## (posición global) en su lugar. El nodo está en el centro de la zona.

@export var zone_size: Vector2 = Vector2(90.0, 60.0):
	set(value):
		zone_size = Vector2(maxf(value.x, 8.0), maxf(value.y, 8.0))
		_refresh()
@export var use_custom_target: bool = false
@export var custom_target: Vector2 = Vector2.ZERO
@export_range(0.0, 3.0, 0.1) var cooldown: float = 0.8

var _visual: Node2D
var _swirl: Node2D
var _fallback_start: Vector2 = Vector2.ZERO
var _has_fallback: bool = false
var _cooldown_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_refresh()
	if Engine.is_editor_hint():
		set_process(false)
		return
	add_to_group("traps")
	body_entered.connect(_on_body_entered)
	# Si el nivel no publica "start_point", se usa donde está el jugador al empezar.
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		_fallback_start = player.global_position
		_has_fallback = true


func _process(delta: float) -> void:
	_time += delta
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if _visual != null:
		_visual.modulate.a = 0.7 + 0.3 * sin(_time * 4.0)
	if _swirl != null:
		_swirl.rotation = _time * 2.5


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
	var body := Polygon2D.new()
	body.color = Color(0.55, 0.25, 0.95, 0.35)
	body.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	_visual.add_child(body)
	var edge := Line2D.new()
	edge.points = body.polygon
	edge.closed = true
	edge.width = 3.0
	edge.default_color = Color(0.8, 0.55, 1.0, 0.9)
	_visual.add_child(edge)
	_swirl = Node2D.new()
	_swirl.name = "Swirl"
	var radius := minf(half.x, half.y) * 0.7
	for arm in 3:
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = Color(0.9, 0.75, 1.0, 0.9)
		var points := PackedVector2Array()
		for i in 10:
			var t := float(i) / 9.0
			var angle := float(arm) * TAU / 3.0 + t * 2.2
			points.append(Vector2(cos(angle), sin(angle)) * radius * t)
		line.points = points
		_swirl.add_child(line)
	_visual.add_child(_swirl)
	add_child(_visual)


func start_target() -> Vector2:
	if use_custom_target:
		return custom_target
	var node: Node = self
	while node != null:
		if node.has_meta("start_point"):
			return node.get_meta("start_point")
		node = node.get_parent()
	return _fallback_start if _has_fallback else global_position


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or _cooldown_left > 0.0:
		return
	var player := body as Player
	if player.health.is_dead:
		return
	_cooldown_left = cooldown
	var world := get_parent() as Node2D
	Fx.make_burst(world, player.global_position, Color(0.75, 0.5, 1.0))
	player.teleport_to(start_target())
	Fx.make_burst(world, player.global_position, Color(0.75, 0.5, 1.0))
	Sfx.play("portal", -8.0)
	var scene := get_tree().current_scene
	var camera := scene.get_node_or_null("Camera") if scene != null else null
	if camera != null and camera.has_method("snap_to_target"):
		camera.snap_to_target()
