class_name CrumblingPlatform
extends Hazard
## Plataforma que se derrumba (Fase 4, 2026-11-18): al pisarla tiembla y se
## agrieta `warning_time` (0,6 s de margen para saltar), cae y desaparece
## `active_time` (2,5 s) y reaparece con un fundido (`cooldown_time`). Sin
## ciclo automático: solo reacciona al jugador. `reset()` la deja entera.
## El nodo está en el centro de la plataforma; se construye por código.

@export var platform_size: Vector2 = Vector2(150.0, 24.0)
@export var platform_color: Color = Color("#7d7a8c")

var body: StaticBody2D
var trigger_area: Area2D
var _shape: CollisionShape2D
var _visual: Node2D
var _cracks: Line2D
var _time: float = 0.0


func _ready() -> void:
	super._ready()
	auto_cycle = false
	warning_time = 0.6
	active_time = 2.5
	cooldown_time = 0.4
	_build()
	set_process(false)  # solo se anima al agrietarse y caer


func _build() -> void:
	body = StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	_shape = CollisionShape2D.new()
	_shape.name = "BodyShape"
	var rectangle := RectangleShape2D.new()
	rectangle.size = platform_size
	_shape.shape = rectangle
	body.add_child(_shape)

	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var half := platform_size * 0.5
	var slab := Polygon2D.new()
	slab.color = platform_color
	slab.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x - 8.0, half.y), Vector2(-half.x + 8.0, half.y),
	])
	_visual.add_child(slab)
	var top := Polygon2D.new()
	top.color = platform_color.lightened(0.25)
	top.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, -half.y + 4.0), Vector2(-half.x, -half.y + 4.0),
	])
	_visual.add_child(top)
	_cracks = Line2D.new()
	_cracks.name = "Cracks"
	_cracks.points = PackedVector2Array([
		Vector2(-half.x * 0.4, -half.y), Vector2(-half.x * 0.25, 0.0), Vector2(-half.x * 0.45, half.y),
		Vector2(half.x * 0.3, -half.y), Vector2(half.x * 0.15, 2.0), Vector2(half.x * 0.35, half.y),
	])
	_cracks.width = 2.0
	_cracks.default_color = Color(0.1, 0.08, 0.12, 0.35)
	_visual.add_child(_cracks)
	var outline := Line2D.new()
	outline.name = "Outline"
	outline.points = slab.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	_visual.add_child(outline)

	trigger_area = Area2D.new()
	trigger_area.name = "Trigger"
	trigger_area.collision_layer = 0
	trigger_area.collision_mask = 2
	trigger_area.position = Vector2(0.0, -half.y - 6.0)
	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(platform_size.x - 10.0, 14.0)
	trigger_shape.shape = trigger_rect
	trigger_area.add_child(trigger_shape)
	add_child(trigger_area)
	trigger_area.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(other: Node2D) -> void:
	if other is Player:
		trigger()


func _process(delta: float) -> void:
	_time += delta
	if state == State.WARNING:
		_visual.position = Vector2(sin(_time * 90.0) * 2.2, 0.0)
		_cracks.default_color.a = 0.35 + 0.5 * warning_progress()
	elif state == State.ACTIVE:
		_visual.position.y += 520.0 * delta
		_visual.modulate.a = maxf(0.0, _visual.modulate.a - delta * 2.5)


func _on_state_entered(new_state: int) -> void:
	set_process(new_state == State.WARNING or new_state == State.ACTIVE)
	match new_state:
		State.ACTIVE:
			_shape.set_deferred("disabled", true)
		State.COOLDOWN:
			_restore_visual()
			_visual.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(_visual, "modulate:a", 1.0, cooldown_time)
		State.IDLE:
			_shape.set_deferred("disabled", false)


func _on_reset() -> void:
	set_process(false)
	_restore_visual()
	_visual.modulate.a = 1.0
	if _shape != null:
		_shape.set_deferred("disabled", false)


func _restore_visual() -> void:
	_visual.position = Vector2.ZERO
	_cracks.default_color.a = 0.35


## Indica si la plataforma sostiene al jugador ahora mismo.
func is_solid() -> bool:
	return _shape != null and not _shape.disabled
