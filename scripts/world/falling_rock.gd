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
##
## 2026-11-26: rediseñada como BOLA DE PÚAS de hierro (púas largas con punta roja:
## forma angular = peligro). Hace daño al tocarla también mientras cuelga
## inmóvil (contacto continuo, como los enemigos); al caer sigue rompiéndose
## contra el suelo o el jugador.
##
## 2026-11-26 (2): ya no espera a que el jugador se coloque debajo. CAE
## `TRIGGER_DELAY` (1,5 s) después de aparecer el marcador que indica dónde va a
## caer; el marcador parpadea cada vez más rápido (como mucho ~3 Hz).

const TRIGGER_DELAY := 1.5
const FALL_SPEED := 1500.0
const OVERSHOOT := 260.0
const SPIKE_COUNT := 12
const BALL_RADIUS := 20.0
const SPIKE_LENGTH := 16.0

enum State { WARNING, FALLING, DONE }

@export var damage: int = 15

var target_y: float = 0.0
var start_y: float = 0.0
var state: State = State.WARNING

var _time: float = 0.0
var _trigger_left: float = -1.0
var _blink_phase: float = 0.0
var _marker: Node2D
var _rock: Node2D
var _flames: Array[Polygon2D] = []
var _glow: Polygon2D


func _ready() -> void:
	add_to_group("falling_rocks")
	collision_layer = 0
	collision_mask = 3
	monitoring = true
	body_entered.connect(_on_body_entered)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BALL_RADIUS + SPIKE_LENGTH * 0.5
	shape.shape = circle
	add_child(shape)

	_rock = _build_rock()
	add_child(_rock)

	_marker = _build_marker()
	_marker.top_level = true
	add_child(_marker)
	_marker.global_position = Vector2(global_position.x, target_y)
	global_position.y = start_y
	# La cuenta empieza en cuanto se indica el punto de impacto.
	_trigger_left = TRIGGER_DELAY


static func clear_rocks(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("falling_rocks"):
		node.queue_free()


## Cierto mientras corre la cuenta hasta la caída (desde que aparece).
func is_triggered() -> bool:
	return _trigger_left >= 0.0


func _physics_process(delta: float) -> void:
	match state:
		State.WARNING:
			_time += delta
			_hurt_touching_player()
			_trigger_left -= delta
			if _trigger_left <= 0.0:
				_start_falling()
			_update_marker()
		State.FALLING:
			global_position.y += FALL_SPEED * delta
			if global_position.y >= target_y + OVERSHOOT:
				_impact()


func _process(_delta: float) -> void:
	_animate_flames()


## Daño por contacto mientras cuelga (la invulnerabilidad del jugador evita
## golpes repetidos en cada frame).
func _hurt_touching_player() -> void:
	for body in get_overlapping_bodies():
		if body is Player and not (body as Player).health.is_dead:
			(body as Player).take_damage(damage, self)


func _start_falling() -> void:
	state = State.FALLING
	_marker.modulate.a = 1.0


func _update_marker() -> void:
	# El marcador parpadea cada vez más rápido (de ~1 a ~3 Hz) y crece hasta la caída.
	var progress := 1.0 - clampf(_trigger_left / TRIGGER_DELAY, 0.0, 1.0)
	_blink_phase += get_physics_process_delta_time() * (6.0 + 12.0 * progress)
	var blink := 0.5 + 0.5 * sin(_blink_phase)
	_marker.modulate.a = 0.4 + 0.6 * blink
	_marker.scale = Vector2.ONE * (0.85 + 0.15 * progress)


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
	if state == State.WARNING:
		if body is Player:
			(body as Player).take_damage(damage, self)
		return
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
	# Púas de hierro con punta roja alrededor de la bola (forma angular = peligro).
	for index in SPIKE_COUNT:
		var angle := TAU * float(index) / float(SPIKE_COUNT)
		var spike := Polygon2D.new()
		spike.name = "Spike%d" % index
		spike.color = Color("#4a4d5c")
		var base := BALL_RADIUS - 3.0
		var tip := BALL_RADIUS + SPIKE_LENGTH
		spike.polygon = PackedVector2Array([Vector2(-6.0, -base), Vector2(6.0, -base), Vector2(0.0, -tip)])
		spike.rotation = angle
		rock.add_child(spike)
		var point := Polygon2D.new()
		point.color = Color("#e0392b")
		point.polygon = PackedVector2Array([Vector2(-2.6, -tip + 7.0), Vector2(2.6, -tip + 7.0), Vector2(0.0, -tip)])
		spike.add_child(point)
		var spike_line := Line2D.new()
		spike_line.points = spike.polygon
		spike_line.closed = true
		spike_line.width = 1.8
		spike_line.default_color = Color.BLACK
		spike.add_child(spike_line)
	# Bola de hierro con brillo y remaches.
	var points := PackedVector2Array()
	for index in 24:
		points.append(Vector2.from_angle(TAU * float(index) / 24.0) * BALL_RADIUS)
	var body := Polygon2D.new()
	body.name = "Ball"
	body.polygon = points
	body.color = Color("#5b5f70")
	rock.add_child(body)
	var shade := Polygon2D.new()
	var shade_points := PackedVector2Array()
	for index in 13:
		shade_points.append(Vector2.from_angle(PI * 0.1 + PI * float(index) / 12.0) * (BALL_RADIUS - 1.0))
	shade.polygon = shade_points
	shade.color = Color("#3c3f4c")
	rock.add_child(shade)
	var shine := Polygon2D.new()
	var shine_points := PackedVector2Array()
	for index in 10:
		shine_points.append(Vector2(-7.0, -7.0) + Vector2.from_angle(TAU * float(index) / 10.0) * Vector2(6.0, 4.0))
	shine.polygon = shine_points
	shine.color = Color(1.0, 1.0, 1.0, 0.45)
	rock.add_child(shine)
	for index in 4:
		var rivet := Polygon2D.new()
		var rivet_points := PackedVector2Array()
		for step in 8:
			rivet_points.append(Vector2.from_angle(TAU * float(step) / 8.0) * 2.2)
		rivet.polygon = rivet_points
		rivet.color = Color("#2a2c36")
		rivet.position = Vector2.from_angle(PI * 0.25 + PI * 0.5 * float(index)) * 11.0
		rock.add_child(rivet)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	rock.add_child(outline)
	return rock
