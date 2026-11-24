class_name LevelRegistry
extends RefCounted
## Registro de los 40 niveles previstos, agrupados en 8 mundos de 5 niveles
## (2026-11-17). Los ocho niveles ya creados ocupan los primeros ocho huecos
## secuenciales; el resto son configuraciones pendientes sin escena cargable.

const WORLD_COUNT := 8
const LEVELS_PER_WORLD := 5
const LEVEL_COUNT := WORLD_COUNT * LEVELS_PER_WORLD
const DEFAULT_TIME_LIMIT := 70.0
const DEFAULT_GOLD_TIME := 35.0
const DEFAULT_SILVER_TIME := 50.0
const DEFAULT_BRONZE_TIME := 70.0

const WORLD_NAMES := [
	"PRADERAS Y COLINAS",
	"RUINAS ANTIGUAS",
	"DESIERTO",
	"CAVERNAS Y MINAS",
	"TORRES Y ALTURAS",
	"FORTALEZA MEDIEVAL",
	"LABORATORIO Y TECNOLOGÍA",
	"VOLCÁN Y FINAL",
]

const IMPLEMENTED_LEVELS := {
	1: {"name": "DÍA", "mood": "DÍA", "path": "res://scenes/levels/level_one.tscn"},
	2: {"name": "ATARDECER", "mood": "ATARDECER", "path": "res://scenes/levels/level_two.tscn"},
	3: {"name": "NOCHE", "mood": "NOCHE", "path": "res://scenes/levels/level_three.tscn"},
	4: {"name": "ABISMO", "mood": "ABISMO", "path": "res://scenes/levels/level_four.tscn"},
	5: {"name": "CIELO", "mood": "CIELO", "path": "res://scenes/levels/level_five.tscn"},
	6: {"name": "FORTALEZA", "mood": "FORTALEZA", "path": "res://scenes/levels/level_six.tscn"},
	7: {"name": "INVERSO", "mood": "INVERSO", "path": "res://scenes/levels/level_seven.tscn"},
	8: {"name": "ESPEJO", "mood": "ESPEJO", "path": "res://scenes/levels/level_eight.tscn"},
	9: {"name": "RUINAS", "mood": "RUINAS", "path": "res://scenes/levels/level_nine.tscn"},
	10: {"name": "TEMPLO", "mood": "TEMPLO", "path": "res://scenes/levels/level_ten.tscn"},
	11: {"name": "VIENTO", "mood": "VIENTO", "path": "res://scenes/levels/level_eleven.tscn"},
	12: {"name": "DUNAS", "mood": "DUNAS", "path": "res://scenes/levels/level_twelve.tscn"},
	13: {"name": "OASIS", "mood": "OASIS", "path": "res://scenes/levels/level_thirteen.tscn"},
	14: {"name": "CAÑÓN", "mood": "CAÑÓN", "path": "res://scenes/levels/level_fourteen.tscn"},
	15: {"name": "TORMENTA", "mood": "TORMENTA", "path": "res://scenes/levels/level_fifteen.tscn"},
	16: {"name": "GRUTA", "mood": "GRUTA", "path": "res://scenes/levels/level_sixteen.tscn"},
	17: {"name": "MINA", "mood": "MINA", "path": "res://scenes/levels/level_seventeen.tscn"},
	18: {"name": "CRISTALES", "mood": "CRISTALES", "path": "res://scenes/levels/level_eighteen.tscn"},
	19: {"name": "GALERÍA", "mood": "GALERÍA", "path": "res://scenes/levels/level_nineteen.tscn"},
	20: {"name": "DERRUMBE", "mood": "DERRUMBE", "path": "res://scenes/levels/level_twenty.tscn"},
	21: {"name": "LABERINTO", "mood": "LABERINTO", "path": "res://scenes/levels/level_twentyone.tscn"},
	22: {"name": "CAMPANARIO", "mood": "CAMPANARIO", "path": "res://scenes/levels/level_twentytwo.tscn"},
	23: {"name": "PUENTES", "mood": "PUENTES", "path": "res://scenes/levels/level_twentythree.tscn"},
	24: {"name": "NUBES", "mood": "NUBES", "path": "res://scenes/levels/level_twentyfour.tscn"},
	25: {"name": "CIUDADELA", "mood": "CIUDADELA", "path": "res://scenes/levels/level_twentyfive.tscn"},
	26: {"name": "FOSO", "mood": "FOSO", "path": "res://scenes/levels/level_twentysix.tscn"},
	27: {"name": "MURALLAS", "mood": "MURALLAS", "path": "res://scenes/levels/level_twentyseven.tscn"},
	28: {"name": "MAZMORRA", "mood": "MAZMORRA", "path": "res://scenes/levels/level_twentyeight.tscn"},
	29: {"name": "CATAPULTAS", "mood": "CATAPULTAS", "path": "res://scenes/levels/level_twentynine.tscn"},
	30: {"name": "SALA DEL TRONO", "mood": "SALA DEL TRONO", "path": "res://scenes/levels/level_thirty.tscn"},
}

