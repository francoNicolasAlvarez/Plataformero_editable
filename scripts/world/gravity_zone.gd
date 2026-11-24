class_name GravityZone
extends GimmickZone
## Zona de gravedad invertida (2026-11-24): mientras el jugador está dentro
## cae hacia arriba (el techo pasa a ser el suelo); al salir recupera la
## gravedad normal. Flechas violetas que apuntan hacia arriba marcan la zona.
## Hay que cubrirla con un techo donde aterrizar. Reaparecer restaura la normal.

var _original: bool = false
var _time: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("gravity_zones")


func _on_player_entered() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		_original = player.inverted_gravity
		_set_inverted(player, not _original)
		Sfx.play("gravity", -10.0)


func _on_player_exited() -> void:
	_restore()


func _on_reset() -> void:
	_restore()


func _restore() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and player.inverted_gravity != _original:
		_set_inverted(player, _original)


func _set_inverted(player: Player, value: bool) -> void:
	player.inverted_gravity = value
	player.configure_gravity()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var half := zone_size * 0.5
	draw_rect(Rect2(-half, zone_size), Color(0.6, 0.35, 0.95, 0.13), true)
	draw_polyline(PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y)]), Color(0.8, 0.6, 1.0, 0.9), 3.0)
	var rows := maxi(1, int(zone_size.y / 90.0))
	var columns := maxi(1, int(zone_size.x / 90.0))
	for r in rows:
		for c in columns:
			var phase := fposmod(_time * 0.5 + float(r) / float(rows), 1.0)
			var x := -half.x + (float(c) + 0.5) * zone_size.x / float(columns)
			var y := half.y - phase * zone_size.y
			var a := 0.6 * sin(phase * PI)
			draw_polyline(PackedVector2Array([Vector2(x - 12.0, y + 8.0), Vector2(x, y - 8.0), Vector2(x + 12.0, y + 8.0)]), Color(0.85, 0.7, 1.0, a), 3.0)
