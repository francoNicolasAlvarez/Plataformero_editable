class_name Catapult
extends Hazard
## Catapulta (2026-11-24, mundo 6): marca en el suelo la zona de impacto (círculo
## rojo parpadeante) durante `warning_time` y lanza un peñasco en parábola que
## cae justo ahí. Apunta entre `min_ahead` y `max_ahead` px por delante del
## jugador, dentro de [`min_x`, `max_x`] (la franja donde puede caer). El
## peñasco quita un golpe al tocar al jugador y se rompe contra el suelo. El
## nodo está sobre la base de la catapulta; `ground_y` es la superficie.

const LAUNCH_ANGLE := deg_to_rad(55.0)

@export var ground_y: float = 640.0
@export var min_x: float = 0.0
@export var max_x: float = 6000.0
@export var min_ahead: float = 60.0
@export var max_ahead: float = 360.0
@export var gravity: float = 1200.0

var target_x: float = 0.0
var _marker_visible: bool = false
var _time: float = 0.0


func _ready() -> void:
	super._ready()
	warning_time = 1.6
	active_time = 1.0
	cooldown_time = maxf(cooldown_time, 1.8)
	z_index = 2


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_state_entered(new_state: int) -> void:
	match new_state:
		State.WARNING:
			target_x = _pick_target()
			_marker_visible = true
		State.ACTIVE:
			_launch()
		State.COOLDOWN, State.IDLE:
			_marker_visible = false


func _on_reset() -> void:
	_marker_visible = false
	for boulder in get_tree().get_nodes_in_group("thrown_boulders"):
		boulder.queue_free()


func _pick_target() -> float:
	var player := get_tree().get_first_node_in_group("player") as Player
	var base := global_position.x
	if player != null:
		var ahead := signf(player.velocity.x) if absf(player.velocity.x) > 20.0 else 1.0
		base = player.global_position.x + ahead * randf_range(min_ahead, max_ahead)
	return clampf(base, min_x, max_x)


## Velocidad inicial para pasar por el objetivo con el ángulo fijo:
## v² = g·d² / (2·cos²θ·(d·tanθ + Δy)), con Δy positivo hacia abajo.
func launch_speed(origin: Vector2, target: Vector2) -> float:
	var distance := absf(target.x - origin.x)
	var drop := target.y - origin.y
	var denom := 2.0 * pow(cos(LAUNCH_ANGLE), 2.0) * (distance * tan(LAUNCH_ANGLE) + drop)
	if distance < 1.0 or denom <= 1.0:
		return 700.0
	return clampf(sqrt(gravity * distance * distance / denom), 200.0, 1400.0)


func _launch() -> void:
	var origin := global_position + Vector2(0.0, -70.0)
	var target := Vector2(target_x, ground_y - ThrownBoulder.DIAMETER * 0.5)
	var direction := 1.0 if target.x >= origin.x else -1.0
	var boulder := ThrownBoulder.new()
	boulder.name = "CatapultBoulder"
	boulder.fall_gravity = gravity
	boulder.velocity = Vector2(direction * cos(LAUNCH_ANGLE), -sin(LAUNCH_ANGLE)) * launch_speed(origin, target)
	get_parent().add_child(boulder)
	boulder.global_position = origin
	Sfx.play("bomb", -10.0)


func _draw() -> void:
	# Base de madera y brazo (se levanta al cargar y cae al disparar).
	var arm_angle := -0.6
	if state == State.WARNING:
		arm_angle = lerpf(-0.6, 0.9, warning_progress())
	elif state == State.ACTIVE:
		arm_angle = -0.9
	draw_rect(Rect2(-34.0, -22.0, 68.0, 22.0), Color("#7a5230"), true)
	draw_rect(Rect2(-34.0, -22.0, 68.0, 22.0), Color.BLACK, false, 3.0)
	var tip := Vector2(0.0, -34.0) + Vector2.from_angle(arm_angle - PI * 0.5) * 62.0
	draw_line(Vector2(0.0, -34.0), tip, Color("#4d3319"), 8.0)
	draw_circle(tip, 11.0, Color("#8d8f99"))
	# Marcador de impacto en el suelo (coordenadas locales).
	if _marker_visible:
		var local := Vector2(target_x - global_position.x, ground_y - global_position.y)
		var blink := 0.35 + 0.35 * (0.5 + 0.5 * sin(_time * 14.0))
		draw_circle(local + Vector2(0.0, -3.0), 46.0, Color(1.0, 0.15, 0.1, blink * 0.5))
		draw_arc(local + Vector2(0.0, -3.0), 46.0, 0.0, TAU, 32, Color(1.0, 0.2, 0.15, 0.4 + blink), 3.0)
