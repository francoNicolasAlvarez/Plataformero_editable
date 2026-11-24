class_name TimedPlatform
extends Hazard
## Plataforma temporizada (2026-11-23, mundo 5): ciclo continuo. Está sólida
## `solid_time` s; después parpadea `warning_time` s (aún sólida, aviso) y
## desaparece `gone_time` s; reaparece con un fundido corto. `initial_delay`
## (fase) desfasa varias plataformas para formar una "escalera" de tiempos.
## Reutiliza la máquina de estados de Hazard: el tramo sólido estable es
## COOLDOWN, el aviso es WARNING y el hueco es ACTIVE. El nodo está en el
## centro de la plataforma y se construye por código.

@export var platform_size: Vector2 = Vector2(140.0, 24.0)
@export var platform_color: Color = Color("#8fb7d9")
@export_range(0.5, 10.0, 0.1) var solid_time: float = 2.5
@export_range(0.5, 5.0, 0.1) var gone_time: float = 1.6

var body: StaticBody2D
var _shape: CollisionShape2D
var _visual: Node2D
var _time: float = 0.0


func _init() -> void:
	warning_time = 0.7
	auto_cycle = true


func _ready() -> void:
	super._ready()
	active_time = gone_time
	cooldown_time = solid_time
	_build()


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
	slab.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	_visual.add_child(slab)
	var top := Polygon2D.new()
	top.color = platform_color.lightened(0.3)
	top.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, -half.y + 4.0), Vector2(-half.x, -half.y + 4.0)])
	_visual.add_child(top)
	var outline := Line2D.new()
	outline.points = slab.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	_visual.add_child(outline)
	# Reloj: franja inferior que se vacía durante el tramo sólido.
	var bar := Polygon2D.new()
	bar.name = "Clock"
	bar.color = Color(1.0, 1.0, 1.0, 0.55)
	bar.polygon = PackedVector2Array([Vector2(-half.x + 4.0, half.y - 5.0), Vector2(half.x - 4.0, half.y - 5.0), Vector2(half.x - 4.0, half.y - 2.0), Vector2(-half.x + 4.0, half.y - 2.0)])
	_visual.add_child(bar)


func _process(delta: float) -> void:
	_time += delta
	if _visual == null:
		return
	match state:
		State.WARNING:
			_visual.modulate.a = 0.45 + 0.4 * (0.5 + 0.5 * sin(_time * (14.0 + 20.0 * warning_progress())))
		State.ACTIVE:
			_visual.modulate.a = 0.12
		_:
			_visual.modulate.a = 1.0


func _on_state_entered(new_state: int) -> void:
	if _shape == null:
		return
	_shape.set_deferred("disabled", new_state == State.ACTIVE)


func _on_reset() -> void:
	if _shape != null:
		_shape.set_deferred("disabled", false)
	if _visual != null:
		_visual.modulate.a = 1.0


## Indica si sostiene al jugador ahora mismo.
func is_solid() -> bool:
	return state != State.ACTIVE
