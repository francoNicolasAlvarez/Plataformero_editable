extends SceneTree
## Comprueba los niveles 22-25 del mundo 5 (2026-11-23): CAMPANARIO (torre con
## corrientes), PUENTES (bifurcación con plataformas temporizadas y cintas),
## NUBES (baja gravedad y trampolín) y CIUDADELA (hub con palancas y
## compuerta). Mezcla comprobaciones de estructura con simulaciones de la
## física real del jugador. Ejecutar con:
## godot --headless --path . --script res://tests/world5_levels_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_level_22()
	await _test_level_23()
	await _test_level_24()
	await _test_level_25()
	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _load(number: int) -> Node:
	var scene := load(LevelRegistry.scene_path_for(number)) as PackedScene
	var level := scene.instantiate()
	root.add_child(level)
	await _wait_physics(20)
	return level


func _unload(level: Node) -> void:
	for action in ["move_left", "move_right", "jump", "move_down"]:
		Input.action_release(action)
	level.queue_free()
	await _wait_physics(3)


# --- Nivel 22: CAMPANARIO -------------------------------------------------

func _test_level_22() -> void:
	var level := await _load(22)
	var player: Player = level.get_node("Player")
	_check(level.next_level_path == "res://scenes/levels/level_twentythree.tscn", "22: lleva al nivel 23")
	_check(LevelRegistry.get_level(22).display_name == "CAMPANARIO", "22: está registrado como CAMPANARIO")
	_check(level.find_children("BellDraft*", "Area2D", true, false).size() == 4, "22: cuatro corrientes ascendentes")
	_check(get_nodes_in_group("crushers").size() == 11, "22: once prensas")
	_check(get_nodes_in_group("saws").size() == LevelTwentytwoLayout.SAWS.size(), "22: sierras de suelo (%d)" % LevelTwentytwoLayout.SAWS.size())
	var ceilings := level.find_children("BellCeiling*Spikes", "Area2D", true, false)
	var ceilings_down := true
	for spikes in ceilings:
		ceilings_down = ceilings_down and absf(absf((spikes as Node2D).rotation) - PI) < 0.01 and (spikes as Node).is_in_group("spikes")
	_check(ceilings.size() == LevelTwentytwoLayout.SPIKE_CEILINGS.size() and ceilings_down, "22: techos con espinas hacia abajo (%d)" % ceilings.size())
	_check(get_nodes_in_group("enemies").size() >= 12, "22: muchos enemigos (%d)" % get_nodes_in_group("enemies").size())
	_check(level.find_children("BellMage*", "Node2D", true, false).size() >= 5, "22: varios magos (%d)" % level.find_children("BellMage*", "Node2D", true, false).size())
	_check(LevelTwentytwoLayout.WIDTH >= 2000.0 and LevelTwentytwoLayout.FLOOR_PITCH < 500.0, "22: pisos más anchos y techo más bajo")
	_check(level.find_children("BellCeiling*Beam", "Node", true, false).is_empty() and level.find_children("BellCeiling*Chain*", "Node", true, false).is_empty(), "22: los techos con espinas no tienen vigas ni cadenas")
	var ceiling_touches := true
	for spikes in ceilings:
		var spike_y := (spikes as Node2D).global_position.y
		var slab_under := false
		for k in range(1, LevelTwentytwoLayout.FLOOR_COUNT):
			slab_under = slab_under or absf(spike_y - (LevelTwentytwoLayout.floor_top(k) + LevelTwentytwoLayout.SLAB_THICKNESS + LevelTwentytwoLayout.SPIKE_HEIGHT * 0.5)) < 40.0
		ceiling_touches = ceiling_touches and slab_under
	_check(ceiling_touches, "22: las espinas están pegadas a la losa de arriba")
	var near_hole := false
	for block in level.find_children("BellBalcony*", "Node2D", true, false):
		var bx := (block as Node2D).global_position.x
		for k in range(1, LevelTwentytwoLayout.FLOOR_COUNT):
			near_hole = near_hole or absf(bx - LevelTwentytwoLayout.shaft_center_x(k)) < 450.0
	_check(not near_hole, "22: ninguna plataforma cerca de las aberturas del techo")
	# Cada corriente llega hasta la cara inferior de la losa del piso siguiente.
	var drafts_ok := true
	for k in range(1, LevelTwentytwoLayout.FLOOR_COUNT):
		var zone := level.find_child("BellDraft%d" % k, true, false) as UpdraftZone
		var zone_top := zone.global_position.y - zone.zone_size.y * 0.5
		drafts_ok = drafts_ok and absf(zone_top - LevelTwentytwoLayout.draft_top(k)) < 1.0
		if k < LevelTwentytwoLayout.FLOOR_COUNT - 1:
			var slab := level.find_child("BellFloor%d_0" % (k + 1), true, false) as Platform
			var underside := slab.global_position.y + slab.platform_size.y * 0.5
			drafts_ok = drafts_ok and absf(zone_top - underside) < 1.0
	_check(drafts_ok, "22: cada corriente llega hasta el techo del piso siguiente")
	_check(get_nodes_in_group("checkpoints").size() == 1, "22: un control")
	_check(get_nodes_in_group("healing_herbs").size() >= 2 or level.find_children("*Herb*", "Area2D", true, false).size() + level.find_children("HealingHerb*", "Area2D", true, false).size() >= 2, "22: hay hierbas (balcones y pasillo)")
	var camera := level.get_node("Camera") as HorizontalCamera
	_check(camera.follow_y and camera.limit_bottom >= 2300, "22: la cámara sigue en vertical")
	var route := LevelTwentytwoLayout.route()
	_check(route[0].distance_to(player.global_position) < 80.0, "22: el jugador empieza al inicio de la ruta")
	var portal := level.get_node("ExitPortal") as Node2D
	_check(portal.global_position.y < 700.0 and portal.global_position.x > 1800.0, "22: el portal está arriba a la derecha")
	_check(level.route_progress(route[route.size() - 1]) > 0.99, "22: la ruta llega al portal (progreso 100 %)")

	# Simulación: del piso 0 al piso 1 por la corriente (sin enemigos ni trampas).
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	for trap in get_nodes_in_group("traps"):
		trap.queue_free()
	for crusher in get_nodes_in_group("crushers"):
		crusher.queue_free()
	for spikes in get_nodes_in_group("spikes"):
		spikes.queue_free()
	await _wait_physics(2)
	var shaft_x := LevelTwentytwoLayout.shaft_center_x(1)
	var floor1 := LevelTwentytwoLayout.floor_top(1)
	var ceiling1 := LevelTwentytwoLayout.draft_top(1)
	player.global_position = Vector2(shaft_x, LevelTwentytwoLayout.floor_top(0) - 30.0)
	player.velocity = Vector2.ZERO
	var landed := false
	var highest := 99999.0
	var left_zone := false
	for _frame in 400:
		if player.global_position.y < ceiling1 + 90.0 and absf(player.global_position.x - shaft_x) < 175.0 and not left_zone:
			Input.action_press("move_left")
		else:
			if absf(player.global_position.x - shaft_x) >= 175.0:
				left_zone = true
			Input.action_release("move_left")
		await physics_frame
		highest = minf(highest, player.global_position.y)
		if left_zone and player.is_on_floor() and absf(player.global_position.y - (floor1 - 24.0)) < 12.0:
			landed = true
			break
	Input.action_release("move_left")
	_check(highest >= ceiling1 - 2.0, "22: la corriente no atraviesa la losa de arriba (punto más alto y=%.0f, techo y=%.0f)" % [highest, ceiling1])
	_check(highest < ceiling1 + 60.0, "22: la corriente sube hasta el techo del piso (y=%.0f)" % highest)
	_check(landed, "22: se sale de la corriente hacia el pasillo y se aterriza en el piso 1 (y=%.0f)" % player.global_position.y)
	await _unload(level)


