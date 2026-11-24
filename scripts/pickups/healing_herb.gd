class_name HealingHerb
extends Area2D
## Curación provisional. Restaura vida al tocarla y solo se consume si el
## jugador tiene vida perdida.

signal healed(amount: int)

@export_range(1, 999, 1) var heal_amount: int = 35

var _used: bool = false
var _time: float = 0.0

@onready var visual: Node2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_time = global_position.x * 0.01
	Fx.make_sparkle(visual, Vector2(0.0, -6.0), Color(0.7, 1.0, 0.75, 0.9))


func _process(delta: float) -> void:
	if _used:
		return
	_time += delta
	visual.position.y = sin(_time * 2.2) * 2.5
	visual.rotation = sin(_time * 1.8) * 0.08


func _on_body_entered(body: Node2D) -> void:
	if _used or not body is Player:
		return

	var player := body as Player
	if player.health.is_dead or player.health.current_health >= player.health.max_health:
		return

	_used = true
	player.health.heal(heal_amount)
	Sfx.play("heal", -6.0)
	_burst_sparks(Color(0.55, 1.0, 0.6, 0.9))
	healed.emit(heal_amount)
	queue_free()


func _burst_sparks(color: Color) -> void:
	## El estallido vive en el nivel, no en la hierba.
	var burst_parent := get_parent()
	if burst_parent == null:
		return
	var burst_position := Vector2.ZERO
	if burst_parent is Node2D:
		burst_position = global_position - (burst_parent as Node2D).global_position
	Fx.make_burst(burst_parent, burst_position, color)
