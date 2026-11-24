class_name LevelFourRoute
extends Node2D
## Tramo principal del Gran Pozo (2026-11-13). Todos los huecos de la ruta
## tienen una plataforma activa a la vez: no hay reciclado ni plataformas que
## desaparezcan. La separación entre huecos (490 px) garantiza que ni las
## plataformas ni sus trayectorias se solapen.
##
## Los huecos de ruta y sus trayectorias son datos estáticos para que el test
## pueda validar el alcance y la separación de toda la cadena.

const PLATFORM_SCENE := preload("res://scenes/world/moving_platform.tscn")
const SPREAD_SCENE := preload("res://scenes/enemies/spread_enemy.tscn")

const ROUTE_START := 2140.0
const ROUTE_STEP := 480.0
const ROUTE_COUNT := 17
const ROUTE_Y := 560.0
const SPEED_SCALE := 1.3

const MOTION_VERTICAL := 0
const MOTION_DIAGONAL := 1
const MOTION_CIRCLE := 2
const MOTION_ROTATING := 3

var player: Player

var _platforms: Array[Node2D] = []


func setup(target: Player) -> void:
	player = target
	for index in ROUTE_COUNT:
		_spawn_slot(index)


func get_active_slot_indices() -> Array[int]:
	var indices: Array[int] = []
	for platform in _platforms:
		indices.append(int(platform.get_meta("slot_index", -1)))
	indices.sort()
	return indices


func _spawn_slot(index: int) -> Node2D:
	var platform := PLATFORM_SCENE.instantiate() as Node2D
	platform.name = "RoutePlatform%d" % index
	platform.position = slot_origin(index)
	platform.add_to_group("main_route")
	platform.set_meta("slot_index", index)
	add_child(platform)
	configure_platform(platform, index)
	_attach_enemy(platform, index)
	_platforms.append(platform)
	return platform


func _attach_enemy(platform: Node2D, index: int) -> void:
	for child in platform.get_children():
		if child.is_in_group("platform_enemies"):
			platform.remove_child(child)
			child.queue_free()
	var config := motion_config(index)
	if index % 2 != 0 or String(config["kind"]) == "rotating":
		return
	var enemy := SPREAD_SCENE.instantiate() as Node2D
	enemy.name = "PlatformGuard%d" % index
	enemy.position = Vector2(0.0, -35.0)
	enemy.set("gravity", 0.0)
	enemy.set("patrol_speed", 0.0)
	enemy.set("patrol_distance", 10.0)
	enemy.set("shoot_range", 420.0)
	enemy.set("anchored", true)
	enemy.add_to_group("platform_enemies")
	platform.add_child(enemy)


static func slot_origin(index: int) -> Vector2:
	return Vector2(ROUTE_START + float(index) * ROUTE_STEP, ROUTE_Y)


static func motion_config(index: int) -> Dictionary:
	var phase := float(index % 3) * 0.08
	var config := {
		"travel": Vector2.ZERO,
		"speed": 1.0,
		"circle_radius": 0.0,
		"circle_speed": 0.0,
		"rotation_speed": 0.0,
		"kind": "vertical",
	}
	match index % 4:
		MOTION_VERTICAL:
			config["travel"] = Vector2(0.0, 80.0)
			config["speed"] = (0.85 + phase) * SPEED_SCALE
			config["kind"] = "vertical"
		MOTION_DIAGONAL:
			config["travel"] = Vector2(65.0, 55.0) if index % 8 < 4 else Vector2(-65.0, 55.0)
			config["speed"] = (0.95 + phase) * SPEED_SCALE
			config["kind"] = "diagonal"
		MOTION_CIRCLE:
			config["circle_radius"] = 50.0
			config["circle_speed"] = (0.8 + phase) * SPEED_SCALE
			config["kind"] = "circle"
		MOTION_ROTATING:
			config["rotation_speed"] = (0.7 + phase * 0.5) * SPEED_SCALE
			config["kind"] = "rotating"
	return config


static func configure_platform(platform: Node2D, index: int) -> void:
	var config := motion_config(index)
	platform.set("travel", config["travel"])
	platform.set("speed", config["speed"])
	platform.set("circle_radius", config["circle_radius"])
	platform.set("circle_speed", config["circle_speed"])
	platform.set("rotation_speed", config["rotation_speed"])


static func trajectory_points(index: int, samples: int = 40) -> Array[Vector2]:
	var config := motion_config(index)
	var origin := slot_origin(index)
	var radius: float = config["circle_radius"]
	var travel: Vector2 = config["travel"]
	var points: Array[Vector2] = []
	for sample in samples:
		var phase := TAU * float(sample) / float(samples)
		if radius > 0.0:
			points.append(origin + Vector2(cos(phase), sin(phase)) * radius)
		else:
			points.append(origin + travel * (0.5 - 0.5 * cos(phase)))
	return points