# --- Nivel 23: PUENTES ----------------------------------------------------

func _test_level_23() -> void:
	var level := await _load(23)
	var player: Player = level.get_node("Player")
	_check(level.next_level_path == "res://scenes/levels/level_twentyfour.tscn", "23: lleva al nivel 24")
	var timed := level.find_children("BridgeTimed*", "Node2D", true, false)
	_check(timed.size() == LevelTwentythreeLayout.UPPER_COUNT, "23: escalera de %d plataformas temporizadas" % LevelTwentythreeLayout.UPPER_COUNT)
	var belts := level.find_children("BridgeBelt*", "Platform", true, false) + level.find_children("BridgeFinalBelt*", "Platform", true, false)
	_check(belts.size() == LevelTwentythreeLayout.belt_count() + LevelTwentythreeLayout.FINAL_BELTS, "23: cintas de la ruta baja y del tramo final (%d)" % belts.size())
	var directions_ok := true
	for i in LevelTwentythreeLayout.belt_count():
		var belt := level.get_node("LevelTwentythreeGenerated/BridgeBelt%d" % i) as Platform
		directions_ok = directions_ok and signf(belt.conveyor_speed) == signf(LevelTwentythreeLayout.belt_speed(i))
	_check(directions_ok, "23: las cintas de la ruta baja alternan el sentido")
	# La escalera alta se puede saltar: huecos y desniveles dentro del alcance.
	var step_ok := true
	var width := LevelTwentythreeLayout.UPPER_WIDTH
	for i in range(1, LevelTwentythreeLayout.UPPER_COUNT):
		var a := LevelTwentythreeLayout.upper_center(i - 1)
		var b := LevelTwentythreeLayout.upper_center(i)
		var gap := absf(b.x - a.x) - width
		step_ok = step_ok and gap <= 250.0 and absf(b.y - a.y) <= player.stats.jump_height * 0.8
	_check(step_ok, "23: huecos ≤ 250 px y desniveles saltables en la escalera alta")
	var first := LevelTwentythreeLayout.upper_center(0)
	_check(LevelTwentythreeLayout.GROUND_Y - (first.y - 12.0) <= player.stats.jump_height - 10.0, "23: se sube a la primera plataforma desde el suelo")
	# Tramos finales: huecos entre cintas saltables.
	var final_ok := true
	for i in range(1, LevelTwentythreeLayout.FINAL_BELTS):
		var gap := LevelTwentythreeLayout.final_belt_center(i).x - LevelTwentythreeLayout.final_belt_center(i - 1).x - LevelTwentythreeLayout.FINAL_BELT_LENGTH
		final_ok = final_ok and gap <= 250.0
	var last_end := LevelTwentythreeLayout.final_belt_center(LevelTwentythreeLayout.FINAL_BELTS - 1).x + LevelTwentythreeLayout.FINAL_BELT_LENGTH * 0.5
	final_ok = final_ok and LevelTwentythreeLayout.FINAL_GROUND_START - last_end <= 250.0
	_check(final_ok, "23: huecos del tramo final ≤ 250 px")
	# Las plataformas temporizadas cruzan un largo pozo: sin cintas ni suelo debajo.
	var over_pit := true
	for node in timed:
		over_pit = over_pit and (node as Node2D).position.x > LevelTwentythreeLayout.PIT_START and (node as Node2D).position.x < LevelTwentythreeLayout.PIT_END
	var under_ok := true
	for belt in belts:
		under_ok = under_ok and ((belt as Node2D).position.x < LevelTwentythreeLayout.PIT_START or (belt as Node2D).position.x > LevelTwentythreeLayout.PIT_END)
	for ground in level.find_children("Ground*", "Platform", true, false):
		var gp := ground as Platform
		under_ok = under_ok and (gp.position.x + gp.platform_size.x * 0.5 <= LevelTwentythreeLayout.PIT_START + 1.0 or gp.position.x - gp.platform_size.x * 0.5 >= LevelTwentythreeLayout.PIT_END - 1.0)
	_check(over_pit and under_ok, "23: la escalera temporizada cruza un pozo de %d px sin suelo ni cintas debajo" % int(LevelTwentythreeLayout.PIT_LENGTH))
	_check(level.find_child("FallZoneBridges", true, false) != null, "23: el pozo es mortal")
	_check(get_nodes_in_group("checkpoints").size() == 1, "23: un control en la isla de unión")
	var route := LevelTwentythreeLayout.route()
	_check(level.route_progress(route[route.size() - 1]) > 0.99, "23: la ruta (escalera) llega al portal")
	# Física: parado sobre una cinta, el jugador avanza.
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await _wait_physics(2)
	var belt_center := LevelTwentythreeLayout.belt_center(0)
	player.global_position = belt_center + Vector2(-150.0, -60.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(30)
	var x0 := player.global_position.x
	await _wait_physics(30)
	_check(player.global_position.x - x0 > 30.0, "23: la cinta 0 arrastra al jugador hacia delante")
	await _unload(level)


# --- Nivel 24: NUBES ------------------------------------------------------

func _test_level_24() -> void:
	var level := await _load(24)
	var player: Player = level.get_node("Player")
	var shared := load("res://resources/player/player_stats.tres") as PlayerStats
	_check(level.next_level_path == "res://scenes/levels/level_twentyfive.tscn", "24: lleva al nivel 25")
	_check(player.stats.gravity < shared.gravity * 0.6 and player.stats.jump_height > shared.jump_height * 1.2, "24: baja gravedad y salto más alto")
	_check(is_equal_approx(shared.gravity, 1450.0), "24: el recurso compartido no cambia")
	# Alcance real del salto con la gravedad del nivel (a velocidad de carrera).
	var g := player.stats.gravity
	var v := sqrt(2.0 * g * player.stats.jump_height)
	var air_time := v / g + sqrt(2.0 * player.stats.jump_height / (g * player.stats.fall_gravity_multiplier))
	var reach := air_time * player.stats.run_speed
	var gaps_ok := true
	var biggest := 0.0
	for i in range(1, LevelTwentyfourLayout.LOW_ISLANDS.size()):
		var a: Array = LevelTwentyfourLayout.LOW_ISLANDS[i - 1]
		var b: Array = LevelTwentyfourLayout.LOW_ISLANDS[i]
		var gap: float = float(b[0]) - float(a[0]) - (float(a[2]) + float(b[2])) * 0.5
		biggest = maxf(biggest, gap)
		gaps_ok = gaps_ok and gap <= reach * 0.8 and absf(float(b[1]) - float(a[1])) <= player.stats.jump_height * 0.7
	_check(gaps_ok, "24: huecos entre islas ≤ 80 %% del alcance (%.0f px de alcance, mayor hueco %.0f)" % [reach, biggest])
	var high_ok := true
	for i in range(1, LevelTwentyfourLayout.HIGH_CLOUDS.size()):
		var a: Array = LevelTwentyfourLayout.HIGH_CLOUDS[i - 1]
		var b: Array = LevelTwentyfourLayout.HIGH_CLOUDS[i]
		var gap: float = float(b[0]) - float(a[0]) - (float(a[2]) + float(b[2])) * 0.5
		high_ok = high_ok and gap <= reach * 0.8 and absf(float(b[1]) - float(a[1])) <= player.stats.jump_height * 0.7
	_check(high_ok, "24: la ruta alta también se puede saltar")
	_check(biggest >= 380.0, "24: los huecos son anchos (regla de baja gravedad), mayor %.0f" % biggest)
	_check(level.find_children("CloudWheel*", "Area2D", true, false).size() == 2, "24: dos ruedas de cuchillas")
	_check(level.find_children("CloudMine*", "Node2D", true, false).size() == 3, "24: tres minas")
	# Densidad: cada plataforma lleva al menos un obstáculo o enemigo.
	var bare: Array = []
	var platforms: Array = []
	for i in LevelTwentyfourLayout.LOW_ISLANDS.size():
		var island: Array = LevelTwentyfourLayout.LOW_ISLANDS[i]
		platforms.append(["isla baja %d" % i, float(island[0]), float(island[2]), LevelTwentyfourLayout.island_top(i)])
	for i in LevelTwentyfourLayout.HIGH_CLOUDS.size():
		var cloud: Array = LevelTwentyfourLayout.HIGH_CLOUDS[i]
		platforms.append(["nube alta %d" % i, float(cloud[0]), float(cloud[2]), float(cloud[1]) - LevelTwentyfourLayout.CLOUD_THICKNESS * 0.5])
	var hazard_nodes: Array = []
	for group in ["enemies", "traps"]:
		for node in get_nodes_in_group(group):
			if node is Node2D and not (node is LaunchPad) and not hazard_nodes.has(node):
				hazard_nodes.append(node)
	for entry in platforms:
		var found := false
		for node in hazard_nodes:
			var offset: Vector2 = (node as Node2D).global_position - Vector2(float(entry[1]), float(entry[3]))
			if absf(offset.x) <= float(entry[2]) * 0.5 + 10.0 and offset.y <= 20.0 and offset.y >= -260.0:
				found = true
				break
		if not found:
			bare.append(entry[0])
	_check(bare.is_empty(), "24: todas las plataformas tienen obstáculo o enemigo (sin: %s)" % str(bare))
	# Nivel superior de magos: uno por nube alta.
	var mages_ok := true
	for i in LevelTwentyfourLayout.HIGH_CLOUDS.size():
		var mage := level.find_child("CloudHighMage%d" % i, true, false)
		var cloud: Array = LevelTwentyfourLayout.HIGH_CLOUDS[i]
		mages_ok = mages_ok and mage is RangedEnemy and absf((mage as Node2D).global_position.x - float(cloud[0])) <= float(cloud[2]) * 0.5
	_check(mages_ok, "24: un mago en cada nube del nivel superior")
	var sentry := level.find_child("VacuumSentry", true, false) as VacuumSentry
	_check(sentry != null, "24: hay un centinela aspirador")
	if sentry != null:
		var cam := level.get_node("Camera") as Camera2D
		var screen := cam.get_screen_center_position()
		_check(sentry.global_position.x < screen.x - 300.0 and sentry.global_position.y > screen.y + 150.0, "24: el centinela está abajo a la izquierda de la pantalla")
	_check(get_nodes_in_group("checkpoints").size() == 1, "24: un control a mitad")
	var route := LevelTwentyfourLayout.route()
	_check(level.route_progress(route[route.size() - 1]) > 0.99, "24: la ruta baja llega al portal")

	# Simulación: el trampolín de la isla 1 lleva a la ruta alta.
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	for trap in get_nodes_in_group("blade_wheels"):
		trap.queue_free()
	for spawner in level.find_children("FlyingSpawner", "Node", true, false):
		spawner.queue_free()
	await _wait_physics(2)
	var island: Array = LevelTwentyfourLayout.LOW_ISLANDS[1]
	var pad_x := float(island[0]) - 110.0
	player.global_position = Vector2(pad_x - 30.0, LevelTwentyfourLayout.island_top(1) - 30.0)
	player.velocity = Vector2.ZERO
	await _wait_physics(20)
	Input.action_press("move_right")
	var on_high := false
	for _frame in 400:
		await physics_frame
		if player.is_on_floor() and player.global_position.y < 300.0:
			on_high = true
			break
	Input.action_release("move_right")
	_check(on_high, "24: el trampolín lleva a una nube de la ruta alta (x=%.0f y=%.0f)" % [player.global_position.x, player.global_position.y])
	await _unload(level)


# --- Nivel 25: CIUDADELA --------------------------------------------------

func _test_level_25() -> void:
	var level := await _load(25)
	var player: Player = level.get_node("Player")
	_check(level.next_level_path == "res://scenes/ui/game_complete.tscn", "25: termina en la pantalla final")
	var gate := level.find_child("CitadelGate", true, false) as SwitchGate
	_check(gate != null and not gate.is_open and gate.levers().size() == 3, "25: compuerta cerrada con tres palancas")
	_check(gate != null and gate.gate_size.y >= 600.0, "25: la compuerta es un muro altísimo, imposible de saltar (%.0f px)" % gate.gate_size.y)
	var levers := level.find_children("CitadelLever*", "Area2D", true, false)
	_check(levers.size() == 3, "25: tres palancas (A, B y C)")
	var xs: Array = []
	for lever in levers:
		xs.append((lever as Node2D).global_position.x)
	xs.sort()
	_check(xs[0] < 1000.0 and xs[1] > 2000.0 and xs[1] < 3500.0 and xs[2] > 5000.0, "25: palancas a la izquierda, en el centro (cámara) y a la derecha")
	_check(get_nodes_in_group("checkpoints").size() == 1, "25: un control en la plaza")
	var route := LevelTwentyfiveLayout.route()
	_check(level.route_progress(route[route.size() - 1]) > 0.99, "25: la ruta termina en el portal")
	_check(level._route_length > 9000.0, "25: la ruta recorre los dos radios (%.0f px)" % level._route_length)
	# Radios: huecos saltables (cintas y temporizadas).
	var left_gap := LevelTwentyfiveLayout.LEFT_GROUND_FROM - 1150.0
	_check(left_gap > 600.0 and left_gap < 900.0 and level.find_children("CitadelTimedL*", "Node2D", true, false).size() == 3, "25: radio izquierdo con tres temporizadas sobre el abismo")
	_check(level.find_children("CitadelBeltR*", "Platform", true, false).size() == 2, "25: radio derecho con dos cintas")
	_check(level.find_children("CitadelCrusher*", "Node2D", true, false).size() == 2 and level.find_children("CitadelWheel*", "Area2D", true, false).size() == 2, "25: prensas y ruedas en los radios")

	# Simulación: la corriente de la plaza sube a la cámara elevada.
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	for trap in get_nodes_in_group("crushers"):
		trap.queue_free()
	await _wait_physics(2)
	player.global_position = Vector2(LevelTwentyfiveLayout.HUB_CENTER, LevelTwentyfiveLayout.GROUND_Y - 30.0)
	player.velocity = Vector2.ZERO
	var reached := false
	for _frame in 200:
		# Arriba: se sale de la corriente hacia la izquierda y se suelta el
		# mando sobre la losa para caer en ella (sin pasarse del borde).
		if player.global_position.y < LevelTwentyfiveLayout.CHAMBER_Y - 40.0 and player.global_position.x > LevelTwentyfiveLayout.HUB_CENTER - 130.0:
			Input.action_press("move_left")
		else:
			Input.action_release("move_left")
		await physics_frame
		if player.is_on_floor() and player.global_position.y < LevelTwentyfiveLayout.CHAMBER_Y:
			reached = true
			break
	_check(reached, "25: la corriente sube a la cámara elevada (y=%.0f)" % player.global_position.y)
	Input.action_press("move_left")
	await _wait_physics(90)
	Input.action_release("move_left")
	var lever_c := level.find_child("CitadelLeverC", true, false) as LeverSwitch
	_check(lever_c.is_on, "25: en la cámara se activa la palanca C")
	_check(not gate.is_open, "25: con 1 de 3 palancas la compuerta sigue cerrada")
	(level.find_child("CitadelLeverA", true, false) as LeverSwitch).activate()
	(level.find_child("CitadelLeverB", true, false) as LeverSwitch).activate()
	await _wait_physics(3)
	_check(gate.is_open, "25: con las tres palancas la compuerta se abre")
	await _unload(level)


func _wait_physics(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
