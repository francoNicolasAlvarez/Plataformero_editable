class_name GrabItem
extends CharacterBody2D
## Objeto sujetable (2026-11-24, mundo 6). Al tocarlo el jugador lo agarra y lo
## lleva sobre la cabeza (solo uno a la vez). Tres tipos:
##  - CRATE (caja): con ABAJO en el suelo se deja delante y queda fija como un
##    peldaño sólido para llegar más alto.
##  - ROCK (roca): con IMPULSO (Ctrl) se lanza hacia delante; derriba a los
##    enemigos sin candado (`ChannelLock`) y se rompe al chocar.
##  - SPRING (resorte): mientras se lleva, los saltos son un 55 % más altos;
##    gasta una carga por salto (3) y desaparece al agotarse.
## `respawn_time` > 0 repone el objeto en su sitio tras gastarse. Al morir el
## jugador todos vuelven a su posición inicial (`reset_to_start`).

enum Kind { CRATE, ROCK, SPRING }

const GRAVITY := 1500.0
const THROW_SPEED := Vector2(640.0, -230.0)
const ROCK_DAMAGE := 99
const SPRING_BOOST := 1.55

@export var kind: Kind = Kind.CRATE
@export_range(0.0, 60.0, 0.5) var respawn_time: float = 0.0

var held_by: Player = null
var placed: bool = false
var thrown: bool = false
var charges: int = 3

var _start: Vector2
var _shape: CollisionShape2D
var _pickup: Area2D
var _visual: Node2D
var _hint: Label
var _cooldown: float = 0.0
var _spent: bool = false


func _ready() -> void:
	add_to_group("grab_items")
	_start = position
	collision_layer = 0
	collision_mask = 1
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _size()
	_shape.shape = rect
	add_child(_shape)
	_pickup = Area2D.new()
	_pickup.collision_layer = 0
	_pickup.collision_mask = 2
	var pickup_shape := CollisionShape2D.new()
	var pickup_rect := RectangleShape2D.new()
	pickup_rect.size = _size() + Vector2(14.0, 14.0)
	pickup_shape.shape = pickup_rect
	_pickup.add_child(pickup_shape)
	add_child(_pickup)
	_visual = Node2D.new()
	add_child(_visual)
	_build_visual()
	_hint = Label.new()
	_hint.size = Vector2(160.0, 18.0)
	_hint.position = Vector2(-80.0, -_size().y - 22.0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color.WHITE)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 5)
	_hint.visible = false
	add_child(_hint)


func _size() -> Vector2:
	match kind:
		Kind.CRATE:
			return Vector2(38.0, 38.0)
		Kind.ROCK:
			return Vector2(28.0, 26.0)
	return Vector2(26.0, 26.0)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _spent:
		return
	if held_by != null:
		_update_held()
		return
	if thrown:
		_fly(delta)
		return
	if placed:
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
		velocity.x = 0.0
		move_and_slide()
		return
	if _cooldown <= 0.0:
		for body in _pickup.get_overlapping_bodies():
			if body is Player and (body as Player).held_item == null and not (body as Player).health.is_dead:
				grab(body as Player)
				break


func grab(player: Player) -> void:
	held_by = player
	player.held_item = self
	if kind == Kind.SPRING:
		player.jump_height_scale = SPRING_BOOST
	_shape.set_deferred("disabled", true)
	collision_layer = 0
	_hint.text = _hint_text()
	_hint.visible = true
	Sfx.play("grab", -6.0)


func _hint_text() -> String:
	match kind:
		Kind.CRATE:
			return "ABAJO: dejar"
		Kind.ROCK:
			return "IMPULSO: lanzar"
	return "SALTO x%d" % charges


func _update_held() -> void:
	if held_by.health.is_dead:
		reset_to_start()
		return
	var gsign := -1.0 if held_by.inverted_gravity else 1.0
	global_position = held_by.global_position + Vector2(0.0, -46.0 * gsign)
	if kind == Kind.CRATE and Input.is_action_just_pressed("move_down") and held_by.is_on_floor():
		place()


