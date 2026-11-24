class_name CrusherTrap
extends Hazard
## Prensa (2026-11-23): bloque colgado del techo. Al pasar el jugador por
## debajo (`block_size.x` de ancho) tiembla `warning_time` (0,7 s de aviso),
## cae de golpe `drop_height` px y quita un golpe a quien esté debajo; se
## queda abajo `active_time` y sube despacio (`cooldown_time`). Con
## `auto_cycle` actúa sin esperar al jugador. El bloque NO es sólido (así no
## aplasta ni atasca): solo daña mientras cae o está abajo. El nodo está en
## el techo, en el centro del bloque; el bloque cuelga hacia abajo.

@export var block_size: Vector2 = Vector2(90.0, 64.0)
@export_range(60.0, 500.0, 5.0) var drop_height: float = 200.0
@export_range(1, 99, 1) var damage: int = 15

var _block: Node2D
var _hitbox: Area2D
var _hit_shape: CollisionShape2D
var _trigger: Area2D
var _time: float = 0.0
var _hit_done: bool = false
var _slam_time: float = 0.12


func _init() -> void:
	warning_time = 0.7
	active_time = 0.6
	cooldown_time = 1.6
	auto_cycle = false


func _ready() -> void:
	super._ready()
	add_to_group("crushers")
	_build()


func _build() -> void:
	# Cadena del techo al bloque.
	var chain := Line2D.new()
	chain.name = "Chain"
	chain.points = PackedVector2Array([Vector2(0.0, -40.0), Vector2(0.0, 0.0)])
	chain.width = 4.0
	chain.default_color = Color("#3b3d4a")
	add_child(chain)
	_block = Node2D.new()
	_block.name = "Block"
	add_child(_block)
	var half := block_size * 0.5
	var slab := Polygon2D.new()
	slab.color = Color("#6d6f85")
	slab.polygon = PackedVector2Array([Vector2(-half.x, 0.0), Vector2(half.x, 0.0), Vector2(half.x, block_size.y), Vector2(-half.x, block_size.y)])
	_block.add_child(slab)
	var teeth := Polygon2D.new()
	teeth.color = Color("#c9ccd9")
	var points := PackedVector2Array()
	var count := maxi(3, int(block_size.x / 18.0))
	var step := block_size.x / float(count)
	for i in count:
		var x := -half.x + step * float(i)
		points.append(Vector2(x, block_size.y))
		points.append(Vector2(x + step * 0.5, block_size.y + 12.0))
		points.append(Vector2(x + step, block_size.y))
	teeth.polygon = points
	_block.add_child(teeth)
	var outline := Line2D.new()
	outline.points = slab.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	_block.add_child(outline)

	_hitbox = Area2D.new()
	_hitbox.name = "Hitbox"
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hit_shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(block_size.x, block_size.y + 12.0)
	_hit_shape.shape = rectangle
	_hit_shape.position = Vector2(0.0, (block_size.y + 12.0) * 0.5)
	_hit_shape.disabled = true
	_hitbox.add_child(_hit_shape)
	_block.add_child(_hitbox)

	# Zona de detección: la columna que barre el bloque al caer.
	_trigger = Area2D.new()
	_trigger.name = "Trigger"
	_trigger.collision_layer = 0
	_trigger.collision_mask = 2
	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(block_size.x + 20.0, drop_height + block_size.y)
	trigger_shape.shape = trigger_rect
	trigger_shape.position = Vector2(0.0, (drop_height + block_size.y) * 0.5)
	_trigger.add_child(trigger_shape)
	add_child(_trigger)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.IDLE and not auto_cycle and _trigger != null:
		for other in _trigger.get_overlapping_bodies():
			if other is Player and not (other as Player).health.is_dead:
				trigger()
				break
	if state == State.ACTIVE and not _hit_done:
		_hit_shape.set_deferred("disabled", false)
		for other in _hitbox.get_overlapping_bodies():
			if other is Player:
				(other as Player).take_damage(damage, self)
				_hit_done = true


func _process(delta: float) -> void:
	_time += delta
	if _block == null:
		return
	match state:
		State.IDLE:
			_block.position = Vector2.ZERO
		State.WARNING:
			_block.position = Vector2(sin(_time * 80.0) * 2.5, 0.0)
		State.ACTIVE:
			var fall := clampf(_state_time / _slam_time, 0.0, 1.0)
			_block.position = Vector2(0.0, drop_height * fall * fall)
		State.COOLDOWN:
			var rise := clampf(_state_time / maxf(cooldown_time, 0.01), 0.0, 1.0)
			_block.position = Vector2(0.0, drop_height * (1.0 - rise))


func _on_state_entered(new_state: int) -> void:
	_hit_done = false
	if new_state == State.ACTIVE:
		Sfx.play("bomb", -10.0)
	elif _hit_shape != null:
		_hit_shape.set_deferred("disabled", true)


func _on_reset() -> void:
	_hit_done = false
	if _block != null:
		_block.position = Vector2.ZERO
	if _hit_shape != null:
		_hit_shape.set_deferred("disabled", true)
