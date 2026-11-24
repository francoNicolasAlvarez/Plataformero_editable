class_name SaveGame
extends RefCounted
## Partida guardada del modo plataformas (2026-11-12): recuerda el último
## nivel alcanzado para continuar y acumula estadísticas de la expedición
## (tiempo total y muertes) que se muestran en la pantalla final.
##
## Fase contrarreloj (2026-11-17): además del progreso de la expedición se
## guarda, por nivel, el mejor tiempo, la mejor medalla y las muertes. El save
## antiguo sigue siendo válido: las secciones de registros se crean cuando se
## completa un nivel. En modo headless no lee ni escribe el archivo para no
## interferir con las pruebas: las variables estáticas conservan los valores
## por defecto.

const SAVE_PATH := "user://save.cfg"
const FIRST_LEVEL := 1
const LAST_LEVEL := 40
## Modo de pruebas: todos los mundos abiertos fuera de headless. Poner en
## false antes de exportar la versión final.
const DEV_UNLOCK_ALL := true
const RECORD_SECTION := "level_%d"

static var level: int = FIRST_LEVEL
static var total_time: float = 0.0
static var deaths: int = 0
static var completed: bool = false
static var best_times: Dictionary = {}
static var medals: Dictionary = {}
static var level_deaths: Dictionary = {}
static var completed_levels: Dictionary = {}
static var last_result_level: int = FIRST_LEVEL
static var last_result_time: float = 0.0
static var last_result_medal: String = MedalRules.NONE
static var last_result_deaths: int = 0
## Desbloqueo por mundos (2026-11-17): el mundo n+1 solo se abre al completar
## TODOS los niveles del mundo n seguidos en una misma pasada. Practicar niveles
## sueltos no cuenta. `world_run` es el mundo de la pasada activa (0 = ninguna)
## y `world_run_progress` cuántos niveles lleva completados en orden.
static var cleared_worlds: Dictionary = {}
static var world_run: int = 0
static var world_run_progress: int = 0
static var last_world_cleared: int = 0
static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if _is_headless():
		return

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	level = clampi(
		int(config.get_value("run", "level", FIRST_LEVEL)),
		FIRST_LEVEL,
		LAST_LEVEL
	)
	total_time = maxf(0.0, float(config.get_value("run", "total_time", 0.0)))
	deaths = maxi(0, int(config.get_value("run", "deaths", 0)))
	completed = bool(config.get_value("run", "completed", false))
	world_run = maxi(0, int(config.get_value("run", "world_run", 0)))
	world_run_progress = maxi(0, int(config.get_value("run", "world_run_progress", 0)))
	_load_records(config)
	_load_world_progress(config)


static func save() -> void:
	if _is_headless():
		return
	var config := ConfigFile.new()
	config.set_value("run", "level", level)
	config.set_value("run", "total_time", total_time)
	config.set_value("run", "deaths", deaths)
	config.set_value("run", "completed", completed)
	config.set_value("run", "world_run", world_run)
	config.set_value("run", "world_run_progress", world_run_progress)
	for world_number in cleared_worlds:
		config.set_value("worlds", "cleared_%d" % int(world_number), true)
	_save_records(config)
	config.save(SAVE_PATH)


static func set_level(next_level: int) -> void:
	ensure_loaded()
	level = clampi(next_level, FIRST_LEVEL, LAST_LEVEL)
	_sync_pass_with_level(level)
	save()


static func start_at_level(next_level: int) -> void:
	## Selección de nivel desde el menú: empieza una expedición limpia en ese
	## nivel sin conservar tiempo, muertes ni el estado de juego completado.
	## Los registros de medallas se conservan.
	ensure_loaded()
	level = clampi(next_level, FIRST_LEVEL, LAST_LEVEL)
	total_time = 0.0
	deaths = 0
	completed = false
	# Elegir un nivel empieza una pasada nueva: válida solo si es el primero
	# de su mundo; en cualquier otro nivel es práctica y no desbloquea nada.
	world_run = 0
	world_run_progress = 0
	_sync_pass_with_level(level)
	save()


static func add_time(seconds: float) -> void:
	if seconds > 0.0:
		total_time += seconds


static func register_death() -> void:
	ensure_loaded()
	deaths += 1
	save()


static func record_level_result(level_id: int, elapsed: float, medal: String, deaths_in_level: int) -> void:
	## Guarda el resultado contrarreloj de un nivel. Solo se conservan mejoras:
	## un tiempo menor, una medalla superior o más muertes registradas.
	ensure_loaded()
	var id := clampi(level_id, FIRST_LEVEL, LAST_LEVEL)
	var seconds := maxf(0.0, elapsed)
	if not best_times.has(id) or seconds < float(best_times[id]):
		best_times[id] = seconds
	if MedalRules.is_better(medal, get_medal(id)):
		medals[id] = medal
	level_deaths[id] = maxi(get_level_deaths(id), maxi(0, deaths_in_level))
	completed_levels[id] = true
	last_result_level = id
	last_result_time = seconds
	last_result_medal = medal
	last_result_deaths = maxi(0, deaths_in_level)
	last_world_cleared = 0
	_advance_pass(id)
	save()


static func has_level_record(level_id: int) -> bool:
	return best_times.has(level_id) or medals.has(level_id) or completed_levels.has(level_id)


static func get_best_time(level_id: int) -> float:
	return float(best_times.get(level_id, 0.0))


static func get_medal(level_id: int) -> String:
	return String(medals.get(level_id, MedalRules.NONE))


static func get_level_deaths(level_id: int) -> int:
	return int(level_deaths.get(level_id, 0))


static func is_level_completed(level_id: int) -> bool:
	return bool(completed_levels.get(level_id, false))


