class_name TrainingDummy
extends CharacterBody2D
## Enemigo de prueba inmóvil. Sirve para comprobar que la hitbox del ataque
## aplica daño, actualiza la vida y elimina al enemigo al llegar a cero.

@export_range(0, 999, 1) var contact_damage: int = 20
@export var inverted_gravity: bool = false
## Si es cierto, el jugador atraviesa a este enemigo mientras hace un impulso.
@export var intangible_during_dash: bool = true

@onready var health: Health = $Health
@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

var _hit_tween: Tween
var _bob_time: float = 0.0
var _gravity_sign: float = 1.0
var _visual_base_y: float = -6.0
var _is_dead: bool = false
var _start_position: Vector2 = Vector2.ZERO
var _start_recorded: bool = false


func _ready() -> void:
	_gravity_sign = -1.0 if inverted_gravity else 1.0
	if inverted_gravity:
		up_direction = Vector2.DOWN
		visual.scale.y = -1.0
		_visual_base_y = 6.0
		var shadow := get_node_or_null("Shadow") as Polygon2D
		if shadow != null:
			shadow.position.y = -24.0
		var head := get_node_or_null("HeadShape") as CollisionShape2D
		if head != null:
			head.position.y = -head.position.y
		damage_shape.position.y = -damage_shape.position.y

	health.died.connect(_on_died)
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	# Los layouts colocan al enemigo después de añadirlo: la posición inicial
	# se anota al final del frame (2026-11-18).
	_record_start.call_deferred()


func _record_start() -> void:
	if not _start_recorded and is_inside_tree():
		_start_position = position
		_start_recorded = true


## Devuelve al enemigo a su posición y estado iniciales (al morir el jugador).
## En enemigos sobre plataformas móviles la posición es local a la plataforma.
func reset_to_start() -> void:
	if not _start_recorded or _is_dead:
		return
	position = _start_position
	velocity = Vector2.ZERO
	_reset_state()


## Gancho para que cada enemigo reinicie su máquina de estados y temporizadores.
func _reset_state() -> void:
	pass


func _physics_process(_delta: float) -> void:
	_check_contact_damage()


func _process(delta: float) -> void:
	if _is_dead:
		return

	# Pequeño movimiento de respiración para que el objetivo se vea vivo.
	_bob_time += delta
	visual.position.y = _visual_base_y + sin(_bob_time * 3.0) * 1.5


## La hitbox del jugador llama a este método automáticamente.
func take_damage(amount: int, source: Node = null) -> void:
	if _is_dead:
		return

	health.take_damage(amount, source)
	if not health.is_dead:
		_flash_hit()


func _on_damage_area_body_entered(body: Node2D) -> void:
	if _is_dead or not body.has_method("take_damage"):
		return
	body.take_damage(_damage_against(body), self)


## Comprueba el contacto cada frame de física. `body_entered` solo avisa una
## vez; si el jugador sigue pegado al enemigo cuando termina su
## invulnerabilidad, este chequeo vuelve a aplicar el golpe.
func _check_contact_damage() -> void:
	if _is_dead:
		return
	for body in damage_area.get_overlapping_bodies():
		_on_damage_area_body_entered(body)


func _damage_against(body: Node2D) -> int:
	if body is Player:
		var player := body as Player
		return maxi(1, ceili(float(player.health.current_health) / 3.0))
	return contact_damage


func _flash_hit() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()

	visual.modulate = Color(1.0, 0.4, 0.4, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)


func _on_died() -> void:
	_is_dead = true
	Sfx.play("enemy_death", -8.0)
	collision_shape.set_deferred("disabled", true)
	damage_shape.set_deferred("disabled", true)
	damage_area.set_deferred("monitoring", false)

	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()

	var death_tween := create_tween()
	death_tween.tween_property(visual, "scale", Vector2(1.35, 0.15), 0.18)
	death_tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.18)
	death_tween.tween_callback(queue_free)
