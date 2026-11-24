class_name LevelConfig
extends Resource
## Configuración declarativa de un nivel de la expedición (2026-11-17).
## Guarda el destino, el límite de tiempo y los umbrales de medalla. Los
## niveles todavía no creados tienen `scene_path` vacío y no se pueden cargar.

@export var number: int = 0
@export var world_number: int = 0
@export var index_in_world: int = 0
@export var display_name: String = ""
@export var mood: String = ""
@export var scene_path: String = ""
@export var time_limit: float = 70.0
@export var gold_time: float = 35.0
@export var silver_time: float = 50.0
@export var bronze_time: float = 70.0


func is_implemented() -> bool:
	return not scene_path.is_empty()


func code() -> String:
	return "%d-%d" % [world_number, index_in_world]


func label() -> String:
	return "%s · %s" % [code(), display_name]
