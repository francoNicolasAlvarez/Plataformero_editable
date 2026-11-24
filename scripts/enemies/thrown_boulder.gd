class_name ThrownBoulder
extends Area2D
## Roca lanzada por el bruto del nivel 9 (2026-11-17). Describe una parábola:
## sale a 45 grados, rápida, y la gravedad la curva. Su diámetro es 1,5 veces
## la altura del modelo del jugador (48 px -> 72 px). Quita un golpe al
## jugador y se rompe contra el primer suelo o plataforma. Se construye entera
## por código.

const PLAYER_HEIGHT := 48.0
const SIZE_FACTOR := 1.5
const DIAMETER := PLAYER_HEIGHT * SIZE_FACTOR

@export var damage: int = 15
@export var fall_gravity: float = 1200.0
@export var lifetime: float = 6.0

var velocity: Vector2 = Vector2.ZERO

var _life_left: float = 0.0
var _hit: bool = false


func _ready() -> void:
	add_to_group("thrown_boulders")
	collision_layer = 0
	collision_mask = 3
	_life_left = lifetime
	body_entered.connect(_on_body_entered)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = DIAMETER * 0.5
	shape.shape = circle
	add_child(shape)
	add_child(_build_visual())


func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	global_position += velocity * delta
	rotation += signf(velocity.x) * 7.0 * delta
	_life_left -= delta
	if _life_left <= 0.0 or global_position.y > 1500.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	# Las rocas del bruto no chocan con su propia pila de rocas.
	if body is RockPile:
		return
	if body is Player and (body as Player).is_intangible():
		return
	_hit = true
	if body is Player:
		(body as Player).take_damage(damage, self)
	var parent := get_parent()
	if parent is Node2D:
		Fx.make_burst(parent, global_position, Color(0.75, 0.62, 0.45, 0.9))
	Sfx.play("bomb", -12.0)
	queue_free()


func _build_visual() -> Node2D:
	var rock := Node2D.new()
	rock.name = "Visual"
	var radius := DIAMETER * 0.5
	var points := PackedVector2Array()
	var factors := [1.0, 0.9, 1.0, 0.86, 0.98, 0.9, 1.0, 0.88, 0.99, 0.92]
	for index in factors.size():
		var angle := TAU * float(index) / float(factors.size())
		points.append(Vector2(cos(angle), sin(angle)) * radius * float(factors[index]))
	var body := Polygon2D.new()
	body.polygon = points
	body.color = Color("#7d6d5c")
	rock.add_child(body)
	var shade := Polygon2D.new()
	shade.polygon = PackedVector2Array([
		Vector2(-radius * 0.2, -radius * 0.1), Vector2(radius * 0.6, -radius * 0.4),
		Vector2(radius * 0.9, radius * 0.2), Vector2(radius * 0.2, radius * 0.8),
		Vector2(-radius * 0.4, radius * 0.5),
	])
	shade.color = Color("#5c4f42")
	rock.add_child(shade)
	var crack := Line2D.new()
	crack.points = PackedVector2Array([
		Vector2(-radius * 0.5, -radius * 0.5), Vector2(-radius * 0.1, -radius * 0.1), Vector2(-radius * 0.3, radius * 0.3),
	])
	crack.width = 2.5
	crack.default_color = Color("#3d342b")
	rock.add_child(crack)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 3.5
	outline.default_color = Color.BLACK
	rock.add_child(outline)
	return rock
