class_name CrusherTrap
extends Hazard
## Prensa (2026-11-23): bloque colgado del techo. Al pasar el jugador por
## debajo (`block_size.x` de ancho) tiembla `warning_time` (0,7 s de aviso),
## cae de golpe `drop_height` px y quita un golpe a quien esté debajo; se
## queda abajo `active_time` y sube despacio (`cooldown_time`). Con
## `auto_cycle` actúa sin esperar al jugador. El bloque NO es sólido (así no
## aplasta ni atasca): solo daña mientras cae o está abajo. El nodo está en
## el techo, en el centro del bloque; el bloque cuelga hacia abajo.
##
## 2026-11-26: el bloque es un BLOQUE DE PÚAS (pinchos de punta roja abajo y a
## los lados: forma angular = peligro) y daña al tocarlo en CUALQUIER momento,
## también quieto arriba o mientras sube (contacto continuo; la invulnerabilidad
## del jugador evita golpes repetidos). Sigue sin ser sólido.

@export var block_size: Vector2 = Vector2(90.0, 64.0)
@export_range(60.0, 500.0, 5.0) var drop_height: float = 200.0
@export_range(1, 99, 1) var damage: int = 15

const SPIKE_LENGTH := 14.0
const SPIKE_COLOR := Color("#b9bccb")
const TIP_COLOR := Color("#e0392b")

var _block: Node2D
var _hitbox: Area2D
var _hit_shape: CollisionShape2D
var _trigger: Area2D
var _time: float = 0.0
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
	slab.color = Color("#4f5263")
	# Franjas de aviso amarillas y negras en la cara del bloque.
	var stripes := Polygon2D.new()
	stripes.name = "WarningStripe"
	stripes.color = Color("#f2c744")
	stripes.polygon = PackedVector2Array([Vector2(-half.x + 6.0, block_size.y * 0.35), Vector2(half.x - 6.0, block_size.y * 0.35), Vector2(half.x - 6.0, block_size.y * 0.6), Vector2(-half.x + 6.0, block_size.y * 0.6)])
	_block.add_child(stripes)
	var count := maxi(3, int(block_size.x / 18.0))
	var step := block_size.x / float(count)
	var spike_index := 0
	# Púas de abajo.
	for i in count:
		var x := -half.x + step * float(i)
		_add_spike(Vector2(x, block_size.y), Vector2(x + step, block_size.y), Vector2(x + step * 0.5, block_size.y + SPIKE_LENGTH), spike_index)
		spike_index += 1
	# Púas de los lados.
	var side_count := maxi(2, int(block_size.y / 22.0))
	var side_step := block_size.y / float(side_count)
	for i in side_count:
		var y := side_step * float(i)
		_add_spike(Vector2(-half.x, y), Vector2(-half.x, y + side_step), Vector2(-half.x - SPIKE_LENGTH, y + side_step * 0.5), spike_index)
		spike_index += 1
		_add_spike(Vector2(half.x, y), Vector2(half.x, y + side_step), Vector2(half.x + SPIKE_LENGTH, y + side_step * 0.5), spike_index)
		spike_index += 1
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
	rectangle.size = Vector2(block_size.x + SPIKE_LENGTH * 1.4, block_size.y + SPIKE_LENGTH * 0.8)
	_hit_shape.shape = rectangle
	_hit_shape.position = Vector2(0.0, (block_size.y + SPIKE_LENGTH * 0.8) * 0.5)
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
	# Daña al tocarlo en cualquier estado (bloque de púas).
	if _hitbox != null:
		for other in _hitbox.get_overlapping_bodies():
			if other is Player and not (other as Player).health.is_dead:
				(other as Player).take_damage(damage, self)


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
	if new_state == State.ACTIVE:
		Sfx.play("bomb", -10.0)


func _on_reset() -> void:
	if _block != null:
		_block.position = Vector2.ZERO


## Púa triangular con punta roja y contorno negro (base a-b, punta `tip`).
func _add_spike(a: Vector2, b: Vector2, tip: Vector2, index: int) -> void:
	var spike := Polygon2D.new()
	spike.name = "Spike%d" % index
	spike.color = SPIKE_COLOR
	spike.polygon = PackedVector2Array([a, b, tip])
	_block.add_child(spike)
	var red := Polygon2D.new()
	red.color = TIP_COLOR
	red.polygon = PackedVector2Array([tip.lerp(a, 0.35), tip.lerp(b, 0.35), tip])
	spike.add_child(red)
	var line := Line2D.new()
	line.points = spike.polygon
	line.closed = true
	line.width = 1.6
	line.default_color = Color.BLACK
	spike.add_child(line)