static func finish_game() -> void:
	## El juego se completó: la partida queda cerrada y el menú ofrecerá una
	## nueva expedición al pulsar Jugar.
	ensure_loaded()
	completed = true
	level = FIRST_LEVEL
	save()


static func begin_new_run() -> void:
	ensure_loaded()
	level = FIRST_LEVEL
	total_time = 0.0
	deaths = 0
	completed = false
	world_run = 0
	world_run_progress = 0
	_sync_pass_with_level(level)
	save()


static func is_world_cleared(world_number: int) -> bool:
	return cleared_worlds.has(world_number)


static func mark_world_cleared(world_number: int) -> void:
	cleared_worlds[world_number] = true


static func is_world_unlocked(world_number: int) -> bool:
	## El mundo 1 siempre está abierto; los demás exigen haber superado el
	## anterior en una pasada completa. Con DEV_UNLOCK_ALL todo queda abierto
	## para probar (los tests headless siguen validando la regla real).
	if DEV_UNLOCK_ALL and not _is_headless():
		return true
	return world_number <= 1 or is_world_cleared(world_number - 1)


static func is_level_unlocked(level_number: int) -> bool:
	var world := LevelRegistry.get_world_for_level(level_number)
	return world != null and is_world_unlocked(world.number)


static func unlock_hint(world_number: int) -> String:
	var previous := LevelRegistry.get_world(world_number - 1)
	if previous == null:
		return ""
	var count := _implemented_in_world(world_number - 1).size()
	return "Bloqueado: completa los %d niveles de «%s» seguidos en una misma pasada." % [count, previous.display_name]


static func world_run_total() -> int:
	return _implemented_in_world(world_run).size()


static func _implemented_in_world(world_number: int) -> Array[int]:
	var result: Array[int] = []
	for config in LevelRegistry.levels_in_world(world_number):
		if config.is_implemented():
			result.append(config.number)
	return result


static func _sync_pass_with_level(level_number: int) -> void:
	## Una pasada solo existe si empezó en el primer nivel de un mundo abierto
	## y se mantiene mientras se siga dentro de ese mundo.
	var world := LevelRegistry.get_world_for_level(level_number)
	if world == null:
		world_run = 0
		world_run_progress = 0
		return
	var numbers := _implemented_in_world(world.number)
	if not numbers.is_empty() and numbers[0] == level_number and is_world_unlocked(world.number):
		if world_run != world.number:
			world_run = world.number
			world_run_progress = 0
	elif world_run != world.number:
		world_run = 0
		world_run_progress = 0


static func _advance_pass(level_id: int) -> void:
	if world_run <= 0:
		return
	var numbers := _implemented_in_world(world_run)
	if world_run_progress >= numbers.size() or numbers[world_run_progress] != level_id:
		# Salió del orden de la pasada: no cuenta como pasada seguida.
		world_run = 0
		world_run_progress = 0
		return
	world_run_progress += 1
	if world_run_progress >= numbers.size():
		mark_world_cleared(world_run)
		last_world_cleared = world_run
		world_run = 0
		world_run_progress = 0


static func format_time(seconds: float) -> String:
	var whole := int(round(maxf(0.0, seconds)))
	return "%02d:%02d" % [whole / 60, whole % 60]


static func format_time_precise(seconds: float) -> String:
	var hundredths := int(round(maxf(0.0, seconds) * 100.0))
	return "%02d:%02d.%02d" % [hundredths / 6000, (hundredths / 100) % 60, hundredths % 100]


static func _section(level_id: int) -> String:
	return RECORD_SECTION % level_id


static func _load_records(config: ConfigFile) -> void:
	best_times.clear()
	medals.clear()
	level_deaths.clear()
	completed_levels.clear()
	for level_id in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var section := _section(level_id)
		if not config.has_section(section):
			continue
		var best := maxf(0.0, float(config.get_value(section, "best_time", 0.0)))
		if best > 0.0:
			best_times[level_id] = best
		var medal := String(config.get_value(section, "medal", MedalRules.NONE))
		if not medal.is_empty():
			medals[level_id] = medal
		var dead := maxi(0, int(config.get_value(section, "deaths", 0)))
		if dead > 0:
			level_deaths[level_id] = dead
		if bool(config.get_value(section, "completed", false)):
			completed_levels[level_id] = true


static func _load_world_progress(config: ConfigFile) -> void:
	cleared_worlds.clear()
	for world_number in range(1, LevelRegistry.WORLD_COUNT + 1):
		if bool(config.get_value("worlds", "cleared_%d" % world_number, false)):
			cleared_worlds[world_number] = true
	if config.has_section("worlds"):
		return
	# Partidas anteriores a esta regla: quien ya llegó a un mundo (o terminó el
	# juego) lo hizo por la cadena lineal, así que se respetan sus mundos.
	var reached := LevelRegistry.get_world_for_level(level).number
	if completed:
		for config_level in LevelRegistry.implemented_levels():
			reached = maxi(reached, config_level.world_number + 1)
	for world_number in range(1, reached):
		cleared_worlds[world_number] = true


static func _save_records(config: ConfigFile) -> void:
	for level_id in range(FIRST_LEVEL, LAST_LEVEL + 1):
		var section := _section(level_id)
		if best_times.has(level_id):
			config.set_value(section, "best_time", float(best_times[level_id]))
		if medals.has(level_id):
			config.set_value(section, "medal", String(medals[level_id]))
		if level_deaths.has(level_id):
			config.set_value(section, "deaths", int(level_deaths[level_id]))
		if completed_levels.has(level_id):
			config.set_value(section, "completed", bool(completed_levels[level_id]))


static func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
