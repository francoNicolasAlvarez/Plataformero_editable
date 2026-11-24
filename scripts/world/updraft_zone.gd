class_name UpdraftZone
extends GimmickZone
## Corriente ascendente (2026-11-23, mundo 5): mientras el jugador está
## dentro, una fuerza lo lleva hacia arriba hasta `lift_speed` (px/s). Con la
## gravedad normal (≈ 1500 px/s²) basta una aceleración de 2600 para flotar y
## subir; salir por arriba conserva el impulso. Se puede bajar manteniendo
## "abajo" (caída rápida). El nodo está en el centro de la zona y se dibuja
## con aspas negras cuadradas que suben y un contorno negro (2026-11-24).

@export_range(50.0, 800.0, 10.0) var lift_speed: float = 340.0
@export_range(500.0, 6000.0, 50.0) var lift_acceleration: float = 2600.0
@export var tint: Color = Color(0.7, 0.9, 1.0, 1.0)

const STREAK_LENGTH := 22.0
const STREAK_WIDTH := 16.0
const STREAK_SPACING := 90.0

var _time: float = 0.0
var _streaks: Array[Line2D] = []


func _ready() -> void:
	super._ready()
	add_to_group("updrafts")
	_build_visual()


func _physics_process(_delta: float) -> void:
	if not player_inside:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if player.health.is_dead or Input.is_action_pressed("move_down"):
		_release(player)
		return
	player.updraft_speed = lift_speed
	player.updraft_accel = lift_acceleration


func _on_player_exited() -> void:
	_release(get_tree().get_first_node_in_group("player") as Player)


func _on_reset() -> void:
	_release(get_tree().get_first_node_in_group("player") as Player)


func _release(player: Player) -> void:
	if player != null:
		player.updraft_speed = 0.0
		player.updraft_accel = 0.0


func _process(delta: float) -> void:
	_time += delta
	var half := zone_size * 0.5
	for index in _streaks.size():
		var phase := fposmod(_time * 0.55 + float(index) / float(_streaks.size()), 1.0)
		var x := -half.x + (float(index) + 0.5) * zone_size.x / float(_streaks.size())
		var y := half.y - phase * zone_size.y
		_streaks[index].points = PackedVector2Array([Vector2(x, y), Vector2(x, y - STREAK_LENGTH)])
		_streaks[index].default_color = Color(0.0, 0.0, 0.0, 0.9 * sin(phase * PI))


func _build_visual() -> void:
	var half := zone_size * 0.5
	var body := Polygon2D.new()
	body.name = "Haze"
	body.color = Color(tint.r, tint.g, tint.b, 0.14)
	body.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	body.z_index = -3
	add_child(body)
	# Contorno negro cerrado de la zona.
	var outline := Line2D.new()
	outline.name = "Outline"
	outline.points = body.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.z_index = -2
	add_child(outline)
	# Aspas negras cuadradas (anchas y cortas) con mucho espacio entre ellas.
	var count := maxi(2, int(zone_size.x / STREAK_SPACING))
	for index in count:
		var streak := Line2D.new()
		streak.width = STREAK_WIDTH
		streak.begin_cap_mode = Line2D.LINE_CAP_NONE
		streak.end_cap_mode = Line2D.LINE_CAP_NONE
		streak.z_index = -2
		add_child(streak)
		_streaks.append(streak)
