class_name VacuumSentry
extends Node2D
## Centinela aspirador (2026-11-23): versión azul del centinela del cielo que
## vive en la esquina INFERIOR IZQUIERDA de la pantalla (sigue a la cámara).
## Alterna dos fases:
##  - Disparo: cada `shoot_interval` s lanza un cono de 5 proyectiles azules
##    apuntado al jugador (con tres círculos de carga, como el rojo).
##  - Succión: cada `suction_interval` s abre la boca durante `suction_duration`
##    s y absorbe objetos que vuelan hacia él (sillas, mesas, vacas, coches,
##    espadas y hasta gente). Los objetos aparecen por el EXTREMO DERECHO de la
##    pantalla y cruzan volando hacia su boca: si tocan al jugador le hacen
##    daño (una vez por objeto). Mientras aspira no dispara.
## No tiene vida ni colisión. Se construye por código. `reset()` lo llama
## `TestLevel` al morir el jugador.

const PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")
const PROJECTILE_LIFETIME := 30.0
const OBJECT_KINDS := ["chair", "table", "cow", "car", "sword", "person"]
const BLUE := Color("#2f6fd0")
const BLUE_DARK := Color("#1b3f86")
const BLUE_DEEPER := Color("#122a5c")
const RING_COLORS := [Color(0.55, 0.9, 1.0), Color(0.3, 0.7, 1.0), Color(0.15, 0.4, 1.0)]

enum Phase { SHOOT, SUCK }

@export_range(0.5, 12.0, 0.01) var shoot_interval: float = 5.0
@export_range(2.0, 40.0, 0.5) var suction_interval: float = 4.0
@export_range(1.0, 10.0, 0.1) var suction_duration: float = 7.0
## Objetos aspirados (2026-11-24): uno cada `object_interval` s y como mucho
## `max_objects` a la vez.
@export_range(0.1, 5.0, 0.05) var object_interval: float = 0.5
@export_range(1, 12, 1) var max_objects: int = 2
@export_range(80.0, 600.0, 10.0) var projectile_speed: float = 250.0
@export_range(0.0, 300.0, 1.0) var left_margin: float = 120.0
@export_range(0.0, 300.0, 1.0) var bottom_margin: float = 110.0
@export_range(0.0, 20.0, 0.5) var bob_amplitude: float = 4.0
@export_range(0, 60, 1) var object_damage: int = 12

var phase: Phase = Phase.SHOOT

var _visual: Node2D
var _eye: Polygon2D
var _mouth: Polygon2D
var _suction_layer: Node2D
var _rings: SentryRings
var _objects: Array[Dictionary] = []
var _cooldown: float = 0.0
var _suction_timer: float = 0.0
var _suction_left: float = 0.0
var _spawn_timer: float = 0.0
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("vacuum_sentries")
	z_index = 6
	_rng.randomize()
	_build_visual()
	_rings = SentryRings.new()
	_rings.name = "ChargeRings"
	_rings.palette = RING_COLORS
	add_child(_rings)
	reset()
	_follow_screen()


## Cancela la carga y la succión en curso y reinicia los ciclos.
func reset() -> void:
	phase = Phase.SHOOT
	_cooldown = shoot_interval
	_suction_timer = suction_interval
	_suction_left = 0.0
	if _rings != null:
		_rings.stop()
	_clear_objects()
	if _mouth != null:
		_mouth.scale = Vector2(0.3, 0.3)


func is_sucking() -> bool:
	return phase == Phase.SUCK


func object_count() -> int:
	return _objects.size()


func _process(delta: float) -> void:
	_time += delta
	_follow_screen()
	match phase:
		Phase.SHOOT:
			_process_shoot(delta)
		Phase.SUCK:
			_process_suck(delta)
	_update_objects(delta)
	var pulse := 1.0 + 0.08 * sin(_time * 4.0)
	_eye.scale = Vector2(pulse, pulse)


