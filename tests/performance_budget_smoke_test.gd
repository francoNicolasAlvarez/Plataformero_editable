extends SceneTree
## Presupuesto de rendimiento (2026-11-27). Carga cada nivel implementado, deja
## que se asiente y mide durante `SAMPLE_FRAMES` fotogramas el coste medio de
## física + proceso. En headless los monitores de `Performance` no dan el
## coste por fotograma, así que se sube la física a 1000 Hz con un solo paso
## por iteración. Aun así el servidor headless duerme ~6,9 ms por iteración,
## así que primero se mide ese SUELO con una escena vacía y se evalúa el
## EXCESO de cada nivel sobre él. Falla si algún nivel supera `BUDGET_MS` de
## exceso (la mitad de un fotograma a 60 FPS, para dejar margen al
## renderizado, que en headless no se mide). Imprime una tabla con el coste y
## el número de nodos de cada nivel para detectar regresiones.
## Ejecutar con:
## godot --headless --path . --script res://tests/performance_budget_smoke_test.gd

const SETTLE_FRAMES := 40
const SAMPLE_FRAMES := 90
const BUDGET_MS := 8.0

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.physics_ticks_per_second = 1000
	Engine.max_physics_steps_per_frame = 1
	# Sin la pausa del modo de bajo consumo (6,9 ms por defecto) ni límite de FPS.
	OS.low_processor_usage_mode = false
	Engine.max_fps = 0
	var rows: Array[String] = []
	var worst := 0.0
	var worst_level := 0
	var empty := Node2D.new()
	root.add_child(empty)
	var floor_ms: float = (await _measure())[0]
	empty.queue_free()
	rows.append("  suelo de medida (escena vacía): %.2f ms" % floor_ms)
	for config in LevelRegistry.implemented_levels():
		var path := LevelRegistry.scene_path_for(config.number)
		if path.is_empty():
			continue
		var level: Node = (load(path) as PackedScene).instantiate()
		root.add_child(level)
		for _frame in SETTLE_FRAMES:
			await physics_frame
		var sample: Array = await _measure()
		var average: float = maxf(0.0, float(sample[0]) - floor_ms)
		var peak: float = sample[1]
		var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		rows.append("  nivel %2d  exceso %5.2f ms  pico %5.2f ms  nodos %5d" % [config.number, average, peak, nodes])
		_check(average < BUDGET_MS, "Nivel %d: exceso medio %.2f ms < %.1f ms" % [config.number, average, BUDGET_MS])
		if average > worst:
			worst = average
			worst_level = config.number
		level.set_process(false)
		level.queue_free()
		for _frame in 3:
			await process_frame

	print("")
	for row in rows:
		print(row)
	print("  Nivel más pesado: %d (%.2f ms)" % [worst_level, worst])
	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _measure() -> Array:
	## [media, pico] en ms del tiempo de reloj entre fotogramas de física.
	var peak := 0.0
	var started := Time.get_ticks_usec()
	var last := started
	for _frame in SAMPLE_FRAMES:
		await physics_frame
		var now := Time.get_ticks_usec()
		peak = maxf(peak, float(now - last) / 1000.0)
		last = now
	return [float(last - started) / 1000.0 / float(SAMPLE_FRAMES), peak]


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