func _detach() -> void:
	if held_by != null:
		held_by.held_item = null
		held_by.jump_height_scale = 1.0
	held_by = null
	_hint.visible = false
	_cooldown = 0.8


func place() -> void:
	## Caja: se deja delante del jugador y pasa a ser un peldaño sólido.
	var player := held_by
	_detach()
	placed = true
	global_position = player.global_position + Vector2(float(player.facing()) * 46.0, 24.0 - _size().y * 0.5)
	velocity = Vector2.ZERO
	collision_layer = 1
	_shape.set_deferred("disabled", false)
	Sfx.play("bomb", -16.0)


## Lo llama Player antes del impulso: devuelve true si el objeto lo consume.
func wants_dash() -> bool:
	if kind != Kind.ROCK or held_by == null:
		return false
	var player := held_by
	_detach()
	thrown = true
	collision_mask = 1 | 4
	var gsign := -1.0 if player.inverted_gravity else 1.0
	velocity = Vector2(THROW_SPEED.x * float(player.facing()), THROW_SPEED.y * gsign)
	global_position = player.global_position + Vector2(float(player.facing()) * 22.0, -26.0 * gsign)
	_shape.set_deferred("disabled", false)
	Sfx.play("throw", -8.0)
	return true


func on_jump() -> void:
	if kind != Kind.SPRING:
		return
	charges -= 1
	_hint.text = _hint_text()
	if charges <= 0:
		_consume()


func _fly(delta: float) -> void:
	velocity.y += GRAVITY * 0.8 * delta
	var collision := move_and_collide(velocity * delta)
	rotation += signf(velocity.x) * 9.0 * delta
	if collision == null:
		if global_position.y > 1600.0 or global_position.y < -900.0:
			_consume()
		return
	var other := collision.get_collider()
	if other is TrainingDummy and not bool((other as Node).get_meta("channel_locked", false)):
		(other as TrainingDummy).take_damage(ROCK_DAMAGE, self)
	_consume()


func _consume() -> void:
	_detach()
	Fx.make_burst(get_parent(), global_position, Color(0.75, 0.65, 0.5, 0.9))
	_spent = true
	thrown = false
	visible = false
	_shape.set_deferred("disabled", true)
	collision_layer = 0
	if respawn_time > 0.0:
		get_tree().create_timer(respawn_time).timeout.connect(reset_to_start)


func reset_to_start() -> void:
	_detach()
	placed = false
	thrown = false
	_spent = false
	charges = 3
	visible = true
	rotation = 0.0
	velocity = Vector2.ZERO
	position = _start
	collision_layer = 0
	collision_mask = 1
	_shape.set_deferred("disabled", false)
	_cooldown = 0.3


func _build_visual() -> void:
	var half := _size() * 0.5
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	match kind:
		Kind.CRATE:
			body.color = Color("#a8743d")
			_visual.add_child(body)
			for line in [[Vector2(-half.x, -half.y), Vector2(half.x, half.y)], [Vector2(half.x, -half.y), Vector2(-half.x, half.y)]]:
				var brace := Line2D.new()
				brace.points = PackedVector2Array(line)
				brace.width = 3.0
				brace.default_color = Color("#6d4722")
				_visual.add_child(brace)
		Kind.ROCK:
			body.color = Color("#8d8f99")
			body.polygon = PackedVector2Array([Vector2(-14, 10), Vector2(-11, -8), Vector2(0, -13), Vector2(12, -7), Vector2(14, 10)])
			_visual.add_child(body)
		Kind.SPRING:
			body.color = Color("#3fb8a6")
			body.polygon = PackedVector2Array([Vector2(-13, 13), Vector2(-13, 9), Vector2(13, 9), Vector2(13, 13)])
			_visual.add_child(body)
			var coil := Line2D.new()
			coil.points = PackedVector2Array([Vector2(-10, 9), Vector2(10, 4), Vector2(-10, -1), Vector2(10, -6), Vector2(-10, -11), Vector2(10, -13)])
			coil.width = 3.5
			coil.default_color = Color("#9ff0d8")
			_visual.add_child(coil)
	var outline := Line2D.new()
	outline.points = body.polygon
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color.BLACK
	_visual.add_child(outline)
