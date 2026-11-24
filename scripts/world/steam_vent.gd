class_name SteamVent
extends Hazard
## Respiradero de vapor (Fase 4, 2026-11-18): chorro vertical cíclico. Aviso:
## la boca se ilumina, tiembla y sale un hilo de vapor tenue (`warning_time`);
## activo: columna densa de `column_height` px que quita un golpe si el
## jugador está dentro; después se enfría. El nodo está a ras de suelo, en
## el centro de la boca. Se construye por código.

@export var column_height: float = 170.0
@export var column_width: float = 46.0

var zone: Area2D
var _column: Polygon2D
var _mouth: Polygon2D
var _shape: CollisionShape2D
var _time: float = 0.0


func _ready() -> void:
	super._ready()
	_build()
	_apply_visual(State.IDLE)
	set_process(false)  # la animación solo hace falta durante el aviso y el chorro


func _build() -> void:
	zone = Area2D.new()
	zone.name = "Zone"
	zone.collision_layer = 0
	zone.collision_mask = 2
	add_child(zone)
	_shape = CollisionShape2D.new()
	_shape.name = "ZoneShape"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(column_width, column_height)
	_shape.shape = rectangle
	_shape.position = Vector2(0.0, -column_height * 0.5)
	_shape.disabled = true
	zone.add_child(_shape)

	_column = Polygon2D.new()
	_column.name = "Column"
	_column.color = Color(0.92, 0.95, 1.0, 0.0)
	_column.polygon = PackedVector2Array([
		Vector2(-column_width * 0.5, 0.0), Vector2(-column_width * 0.62, -column_height * 0.55),
		Vector2(-column_width * 0.45, -column_height), Vector2(column_width * 0.45, -column_height),
		Vector2(column_width * 0.62, -column_height * 0.55), Vector2(column_width * 0.5, 0.0),
	])
	_column.z_index = 2
	add_child(_column)

	_mouth = Polygon2D.new()
	_mouth.name = "Mouth"
	_mouth.color = Color("#3b3a46")
	_mouth.polygon = PackedVector2Array([
		Vector2(-column_width * 0.6, 0.0), Vector2(-column_width * 0.45, -10.0),
		Vector2(column_width * 0.45, -10.0), Vector2(column_width * 0.6, 0.0),
	])
	add_child(_mouth)
	var outline := Line2D.new()
	outline.name = "MouthOutline"
	outline.points = _mouth.polygon
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	add_child(outline)


func _process(delta: float) -> void:
	_time += delta
	if state == State.WARNING:
		_mouth.position.x = sin(_time * 70.0) * 1.6 * warning_progress()
		_column.color.a = 0.10 + 0.12 * warning_progress()
		_mouth.color = Color("#3b3a46").lerp(Color("#ff8a4a"), warning_progress())
	elif state == State.ACTIVE:
		_column.color.a = 0.68 + 0.08 * sin(_time * 24.0)


func _on_active_tick(_delta: float) -> void:
	for body in zone.get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(15, self)


func _on_state_entered(new_state: int) -> void:
	_apply_visual(new_state)


func _on_reset() -> void:
	_apply_visual(State.IDLE)


func _apply_visual(for_state: int) -> void:
	if _shape == null:
		return
	set_process(for_state == State.WARNING or for_state == State.ACTIVE)
	_shape.set_deferred("disabled", for_state != State.ACTIVE)
	_mouth.position.x = 0.0
	match for_state:
		State.IDLE, State.COOLDOWN:
			_column.color.a = 0.0
			_mouth.color = Color("#3b3a46")
		State.WARNING:
			_column.color.a = 0.10
		State.ACTIVE:
			_column.color.a = 0.7
			_mouth.color = Color("#ff8a4a")