func _process_shoot(delta: float) -> void:
	_cooldown -= delta
	_suction_timer -= delta
	var charge_time := SentryRings.total_time()
	if _cooldown > 0.0 and _cooldown <= charge_time:
		_rings.position = to_local(_eye.global_position)
		_rings.set_elapsed(charge_time - _cooldown)
	if _cooldown <= 0.0:
		_rings.stop()
		_shoot_at_player()
		_cooldown = shoot_interval
	# La succión tiene prioridad: cancela una carga a medias.
	if _suction_timer <= 0.0:
		_start_suction()


func _start_suction() -> void:
	phase = Phase.SUCK
	_suction_left = suction_duration
	_spawn_timer = 0.0
	_rings.stop()


func _process_suck(delta: float) -> void:
	_suction_left -= delta
	# La boca se abre y los ojos se afilan mientras aspira.
	_mouth.scale = _mouth.scale.lerp(Vector2(1.0, 1.0), minf(1.0, delta * 6.0))
	_eye.modulate = Color(0.6, 1.0, 1.0)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _suction_left > 0.4 and _objects.size() < max_objects:
		_spawn_timer = object_interval
		_spawn_object()
	elif _spawn_timer <= 0.0:
		_spawn_timer = 0.05
	if _suction_left <= 0.0:
		phase = Phase.SHOOT
		_suction_timer = suction_interval
		_cooldown = shoot_interval * 0.6
		_eye.modulate = Color.WHITE
		_mouth.scale = Vector2(0.3, 0.3)


func _follow_screen() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var viewport_size := get_viewport_rect().size
	var visible_width := viewport_size.x / maxf(camera.zoom.x, 0.01)
	var visible_height := viewport_size.y / maxf(camera.zoom.y, 0.01)
	var bob := sin(_time * 2.0) * bob_amplitude
	global_position = Vector2(
		center.x - visible_width * 0.5 + left_margin,
		center.y + visible_height * 0.5 - bottom_margin + bob
	)


func _shoot_at_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var origin := global_position + Vector2(40.0, -20.0)
	var aim := (player.global_position - origin).normalized()
	if aim.is_zero_approx():
		return
	var parent := get_parent()
	if parent == null:
		return
	var count := 5
	var cone_angle := deg_to_rad(70.0)
	var step := cone_angle / float(count - 1)
	var start_angle := aim.angle() - cone_angle * 0.5
	for index in count:
		var angle := start_angle + step * float(index)
		var direction := Vector2(cos(angle), sin(angle))
		var projectile := PROJECTILE_SCENE.instantiate() as EnemyProjectile
		projectile.lifetime = PROJECTILE_LIFETIME
		parent.add_child(projectile)
		projectile.global_position = origin
		projectile.direction = 1.0 if direction.x >= 0.0 else -1.0
		projectile.speed = projectile_speed
		projectile.velocity = direction * projectile_speed
		projectile.rotation = angle
	Sfx.play("sentry", -15.0)


# --- Objetos absorbidos -----------------------------------------------------

func _spawn_object() -> void:
	var kind: String = OBJECT_KINDS[_rng.randi() % OBJECT_KINDS.size()]
	var node := _build_object(kind)
	var view := _view_size()
	# Por el borde derecho de la pantalla, siempre más arriba que el jugador
	# (2026-11-24) y dentro de la zona visible, así cruzan la pantalla a la vista.
	var right_edge := view.x - left_margin + 80.0
	var top_edge := -(view.y - bottom_margin) + 40.0
	var bottom_edge := bottom_margin - 40.0
	var highest_allowed := bottom_edge
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		highest_allowed = clampf(_suction_layer.to_local(player.global_position).y - 70.0, top_edge + 30.0, bottom_edge)
	node.position = Vector2(right_edge, _rng.randf_range(top_edge, highest_allowed))
	node.scale = Vector2.ONE * _rng.randf_range(1.1, 1.6)
	_suction_layer.add_child(node)
	_objects.append({
		"node": node, "speed": _rng.randf_range(230.0, 300.0),
		"spin": _rng.randf_range(-4.0, 4.0), "base_scale": node.scale.x, "kind": kind,
		"hit": false,
	})


func _view_size() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	var zoom := camera.zoom if camera != null else Vector2.ONE
	var size := get_viewport_rect().size
	return Vector2(size.x / maxf(zoom.x, 0.01), size.y / maxf(zoom.y, 0.01))


