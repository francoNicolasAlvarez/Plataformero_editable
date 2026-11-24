extends SceneTree
## Comprueba el registro de 40 niveles y 8 mundos de la fase 3 (2026-11-17).
## Ejecutar con:
## godot --headless --path . --script res://tests/level_registry_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(LevelRegistry.WORLD_COUNT == 8, "Hay 8 mundos")
	_check(LevelRegistry.LEVELS_PER_WORLD == 5, "Cada mundo tiene 5 niveles")
	_check(LevelRegistry.LEVEL_COUNT == 40, "El registro tiene 40 niveles")
	_check(LevelRegistry.all_worlds().size() == 8, "Se devuelven los 8 mundos")
	_check(LevelRegistry.all_levels().size() == 40, "Se devuelven los 40 niveles")

	var world_one: WorldConfig = LevelRegistry.get_world(1)
	var world_eight: WorldConfig = LevelRegistry.get_world(8)
	_check(world_one != null and world_one.display_name == "PRADERAS Y COLINAS", "Mundo 1 con nombre")
	_check(world_eight != null and world_eight.display_name.contains("VOLCÁN"), "Mundo 8 con nombre")
	_check(LevelRegistry.get_world(0) == null, "Mundo inválido devuelve null")
	_check(LevelRegistry.get_level(0) == null, "Nivel inválido devuelve null")
	_check(LevelRegistry.get_level(41) == null, "Nivel fuera de rango devuelve null")

	var first: LevelConfig = LevelRegistry.get_level(1)
	var eighth: LevelConfig = LevelRegistry.get_level(8)
	var ninth: LevelConfig = LevelRegistry.get_level(9)
	var tenth: LevelConfig = LevelRegistry.get_level(10)
	var eleventh: LevelConfig = LevelRegistry.get_level(26)
	_check(first != null and first.number == 1 and first.world_number == 1, "Nivel 1 en el mundo 1")
	_check(first != null and first.index_in_world == 1, "Nivel 1 es el primero del mundo")
	_check(first != null and first.display_name == "DÍA", "Nivel 1 conserva su nombre")
	_check(first != null and ResourceLoader.exists(first.scene_path), "Nivel 1 apunta a una escena real")
	_check(eighth != null and eighth.world_number == 2 and eighth.index_in_world == 3, "Nivel 8 está en el mundo 2")
	_check(ninth != null and ninth.world_number == 2 and ninth.index_in_world == 4, "Nivel 9 pertenece al mundo 2")
	_check(ninth != null and ninth.is_implemented() and ninth.display_name == "RUINAS", "Nivel 9 RUINAS está creado")
	_check(tenth != null and tenth.is_implemented() and tenth.display_name == "TEMPLO", "Nivel 10 TEMPLO está creado")
	_check(tenth != null and tenth.world_number == 2 and tenth.index_in_world == 5, "Nivel 10 cierra el mundo 2")
	_check(ninth != null and ResourceLoader.exists(ninth.scene_path), "Nivel 9 apunta a una escena real")
	_check(eleventh != null and not eleventh.is_implemented(), "Nivel 26 todavía no está creado")
	_check(eleventh != null and eleventh.scene_path.is_empty(), "Nivel 26 sin ruta cargable")
	_check(eleventh != null and eleventh.display_name == "POR CONSTRUIR", "Nivel 26 marcado como pendiente")

	_check(LevelRegistry.implemented_levels().size() == 25, "Solo 25 niveles están implementados")
	_check(LevelRegistry.is_implemented(1) and not LevelRegistry.is_implemented(26), "Estado de implementación")
	_check(
		LevelRegistry.scene_path_for(2) == "res://scenes/levels/level_two.tscn",
		"La ruta del nivel 2 es la correcta"
	)
	_check(LevelRegistry.scene_path_for(26).is_empty(), "La ruta de un nivel pendiente está vacía")

	for level_number in range(1, 41):
		var config: LevelConfig = LevelRegistry.get_level(level_number)
		_check(
			is_equal_approx(config.time_limit, 70.0)
			and is_equal_approx(config.gold_time, 35.0)
			and is_equal_approx(config.silver_time, 50.0)
			and is_equal_approx(config.bronze_time, 70.0),
			"Nivel %d con umbrales por defecto" % level_number
		)

	_check(LevelRegistry.get_world_for_level(9) == LevelRegistry.get_world(2), "Mundo calculado desde el nivel")
	_check(LevelRegistry.levels_in_world(2).size() == 5, "Mundo 2 tiene 5 niveles")
	_check(LevelRegistry.levels_in_world(9).is_empty(), "Mundo inválido sin niveles")
	_check(LevelRegistry.next_implemented_level(1) == 2, "Siguiente implementado desde el nivel 1")
	_check(LevelRegistry.next_implemented_level(8) == 9 and LevelRegistry.next_implemented_level(10) == 11 and LevelRegistry.next_implemented_level(15) == 16 and LevelRegistry.next_implemented_level(19) == 20 and LevelRegistry.next_implemented_level(20) == 21 and LevelRegistry.next_implemented_level(24) == 25 and LevelRegistry.next_implemented_level(25) == -1, "El nivel 25 es el último implementado")
	_check(LevelRegistry.label_for(1) == "1-1 · DÍA", "Etiqueta legible del nivel 1")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
