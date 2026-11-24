class_name WallCannon
extends Hazard
## Cañón de pared (2026-11-24, mundo 6): empotrado en una muralla, avisa con la
## boca al rojo y un retroceso (`warning_time`) y dispara una bola horizontal
## (`direction` 1 = derecha, -1 = izquierda). Se esquiva saltando o con el
## impulso. El nodo está en el centro de la boca del cañón.

const PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

@export var direction: float = 1.0
@export_range(100.0, 600.0, 10.0) var shot_speed: float = 300.0
@export_range(1, 99, 1) var damage: int = 15


func _ready() -> void:
	super._ready()
	warning_time = 0.9
	active_time = 0.15
	cooldown_time = maxf(cooldown_time, 2.2)
	queue_redraw()


func _process(_delta: float) -> void:
	if state != State.IDLE or auto_cycle:
		queue_redraw()


func _on_state_entered(new_state: int) -> void:
	if new_state == State.ACTIVE:
		_fire()
	queue_redraw()


func _fire() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(direction * 34.0, 0.0)
	projectile.direction = direction
	projectile.speed = shot_speed
	projectile.velocity = Vector2(direction * shot_speed, 0.0)
	projectile.damage = damage
	projectile.lifetime = 4.0
	if projectile.has_method("use_sentry_style"):
		projectile.use_sentry_style()
	Sfx.play("cannon", -8.0)
	Fx.make_burst(get_parent(), global_position + Vector2(direction * 36.0, 0.0), Color(1.0, 0.6, 0.2, 0.9))


func _draw() -> void:
	var warn := warning_progress()
	var recoil := -direction * 6.0 * (warn if state == State.WARNING else 0.0)
	# Cureña de piedra empotrada en el muro.
	draw_rect(Rect2(-direction * 30.0 - 24.0, -26.0, 48.0, 52.0), Color("#5d5a6e"), true)
	draw_rect(Rect2(-direction * 30.0 - 24.0, -26.0, 48.0, 52.0), Color.BLACK, false, 3.0)
	# Cañón de hierro.
	var barrel := Rect2(minf(0.0, direction * 36.0) + recoil, -12.0, 36.0, 24.0)
	draw_rect(barrel, Color("#2f2f3a").lerp(Color("#ff5a1f"), warn), true)
	draw_rect(barrel, Color.BLACK, false, 3.0)
	if state == State.WARNING:
		draw_circle(Vector2(direction * 36.0, 0.0), 6.0 + 6.0 * warn, Color(1.0, 0.45, 0.1, 0.35 + 0.5 * warn))
