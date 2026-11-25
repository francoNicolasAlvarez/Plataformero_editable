class_name KeyPickup
extends Area2D
## Llave (2026-11-24, mundo 6): se recoge al tocarla y se conserva aunque el
## jugador muera. `VictoryCondition` en modo KEYS exige recoger todas las del
## grupo `keys` para abrir la salida. El nodo está en el centro de la llave.

signal collected(key: KeyPickup)

var is_collected: bool = false

var _time: float = 0.0


func _ready() -> void:
	add_to_group("keys")
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40.0, 40.0)
	shape.shape = rectangle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_collected:
		is_collected = true
		Fx.make_burst(get_parent(), global_position, Color(1.0, 0.85, 0.3, 0.95))
		Sfx.play("unlock", -4.0)
		visible = false
		set_deferred("monitoring", false)
		collected.emit(self)


func _draw() -> void:
	var bob := sin(_time * 3.0) * 3.0
	# Halo dorado suave (2026-11-25, guía de diseño visual): el objeto de misión se ve de lejos.
	draw_circle(Vector2(0.0, bob), 26.0 + 2.0 * sin(_time * 3.0), Color(1.0, 0.85, 0.3, 0.16))
	var gold := Color("#f2c744")
	draw_circle(Vector2(-8.0, bob), 9.0, gold)
	draw_circle(Vector2(-8.0, bob), 4.0, Color(0.15, 0.1, 0.0))
	draw_rect(Rect2(0.0, bob - 3.0, 22.0, 6.0), gold, true)
	draw_rect(Rect2(14.0, bob + 3.0, 4.0, 8.0), gold, true)
	draw_rect(Rect2(20.0, bob + 3.0, 4.0, 6.0), gold, true)
	draw_arc(Vector2(-8.0, bob), 9.0, 0.0, TAU, 20, Color.BLACK, 2.0)
