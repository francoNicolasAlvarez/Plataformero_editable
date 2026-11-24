class_name EnemyProjectile
extends Area2D
## Proyectil enemigo: viaja en horizontal, daña una vez y desaparece al
## impactar o al agotar su tiempo de vida. Tres estilos: FIRE (orbe azul del
## mago, 3 por disparo), SENTRY (descarga roja del centinela del nivel 6) y
## BOLT (flecha del arquero, más rápida y sin estela).

enum Style { FIRE, BOLT }

const FIREBALL_TEXTURE := preload("res://assets/enemies/fireball.svg")
const SENTRY_TEXTURE := preload("res://assets/enemies/sentry_bolt.svg")
const BOLT_TEXTURE := preload("res://assets/enemies/crossbow_bolt.svg")
const FIRE_IMPACT := Color(0.35, 0.8, 1.0, 0.9)
const SENTRY_IMPACT := Color(1.0, 0.3, 0.12, 0.9)

@export var style: Style = Style.FIRE
@export_range(50.0, 600.0, 5.0) var speed: float = 230.0
@export_range(1, 99, 1) var damage: int = 15
@export_range(0.2, 10.0, 0.1) var lifetime: float = 3.0

var direction: float = 1.0
var vertical_speed: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var impact_color: Color = FIRE_IMPACT
var _life_left: float = 0.0
var _spin_rate: float = 4.0
var _sentry_style: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: Sprite2D = $Glow


func _ready() -> void:
	add_to_group("enemy_projectiles")
	_life_left = lifetime
	body_entered.connect(_on_body_entered)
	apply_style()


func use_sentry_style() -> void:
	## Descarga roja del centinela del nivel 6 (2026-11-16).
	_sentry_style = true
	style = Style.FIRE
	apply_style()


func use_bolt_style() -> void:
	## Flecha del arquero.
	style = Style.BOLT
	apply_style()


func is_sentry_style() -> bool:
	return _sentry_style and style == Style.FIRE


func apply_style() -> void:
	## Aplica el aspecto del estilo actual; idempotente y seguro de rellamar.
	if sprite == null:
		return  # Aún no entró en escena; _ready aplicará el estilo.
	var trail := get_node_or_null("FlameTrail") as CPUParticles2D
	if style == Style.BOLT:
		sprite.texture = BOLT_TEXTURE
		glow.visible = false
		_spin_rate = 0.0
		if trail != null:
			trail.queue_free()
		return

	sprite.texture = SENTRY_TEXTURE if _sentry_style else FIREBALL_TEXTURE
	glow.modulate = Color(1.0, 0.3, 0.15, 0.32) if _sentry_style else Color(0.25, 0.6, 1.0, 0.32)
	impact_color = SENTRY_IMPACT if _sentry_style else FIRE_IMPACT
	glow.visible = true
	_spin_rate = 4.0
	if trail == null:
		if _sentry_style:
			Fx.make_sentry_trail(self)
		else:
			Fx.make_fire_trail(self)
	elif _sentry_style:
		Fx.apply_sentry_trail(trail)
	else:
		Fx.apply_fire_trail(trail)


func _physics_process(delta: float) -> void:
	if not velocity.is_zero_approx():
		position += velocity * delta
	else:
		position.x += speed * direction * delta
		position.y += vertical_speed * delta
	rotation += _spin_rate * delta * direction
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# El impulso del jugador atraviesa los proyectiles sin dañar ni detenerlos.
	if body is Player and (body as Player).is_intangible():
		return
	if body.has_method("take_damage") and not body.is_in_group("enemies"):
		body.take_damage(_damage_against(body), self)
	if style == Style.FIRE:
		# Los orbes estallan; la flecha se clava sin ruido.
		var impact_parent := get_parent() as Node2D
		if impact_parent != null:
			Fx.make_burst(impact_parent, position, impact_color)
	queue_free()


func _damage_against(body: Node2D) -> int:
	if body is Player:
		var player := body as Player
		return maxi(1, ceili(float(player.health.current_health) / 3.0))
	return damage