func _update_objects(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for index in range(_objects.size() - 1, -1, -1):
		var entry := _objects[index]
		var node := entry["node"] as Node2D
		if not is_instance_valid(node):
			_objects.remove_at(index)
			continue
		entry["speed"] = float(entry["speed"]) + 260.0 * delta
		var to_mouth := Vector2(46.0, 0.0) - node.position
		var distance := to_mouth.length()
		node.position += to_mouth.normalized() * minf(float(entry["speed"]) * delta, distance)
		node.rotation += float(entry["spin"]) * delta
		node.scale = Vector2.ONE * float(entry["base_scale"]) * clampf(distance / 220.0, 0.12, 1.0)
		if player != null and not bool(entry["hit"]) and distance > 90.0:
			var reach := 26.0 * node.scale.x + 16.0
			if node.global_position.distance_to(player.global_position) <= reach and player.has_method("take_damage"):
				if not (player is Player and (player as Player).is_intangible()):
					entry["hit"] = true
					player.take_damage(object_damage, self)
		if distance < 28.0:
			node.queue_free()
			_objects.remove_at(index)


func _clear_objects() -> void:
	for entry in _objects:
		var node := entry["node"] as Node
		if is_instance_valid(node):
			node.queue_free()
	_objects.clear()


static func _poly(parent: Node, points: PackedVector2Array, color: Color, outline: bool = true) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	if outline:
		var line := Line2D.new()
		line.points = points
		line.closed = true
		line.width = 2.0
		line.default_color = Color.BLACK
		polygon.add_child(line)
	return polygon


static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])


static func _disc(radius: float, count: int = 12) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		points.append(Vector2.from_angle(TAU * float(i) / float(count)) * radius)
	return points


## Silueta sencilla de cada objeto absorbible (centrada en el origen).
static func _build_object(kind: String) -> Node2D:
	var root := Node2D.new()
	root.name = "Sucked_" + kind
	root.z_index = 7
	match kind:
		"chair":
			_poly(root, _rect(-12.0, -2.0, 26.0, 8.0), Color("#9a6b3d"))
			_poly(root, _rect(-12.0, -28.0, 7.0, 28.0), Color("#8a5c32"))
			_poly(root, _rect(-12.0, 6.0, 5.0, 20.0), Color("#7a5029"))
			_poly(root, _rect(9.0, 6.0, 5.0, 20.0), Color("#7a5029"))
		"table":
			_poly(root, _rect(-30.0, -6.0, 60.0, 8.0), Color("#b07a45"))
			_poly(root, _rect(-26.0, 2.0, 6.0, 24.0), Color("#8a5c32"))
			_poly(root, _rect(20.0, 2.0, 6.0, 24.0), Color("#8a5c32"))
		"cow":
			_poly(root, _rect(-26.0, -14.0, 52.0, 26.0), Color("#f4f4f4"))
			_poly(root, _rect(-8.0, -12.0, 14.0, 12.0), Color("#222222"), false)
			_poly(root, _rect(10.0, 0.0, 10.0, 9.0), Color("#222222"), false)
			_poly(root, _rect(24.0, -22.0, 18.0, 16.0), Color("#f4f4f4"))
			_poly(root, _rect(36.0, -16.0, 8.0, 8.0), Color("#e9a0a0"))
			_poly(root, PackedVector2Array([Vector2(27, -22), Vector2(30, -30), Vector2(33, -22)]), Color("#d8c9a0"))
			for leg_x in [-22.0, -10.0, 8.0, 18.0]:
				_poly(root, _rect(leg_x, 12.0, 6.0, 14.0), Color("#dddddd"))
		"car":
			_poly(root, _rect(-38.0, -4.0, 76.0, 18.0), Color("#c0392b"))
			_poly(root, PackedVector2Array([Vector2(-22, -4), Vector2(-14, -20), Vector2(14, -20), Vector2(24, -4)]), Color("#d65a4a"))
			_poly(root, PackedVector2Array([Vector2(-16, -6), Vector2(-11, -17), Vector2(-1, -17), Vector2(-1, -6)]), Color("#bfe6f5"), false)
			_poly(root, PackedVector2Array([Vector2(3, -6), Vector2(3, -17), Vector2(12, -17), Vector2(19, -6)]), Color("#bfe6f5"), false)
			for wheel_x in [-24.0, 24.0]:
				var wheel := _poly(root, _disc(9.0), Color("#262626"))
				wheel.position = Vector2(wheel_x, 14.0)
		"sword":
			_poly(root, PackedVector2Array([Vector2(-34, -3), Vector2(24, -3), Vector2(36, 0), Vector2(24, 3), Vector2(-34, 3)]), Color("#d9dde6"))
			_poly(root, _rect(-40.0, -9.0, 6.0, 18.0), Color("#c9a227"))
			_poly(root, _rect(-52.0, -3.0, 12.0, 6.0), Color("#6b3b1f"))
		"person":
			var head := _poly(root, _disc(8.0), Color("#f1c9a5"))
			head.position = Vector2(0.0, -26.0)
			_poly(root, _rect(-8.0, -18.0, 16.0, 24.0), Color("#3b82c4"))
			_poly(root, _rect(-14.0, -17.0, 6.0, 18.0), Color("#f1c9a5"))
			_poly(root, _rect(8.0, -17.0, 6.0, 18.0), Color("#f1c9a5"))
			_poly(root, _rect(-7.0, 6.0, 6.0, 20.0), Color("#2c3e50"))
			_poly(root, _rect(1.0, 6.0, 6.0, 20.0), Color("#2c3e50"))
	return root


