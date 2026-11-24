class_name UpdraftZone
extends GimmickZone
## Corriente ascendente (2026-11-23, mundo 5): mientras el jugador está
## dentro, una fuerza lo lleva hacia arriba hasta `lift_speed` (px/s). Con la
## gravedad normal (≈ 1500 px/s²) basta una aceleración de 2600 para flotar y
## subir; salir por arriba conserva el impulso. Se puede bajar manteniendo
## "abajo" (caída rápida). El nodo está en el centro de la zona y se dibuja
## como lluvia invertida con borde blanco (2026-11-24).

@export_range(50.0, 800.0, 10.0) var lift_speed: float = 340.0
@export_range(500.0, 6000.0, 50.0) var lift_acceleration: float = 2600.0
@export var tint: Color = Color(0.7, 0.9, 1.0, 1.0)

## Efecto de lluvia invertida (2026-11-24): muchas líneas finas que suben a
## distinta velocidad y largo dentro de un rectángulo con borde blanco. La altura
## se ajusta con `zone_size.y` (Inspector); el dibujo y la colisión la siguen.
const RAIN_SPACING := 14.0
const RAIN_LENGTH_MIN := 18.0
const RAIN_LENGTH_MAX := 46.0
const RAIN_SPEED_MIN := 260.0
const RAIN_SPEED_MAX := 520.0
const BORDER_WIDTH := 3.0

var _time: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("updrafts")


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
	queue_redraw()


func _draw() -> void:
	var half := zone_size * 0.5
	draw_rect(Rect2(-half, zone_size), Color(tint.r, tint.g, tint.b, 0.10), true)
	var count := maxi(2, int(zone_size.x / RAIN_SPACING))
	for index in count:
		# Valores deterministas por línea (sin aleatoriedad en cada frame).
		var seed_a := fposmod(sin(float(index) * 12.9898) * 43758.5453, 1.0)
		var seed_b := fposmod(sin(float(index) * 78.233) * 12345.6789, 1.0)
		var length := lerpf(RAIN_LENGTH_MIN, RAIN_LENGTH_MAX, seed_a)
		var speed := lerpf(RAIN_SPEED_MIN, RAIN_SPEED_MAX, seed_b)
		var travel := zone_size.y + length
		var offset := fposmod(_time * speed + seed_a * travel, travel)
		var x := -half.x + (float(index) + 0.5) * zone_size.x / float(count)
		var bottom := half.y - offset + length
		var top := bottom - length
		bottom = minf(bottom, half.y)
		top = maxf(top, -half.y)
		if top >= bottom:
			continue
		draw_line(Vector2(x, bottom), Vector2(x, top), Color(1.0, 1.0, 1.0, 0.55), 2.0)
	var corners := PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y)])
	draw_polyline(corners, Color.WHITE, BORDER_WIDTH)
