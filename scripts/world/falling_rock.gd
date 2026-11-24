class_name FallingRock
extends Area2D
## Roca que cae (2026-11-17, rediseñada el 2026-11-23). La roca cuelga visible
## en el borde superior de la pantalla, con clavos de hierro y llamas (así no
## parece una plataforma donde se pueda pisar), y un marcador rojo en la
## superficie donde va a impactar. CAE `TRIGGER_DELAY` (0,2 s) después de que
## el jugador se coloque debajo de ella (a menos de `TRIGGER_HALF_WIDTH` px en
## horizontal). Si nadie se coloca debajo cae sola tras `MAX_WAIT` s para no
## acumularse. Daña al jugador (un golpe) y se rompe contra el primer suelo o
## plataforma. Se construye entera por código, sin escena propia.
##
## Estados: WARNING = colgada y armada (esperando), FALLING = cayendo, DONE.

const TRIGGER_DELAY := 0.2
const TRIGGER_HALF_WIDTH := 70.0
const MAX_WAIT := 3.5
const FALL_SPEED := 1500.0
const OVERSHOOT := 260.0
const SPIKE_COUNT := 12

enum State { WARNING, FALLING, DONE }

@export var damage: int = 15

var target_y: float = 0.0
var start_y: float = 0.0
var state: State = State.WARNING

var _time: float = 0.0
var _trigger_left: float = -1.0
var _marker: Node2D
var _rock: Node2D
var _flames: Array[Polygon2D] = []
var _glow: Polygon2D


func _ready() -> void:
	add_to_group("falling_rocks")
	collision_layer = 0
	collision_mask = 3
	set_deferred("monitoring", false)
	body_entered.connect(_on_body_entered)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	add_child(shape)

	_rock = _build_rock()
	add_child(_rock)

	_marker = _build_marker()
	_marker.top_level = true
	add_child(_marker)
	_marker.global_position = Vector2(global_position.x, target_y)
	global_position.y = start_y


static func clear_rocks(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("falling_rocks"):
		node.queue_free()


## Cierto cuando el jugador ya se colocó debajo y la cuenta de 0,2 s corre.
func is_triggered() -> bool:
	return _trigger_left >= 0.0


## Segundos que faltan para que empiece a caer (solo si está activada).
func fall_in() -> float:
	return maxf(0.0, _trigger_left) if state == State.WARNING and is_triggered() else 0.0


func _physics_process(delta: float) -> void:
	match state:
		State.WARNING:
			_time += delta
			if not is_triggered() and _player_below():
				_trigger_left = TRIGGER_DELAY
			if is_triggered():
				_trigger_left -= delta
				if _trigger_left <= 0.0:
					_start_falling()
			elif _time >= MAX_WAIT:
				_start_falling()
			_update_marker()
		State.FALLING:
			global_position.y += FALL_SPEED * delta
			if global_position.y >= target_y + OVERSHOOT:
				_impact()


func _process(_delta: float) -> void:
	_animate_flames()


func _player_below() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.health.is_dead:
		return false
	var offset := player.global_position - global_position
	return absf(offset.x) <= TRIGGER_HALF_WIDTH and offset.y > 0.0 and player.global_position.y <= target_y + 60.0


func _start_falling() -> void:
	state = State.FALLING
	monitoring = true
	_marker.modulate.a = 1.0


func _update_marker() -> void:
	# El marcador parpadea despacio mientras espera y muy rápido al activarse.
	var rate := 26.0 if is_triggered() else 7.0
	var blink := 0.5 + 0.5 * sin(_time * rate)
	_marker.modulate.a = 0.4 + 0.6 * blink
	_marker.scale = Vector2.ONE * (1.0 if is_triggered() else 0.85)


func _animate_flames() -> void:
	if _rock == null:
		return
	var t := Time.get_ticks_msec() * 0.001
	var falling := state == State.FALLING
	for index in _flames.size():
		var wobble := 0.75 + 0.35 * sin(t * (11.0 + float(index) * 3.0) * (1.6 if falling else 1.0) + float(index))
		_flames[index].scale = Vector2(0.9 + 0.2 * wobble, wobble * (1.5 if falling else 1.0))
	if _glow != null:
		_glow.modulate.a = 0.55 + 0.25 * sin(t * 9.0)


func _on_body_entered(body: Node2D) -> void:
	if state != State.FALLING:
		return
	if body is Player:
		(body as Player).take_damage(damage, self)
	_impact()


func _impact() -> void:
	if state == State.DONE:
		return
	state = State.DONE
	set_deferred("monitoring", false)
	var parent := get_parent()
	if parent is Node2D:
		Fx.make_burst(parent, Vector2(global_position.x, minf(global_position.y, target_y)), Color(0.75, 0.62, 0.45, 0.9))
	Sfx.play("bomb", -16.0)
	queue_free()


func _build_marker() -> Node2D:
	var marker := Node2D.new()
	marker.name = "RockWarning"
	marker.z_index = 6
	marker.add_to_group("rock_warnings")
	var red := Color(1.0, 0.25, 0.2, 0.9)
	var ground := Polygon2D.new()
	var ring := PackedVector2Array()
	for step in 20:
		var angle := TAU * float(step) / 20.0
		ring.append(Vector2(cos(angle) * 36.0, sin(angle) * 7.0 - 2.0))
	ground.polygon = ring
	ground.color = Color(red.r, red.g, red.b, 0.55)
	marker.add_child(ground)
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(-14, -50), Vector2(14, -50), Vector2(0, -22)])
	arrow.color = red
	marker.add_child(arrow)
	var outline := Line2D.new()
	outline.points = PackedVector2Array([Vector2(-14, -50), Vector2(14, -50), Vector2(0, -22)])
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	marker.add_child(outline)
	return marker


