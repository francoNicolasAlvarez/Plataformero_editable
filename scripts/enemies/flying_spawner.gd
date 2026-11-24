class_name FlyingSpawner
extends Node2D
## Generador de enemigos voladores (2026-11-13). No usa un punto fijo: espera
## `spawn_interval` segundos y crea un volador justo fuera del borde visible
## de la cámara, a la altura del jugador o a una altura aleatoria. El enemigo
## cruza la pantalla ondulando y se autodestruye al terminar su recorrido.
## Nivel 5: uno cada 3 s a altura aleatoria (petición del usuario).

enum HeightMode { RANDOM, PLAYER }

const ENEMY_SCENE := preload("res://scenes/enemies/flying_enemy.tscn")

@export var spawn_interval: float = 3.0
@export var initial_delay: float = 2.0
@export var height_mode: HeightMode = HeightMode.RANDOM
@export var min_height: float = 140.0
@export var max_height: float = 540.0
@export var side_margin: float = 70.0
@export var active: bool = true

var _timer: float = 0.0
var _next_side: int = 1


func _ready() -> void:
	add_to_group("flying_spawners")
	_timer = initial_delay


func _process(delta: float) -> void:
	if not active:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = spawn_interval
	_spawn()


func _spawn() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var camera := get_tree().get_first_node_in_group("camera") as Camera2D
	if player == null:
		return
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	var center := camera.get_screen_center_position()
	var zoom_x := maxf(camera.zoom.x, 0.01)
	var half_width := get_viewport().get_visible_rect().size.x / zoom_x * 0.5
	var side := 1 if randf() > 0.5 else -1
	_next_side = -side
	var spawn_x := center.x + float(side) * (half_width + side_margin + randf_range(0.0, 120.0))
	var spawn_y := _pick_height(player)
	var spawn_position := Vector2(spawn_x, spawn_y)

	var enemy := ENEMY_SCENE.instantiate() as FlyingEnemy
	var parent := get_parent()
	if parent == null:
		return
	enemy.position = parent.to_local(spawn_position)
	enemy.direction = -side
	parent.add_child(enemy)


func _pick_height(player: Player) -> float:
	var value := 0.0
	if height_mode == HeightMode.PLAYER:
		value = player.global_position.y
	else:
		value = randf_range(min_height, max_height)
	return clampf(value, min_height, max_height)


static func clear_flying_enemies(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("flying_enemies"):
		if is_instance_valid(node):
			node.queue_free()