# --- Dibujo del centinela -----------------------------------------------------

func _build_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	_visual.scale = Vector2(1.75, 1.75)
	add_child(_visual)
	for side in [-1.0, 1.0]:
		var wing := _poly(_visual, PackedVector2Array([Vector2(0, -6), Vector2(28 * side, -26), Vector2(54 * side, -18), Vector2(42 * side, -2), Vector2(14 * side, 8)]), BLUE_DARK, false)
		wing.position = Vector2(16.0 * side, -2.0)
		var shade := _poly(_visual, PackedVector2Array([Vector2(0, -6), Vector2(28 * side, -26), Vector2(38 * side, -20), Vector2(20 * side, -5)]), BLUE_DEEPER, false)
		shade.position = Vector2(16.0 * side, -2.0)
		_poly(_visual, PackedVector2Array([Vector2(18 * side, -14), Vector2(28 * side, -38), Vector2(7 * side, -22)]), BLUE_DEEPER, false)
	var body_points := PackedVector2Array([Vector2(-22, -18), Vector2(22, -18), Vector2(29, 0), Vector2(18, 20), Vector2(-18, 20), Vector2(-29, 0)])
	_poly(_visual, body_points, BLUE)
	_poly(_visual, PackedVector2Array([Vector2(5, -18), Vector2(22, -18), Vector2(29, 0), Vector2(18, 20), Vector2(5, 20)]), BLUE_DARK, false)
	var glow := _poly(_visual, _disc(17.0, 8), Color(0.3, 0.9, 1.0, 0.3), false)
	glow.position = Vector2.ZERO
	_eye = _poly(_visual, _disc(10.0, 8), Color(0.55, 0.95, 1.0), false)
	var pupil := _poly(_visual, PackedVector2Array([Vector2(0, -7), Vector2(2.4, -2.4), Vector2(2.4, 2.4), Vector2(0, 7), Vector2(-2.4, 2.4), Vector2(-2.4, -2.4)]), Color(0.04, 0.08, 0.2), false)
	pupil.position = Vector2.ZERO
	# Boca de succión: embudo a la derecha que se abre al aspirar.
	_mouth = _poly(_visual, PackedVector2Array([Vector2(0, -12), Vector2(18, -22), Vector2(18, 22), Vector2(0, 12)]), Color(0.05, 0.1, 0.3, 0.95))
	_mouth.position = Vector2(26.0, 0.0)
	_mouth.scale = Vector2(0.3, 0.3)
	_suction_layer = Node2D.new()
	_suction_layer.name = "Sucked"
	add_child(_suction_layer)
