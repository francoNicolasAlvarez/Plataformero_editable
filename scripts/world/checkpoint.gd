class_name Checkpoint
extends Area2D
## Bandera de control (2026-11-12): al tocarla se convierte en el punto de
## reaparición del nivel y recupera toda la vida del jugador. Sirve también
## como zona de descanso entre retos.

signal activated(checkpoint: Checkpoint)

@onready var pole: Polygon2D = $Visual/Pole
@onready var flag: Polygon2D = $Visual/Flag
@onready var base: Polygon2D = $Visual/Base

var is_active: bool = false


func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	Fx.make_sparkle(self, Vector2(0.0, -52.0), Color(0.62, 0.9, 1.0, 0.5))


func _on_body_entered(body: Node2D) -> void:
	if is_active or not body is Player:
		return
	activate(body as Player)


func activate(player: Player) -> void:
	if is_active:
		return
	is_active = true
	pole.color = Color("#7ef0b2")
	base.color = Color("#7ef0b2")
	flag.color = Color("#57e389")
	flag.scale = Vector2(1.6, 1.6)
	var tween := create_tween()
	tween.tween_property(flag, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if not player.health.is_dead:
		player.health.heal(player.health.max_health)
	Sfx.play("heal", -8.0)
	var burst_parent := get_parent() as Node2D
	if burst_parent != null:
		Fx.make_burst(
			burst_parent,
			global_position + Vector2(0.0, -40.0),
			Color(0.42, 0.95, 0.68, 0.9)
		)
	activated.emit(self)
