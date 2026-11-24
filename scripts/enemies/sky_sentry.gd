class_name SkySentry
extends Node2D
## Centinela del nivel 6 (2026-11-16): permanece fijo en la esquina superior
## derecha de la pantalla, se desplaza con la cǭmara y dispara un cono de
## proyectiles apuntado al jugador cada 2 s. No tiene vida ni colisi��n.

const PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

const PROJECTILE_LIFETIME := 30.0

## 2.0 s / 0.75 = 25 % menos frecuencia de disparo.
@export_range(0.5, 6.0, 0.01) var shoot_interval: float = 4.0 / 0.75
@export_range(80.0, 600.0, 10.0) var projectile_speed: float = 260.0
@export_range(0.0, 160.0, 1.0) var top_margin: float = 80.0
@export_range(0.0, 260.0, 1.0) var right_margin: float = 120.0
@export_range(0.0, 20.0, 0.5) var bob_amplitude: float = 4.0

@onready var eye: Polygon2D = $Visual/Eye
@onready var muzzle: Marker2D = $Muzzle

var _cooldown: float = 0.0
var _rings: SentryRings
var _time: float = 0.0


func _ready() -> void:
	add_to_group("sky_sentries")
	_cooldown = shoot_interval
	_rings = SentryRings.new()
	_rings.name = "ChargeRings"
	add_child(_rings)
	_follow_screen_top()


func reset() -> void:
	## Al morir el jugador se cancela la carga en curso y se reinicia el ciclo.
	_cooldown = shoot_interval
	if _rings != null:
		_rings.stop()


func _process(delta: float) -> void:
	_time += delta
	_follow_screen_top()
	_cooldown -= delta
	# Tres círculos se cierran sobre el ojo (rápido, medio, lento); al cerrarse
	# el último se dispara.
	var charge_time := SentryRings.total_time()
	if _cooldown > 0.0 and _cooldown <= charge_time:
		_rings.position = to_local(eye.global_position) if eye != null else Vector2.ZERO
		_rings.set_elapsed(charge_time - _cooldown)
	if _cooldown <= 0.0:
		_rings.stop()
		_shoot_at_player()
		_cooldown = shoot_interval
	if eye != null:
		var pulse := 1.0 + 0.08 * sin(_time * 4.0)
		eye.scale = Vector2(pulse, pulse)


func _follow_screen_top() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var viewport_size := get_viewport_rect().size
	var visible_width := viewport_size.x / maxf(camera.zoom.x, 0.01)
	var visible_height := viewport_size.y / maxf(camera.zoom.y, 0.01)
	var top_y := center.y - visible_height * 0.5 + top_margin
	var bob := sin(_time * 2.0) * bob_amplitude
	global_position = Vector2(center.x + visible_width * 0.5 - right_margin, top_y + bob)


func is_charging() -> bool:
	return _rings != null and _rings.active


func _shoot_at_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var origin := global_position
	if muzzle != null:
		origin = muzzle.global_position
	var aim := (player.global_position - origin).normalized()
	if aim.is_zero_approx():
		return
	var parent := get_parent()
	if parent == null:
		return

	var count := 5
	var cone_angle := deg_to_rad(70.0)
	var step := cone_angle / float(count - 1)
	var start_angle := aim.angle() - cone_angle * 0.5
	for index in count:
		var angle := start_angle + step * float(index)
		var direction := Vector2(cos(angle), sin(angle))
		var projectile := PROJECTILE_SCENE.instantiate() as EnemyProjectile
		# Solo desaparece al tocar suelo, plataforma o jugador; la vida larga
		# es una red de seguridad si sale del mundo.
		projectile.lifetime = PROJECTILE_LIFETIME
		parent.add_child(projectile)
		projectile.use_sentry_style()
		projectile.global_position = origin
		projectile.direction = 1.0 if direction.x >= 0.0 else -1.0
		projectile.speed = projectile_speed
		projectile.velocity = direction * projectile_speed
		projectile.rotation = angle
	Sfx.play("sentry", -15.0)