static var _worlds: Array[WorldConfig] = []
static var _levels: Array[LevelConfig] = []
static var _initialized := false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	for world_number in range(1, WORLD_COUNT + 1):
		var world := WorldConfig.new()
		world.number = world_number
		world.display_name = WORLD_NAMES[world_number - 1]
		world.accent = _accent_for(world_number)
		for index_in_world in range(1, LEVELS_PER_WORLD + 1):
			var number := (world_number - 1) * LEVELS_PER_WORLD + index_in_world
			var config := LevelConfig.new()
			config.number = number
			config.world_number = world_number
			config.index_in_world = index_in_world
			config.time_limit = DEFAULT_TIME_LIMIT
			config.gold_time = DEFAULT_GOLD_TIME
			config.silver_time = DEFAULT_SILVER_TIME
			config.bronze_time = DEFAULT_BRONZE_TIME
			if IMPLEMENTED_LEVELS.has(number):
				var data: Dictionary = IMPLEMENTED_LEVELS[number]
				config.display_name = data["name"]
				config.mood = data["mood"]
				config.scene_path = data["path"]
			else:
				config.display_name = "POR CONSTRUIR"
				config.mood = world.display_name
			world.levels.append(config)
			_levels.append(config)
		_worlds.append(world)


static func _accent_for(world_number: int) -> Color:
	match world_number:
		1:
			return Color(0.45, 0.78, 0.35)
		2:
			return Color(0.55, 0.55, 0.72)
		3:
			return Color(0.90, 0.72, 0.34)
		4:
			return Color(0.48, 0.40, 0.62)
		5:
			return Color(0.40, 0.75, 0.95)
		6:
			return Color(0.68, 0.48, 0.36)
		7:
			return Color(0.40, 0.90, 0.78)
		8:
			return Color(0.92, 0.34, 0.28)
	return Color.WHITE


static func is_valid_level(level_number: int) -> bool:
	return level_number >= 1 and level_number <= LEVEL_COUNT


static func get_level(level_number: int) -> LevelConfig:
	_ensure_initialized()
	if not is_valid_level(level_number):
		return null
	return _levels[level_number - 1]


static func get_world(world_number: int) -> WorldConfig:
	_ensure_initialized()
	if world_number < 1 or world_number > WORLD_COUNT:
		return null
	return _worlds[world_number - 1]


static func get_world_for_level(level_number: int) -> WorldConfig:
	return get_world((level_number - 1) / LEVELS_PER_WORLD + 1)


static func all_levels() -> Array[LevelConfig]:
	_ensure_initialized()
	return _levels.duplicate()


static func all_worlds() -> Array[WorldConfig]:
	_ensure_initialized()
	return _worlds.duplicate()


static func levels_in_world(world_number: int) -> Array[LevelConfig]:
	var world := get_world(world_number)
	if world == null:
		return []
	return world.levels.duplicate()


static func implemented_levels() -> Array[LevelConfig]:
	var result: Array[LevelConfig] = []
	for config in all_levels():
		if config.is_implemented():
			result.append(config)
	return result


static func is_implemented(level_number: int) -> bool:
	var config := get_level(level_number)
	return config != null and config.is_implemented()


static func scene_path_for(level_number: int) -> String:
	var config := get_level(level_number)
	if config == null:
		return ""
	return config.scene_path


static func next_implemented_level(level_number: int) -> int:
	for config in all_levels():
		if config.number > level_number and config.is_implemented():
			return config.number
	return -1


static func label_for(level_number: int) -> String:
	var config := get_level(level_number)
	if config == null:
		return "NIVEL %d" % level_number
	return config.label()
