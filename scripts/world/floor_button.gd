class_name FloorButton
extends LeverSwitch
## Botón de suelo (2026-11-24, mundo 6): se activa al CAER sobre él (hay que
## saltar encima; con `require_jump` falso basta con pisarlo). Funciona como una
## palanca: abre las compuertas, puentes y candados (`ChannelLock`) de su canal.
## Con `reset_after` > 0 se vuelve a levantar tras esos segundos.

@export var require_jump: bool = true
@export_range(0.0, 60.0, 0.5) var reset_after: float = 0.0

var _cap: Polygon2D
var _timer: float = 0.0


func _physics_process(delta: float) -> void:
	if is_on and reset_after > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			reset()


func activate() -> void:
	if is_on:
		return
	_timer = reset_after
	super.activate()


func _accepts(player: Player) -> bool:
	if not require_jump:
		return true
	var fall_speed := player.velocity.y * (-1.0 if player.inverted_gravity else 1.0)
	return fall_speed > 120.0


func _build_visual() -> void:
	var plate := Polygon2D.new()
	plate.color = Color("#3d4152")
	plate.polygon = PackedVector2Array([Vector2(-28.0, 0.0), Vector2(-24.0, -6.0), Vector2(24.0, -6.0), Vector2(28.0, 0.0)])
	add_child(plate)
	_cap = Polygon2D.new()
	_cap.polygon = PackedVector2Array([Vector2(-18.0, -6.0), Vector2(-15.0, -16.0), Vector2(15.0, -16.0), Vector2(18.0, -6.0)])
	add_child(_cap)
	for poly in [plate, _cap]:
		var outline := Line2D.new()
		outline.points = (poly as Polygon2D).polygon
		outline.closed = true
		outline.width = 2.5
		outline.default_color = Color.BLACK
		poly.add_child(outline)
	_apply_visual(false)


func _apply_visual(on: bool) -> void:
	if _cap == null:
		return
	_cap.color = Color("#57e389") if on else Color("#d94b4b")
	_cap.position.y = 6.0 if on else 0.0