func _build_rock() -> Node2D:
	var rock := Node2D.new()
	rock.name = "Rock"
	rock.z_index = 5
	# Resplandor naranja detrás.
	_glow = Polygon2D.new()
	_glow.name = "FireGlow"
	_glow.color = Color(1.0, 0.45, 0.1, 0.35)
	var glow_points := PackedVector2Array()
	for index in 20:
		glow_points.append(Vector2.from_angle(TAU * float(index) / 20.0) * 40.0)
	_glow.polygon = glow_points
	rock.add_child(_glow)
	# Llamas que salen hacia arriba (la roca cae de cabeza).
	for index in 3:
		var flame := Polygon2D.new()
		flame.name = "Flame%d" % index
		var x := (float(index) - 1.0) * 14.0
		var height := 52.0 if index == 1 else 38.0
		flame.color = Color(1.0, 0.5 + 0.18 * float(index == 1), 0.1, 0.92)
		flame.polygon = PackedVector2Array([Vector2(x - 10.0, -14.0), Vector2(x - 4.0, -height * 0.55), Vector2(x, -height), Vector2(x + 5.0, -height * 0.55), Vector2(x + 10.0, -14.0)])
		rock.add_child(flame)
		_flames.append(flame)
		var core := Polygon2D.new()
		core.color = Color(1.0, 0.9, 0.4, 0.95)
		core.polygon = PackedVector2Array([Vector2(x - 4.0, -14.0), Vector2(x, -height * 0.62), Vector2(x + 4.0, -14.0)])
		flame.add_child(core)
	# Clavos de hierro alrededor.
	for index in SPIKE_COUNT:
		var angle := TAU * float(index) / float(SPIKE_COUNT)
		var spike := Polygon2D.new()
		spike.color = Color("#3d3d4a")
		spike.polygon = PackedVector2Array([Vector2(-5.0, -17.0), Vector2(5.0, -17.0), Vector2(0.0, -34.0)])
		spike.rotation = angle
		rock.add_child(spike)
		var spike_line := Line2D.new()
		spike_line.points = spike.polygon
		spike_line.closed = true
		spike_line.width = 1.8
		spike_line.default_color = Color.BLACK
		spike.add_child(spike_line)
	var points := PackedVector2Array()
	var radii := [22.0, 18.0, 23.0, 19.0, 22.0, 17.0, 23.0, 20.0]
	for index in radii.size():
		var angle := TAU * float(index) / float(radii.size())
		points.append(Vector2(cos(angle), sin(angle)) * float(radii[index]))
	var body := Polygon2D.new()
	body.polygon = points
	body.color = Color("#5a4538")
	rock.add_child(body)
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([Vector2(-6, -4), Vector2(14, -10), Vector2(20, 6), Vector2(2, 18), Vector2(-10, 10)])
	shade.color = Color("#3b2c24")
	rock.add_child(shade)
	var crack := Line2D.new()
	crack.points = PackedVector2Array([Vector2(-12.0, -6.0), Vector2(-2.0, 2.0), Vector2(-8.0, 12.0)])
	crack.width = 2.5
	crack.default_color = Color(1.0, 0.55, 0.15)
	rock.add_child(crack)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	rock.add_child(outline)
	return rock
