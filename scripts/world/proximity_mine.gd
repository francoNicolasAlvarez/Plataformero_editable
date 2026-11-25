class_name ProximityMine
extends Hazard
## Mina de proximidad (2026-11-21): al acercarse el jugador (`detect_radius`)
## empieza a parpadear en rojo y explota `warning_time` (1 s) después. La
## explosión quita un golpe a quien esté dentro de `blast_radius` en ese
## instante, así que se puede huir a tiempo. Tras explotar desaparece hasta
## que el jugador muere (`reset()`), o vuelve sola tras `rearm_time` segundos
## si es mayor que 0. Se construye por código (se ve al ejecutar el nivel).

@export_range(20.0, 600.0, 5.0) var detect_radius: float = 120.0
@export_range(20.0, 400.0, 5.0) var blast_radius: float = 95.0
@export_range(1, 99, 1) var damage: int = 15
## 0 = una sola vez (hasta morir); >0 = se vuelve a armar tras ese tiempo.
@export_range(0.0, 30.0, 0.5) var rearm_time: float = 0.0

var _trigger_area: Area2D
var _body: Node2D
var _light: Polygon2D
var _blast: Polygon2D
var _ring: Line2D
var _time: float = 0.0
var _blast_tween: Tween


func _init() -> void:
	warning_time = 1.0
	active_time = 0.4
	cooldown_time = 1.0e9
	auto_cycle = false


func _ready() -> void:
	super._ready()
	add_to_group("mines")
	if rearm_time > 0.0:
		cooldown_time = rearm_time
	_build()
	_apply_visual(State.IDLE)


func _build() -> void:
	_trigger_area = Area2D.new()
	_trigger_area.name = "Trigger"
	_trigger_area.collision_layer = 0
	_trigger_area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = detect_radius
	shape.shape = circle
	_trigger_area.add_child(shape)
	add_child(_trigger_area)

	_ring = Line2D.new()
	_ring.name = "BlastRing"
	_ring.width = 2.0
	_ring.default_color = Color(1.0, 0.35, 0.25, 0.0)
	_ring.closed = true
	_ring.z_index = -1
	_ring.points = _circle_points(blast_radius, 40)
	add_child(_ring)

	_body = Node2D.new()
	_body.name = "Body"
	add_child(_body)
	var shell := Polygon2D.new()
	shell.color = Color("#4a4d5a")
	shell.polygon = _circle_points(14.0, 16)
	_body.add_child(shell)
	var outline := Line2D.new()
	outline.points = _circle_points(14.0, 16)
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	_body.add_child(outline)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var spike := Polygon2D.new()
		spike.color = Color("#2d2f38")
		spike.polygon = PackedVector2Array([Vector2(-3, -13), Vector2(3, -13), Vector2(0, -21)])
		spike.rotation = angle
		_body.add_child(spike)
	_light = Polygon2D.new()
	_light.color = Color("#7a2d2d")
	_light.polygon = _circle_points(5.0, 10)
	_body.add_child(_light)
	_body.position.y = -14.0

	_blast = Polygon2D.new()
	_blast.name = "Blast"
	_blast.color = Color(1.0, 0.62, 0.2, 0.0)
	_blast.polygon = _circle_points(blast_radius, 32)
	_blast.z_index = 3
	add_child(_blast)


func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		var angle := TAU * float(i) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if state == State.IDLE and _trigger_area != null:
		for body in _trigger_area.get_overlapping_bodies():
			if body is Player and not (body as Player).health.is_dead:
				trigger()
				break


func _process(delta: float) -> void:
	_time += delta
	if state == State.WARNING and _light != null:
		# Parpadeo cada vez más rápido hasta la explosión.
		var rate := 8.0 + 10.0 * warning_progress()  # <= 18 rad/s (~2,9 Hz): sin parpadeo rápido
		var on := sin(_time * rate) > 0.0
		_light.color = Color("#ff3b30") if on else Color("#7a2d2d")
		_body.scale = Vector2.ONE * (1.0 + 0.12 * warning_progress())
		_ring.default_color.a = 0.25 + 0.35 * warning_progress()


func _on_state_entered(new_state: int) -> void:
	_apply_visual(new_state)
	if new_state == State.ACTIVE:
		_explode()


func _on_reset() -> void:
	_apply_visual(State.IDLE)


func _explode() -> void:
	Sfx.play("bomb", -4.0)
	for body in _trigger_area.get_overlapping_bodies():
		if body is Player and global_position.distance_to((body as Player).global_position) <= blast_radius:
			(body as Player).take_damage(damage, self)
	if _blast_tween != null and _blast_tween.is_valid():
		_blast_tween.kill()
	_blast.scale = Vector2(0.2, 0.2)
	_blast.color.a = 0.85
	_blast_tween = create_tween().set_parallel(true)
	_blast_tween.tween_property(_blast, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_blast_tween.tween_property(_blast, "color:a", 0.0, active_time)
	Fx.make_burst(self, Vector2(0.0, -14.0), Color(1.0, 0.6, 0.2))


func _apply_visual(for_state: int) -> void:
	if _body == null:
		return
	set_process(for_state == State.WARNING)
	_body.scale = Vector2.ONE
	_light.color = Color("#7a2d2d")
	_ring.default_color.a = 0.0
	# Con la mina consumida el cuerpo desaparece y la detección se apaga.
	var armed := for_state == State.IDLE or for_state == State.WARNING
	_body.visible = armed
	_trigger_area.set_deferred("monitoring", for_state == State.IDLE or for_state == State.WARNING or for_state == State.ACTIVE)
	if for_state == State.IDLE:
		_blast.color.a = 0.0
