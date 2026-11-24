class_name RockfallSpawner
extends Node2D
## Generador de rocas que caen (2026-11-17). Cada `interval` segundos elige un
## punto de impacto SIEMPRE por delante del jugador (entre `min_ahead` y
## `max_ahead` px en la dirección de avance, `ahead_direction`), busca con un rayo la primera superficie bajo ese punto y crea una
## FallingRock que cuelga arriba y cae 0,2 s después de que el jugador se ponga debajo. Solo actúa mientras el jugador está
## entre `min_x` y `max_x` (las islas de inicio y final quedan a salvo). Si el
## punto cae sobre un foso no hay superficie y no se crea roca.

@export var interval: float = 2.2
@export var initial_delay: float = 3.0
@export var min_x: float = 0.0
@export var max_x: float = 100000.0
@export_range(0.0, 1.0, 0.05) var double_chance: float = 0.3
## 1 = el nivel avanza hacia la derecha, -1 hacia la izquierda.
@export var ahead_direction: float = 1.0
@export var min_ahead: float = 80.0
@export var max_ahead: float = 480.0
@export var double_gap: float = 170.0
@export var active: bool = true

var _timer: float = 0.0


func _ready() -> void:
	add_to_group("rockfall_spawners")
	_timer = initial_delay


func _process(delta: float) -> void:
	if not active:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.health.is_dead:
		return
	if player.global_position.x < min_x or player.global_position.x > max_x:
		return
	_spawn_event(player)


func _spawn_event(player: Player) -> void:
	var x := player.global_position.x + ahead_direction * randf_range(min_ahead, max_ahead)
	spawn_rock_at(x)
	if randf() < double_chance:
		# La segunda roca también cae por delante, más lejos que la primera.
		spawn_rock_at(x + ahead_direction * double_gap)


func spawn_rock_at(x: float) -> FallingRock:
	## Crea una roca que impactará en la primera superficie bajo `x`; devuelve
	## null si no hay cámara o no hay nada sólido debajo (foso).
	var camera := get_tree().get_first_node_in_group("camera") as Camera2D
	if camera == null:
		camera = get_viewport().get_camera_2d()
	if camera == null:
		return null
	var half := get_viewport().get_visible_rect().size * 0.5 / maxf(camera.zoom.x, 0.01)
	var center := camera.get_screen_center_position()
	var clamped_x := clampf(x, center.x - half.x + 40.0, center.x + half.x - 40.0)
	var top := center.y - half.y
	var query := PhysicsRayQueryParameters2D.create(Vector2(clamped_x, top), Vector2(clamped_x, top + 1600.0), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null

	var rock := FallingRock.new()
	rock.name = "FallingRock"
	rock.target_y = float(hit["position"].y)
	rock.start_y = top + 70.0  # cuelga visible, en el borde superior de la pantalla
	rock.position = Vector2(clamped_x, rock.start_y)
	get_parent().add_child(rock)
	return rock
