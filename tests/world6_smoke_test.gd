extends SceneTree
## Mundo 6 "FORTALEZA MEDIEVAL" (2026-11-24): niveles 26-30 y sus mecánicas:
## botón de suelo, puente levadizo, candado de enemigo, objetos sujetables
## (caja, roca, resorte), zona de gravedad, cañón de pared, catapulta, llaves y
## condiciones de victoria alternativas. Ejecutar con:
## godot --headless --path . --script res://tests/world6_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_pendings()
	await _test_registry()
	await _test_level_26()
	await _test_items_and_gravity()
	await _test_level_27()
	await _test_level_28()
	await _test_level_29()
	await _test_level_30()
	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _load(number: int) -> Node:
	var level := (load(LevelRegistry.scene_path_for(number)) as PackedScene).instantiate()
	root.add_child(level)
	(level.get_node("Player") as Player).health.died.connect(_on_player_died.bind(number))
	await _wait_physics(20)
	return level


func _on_player_died(number: int) -> void:
	print("[AVISO] el jugador murió en el nivel %d" % number)


func _unload(level: Node) -> void:
	for action in ["move_left", "move_right", "jump", "move_down", "dash"]:
		Input.action_release(action)
	level.queue_free()
	await _wait_physics(3)


func _player(level: Node) -> Player:
	return level.get_node("Player") as Player


func _place_player(level: Node, position: Vector2) -> void:
	var player := _player(level)
	player.global_position = position
	player.velocity = Vector2.ZERO
	await _wait_physics(3)


func _test_pendings() -> void:
	for sound in ["button", "grab", "throw", "cannon", "unlock", "gravity"]:
		_check(Sfx._get_sound(sound) != null and Sfx._get_sound(sound) != Sfx._get_sound("nope"), "sonido propio: %s" % sound)
	var scene_text := FileAccess.get_file_as_string("res://scenes/ui/main_menu.tscn")
	_check(scene_text.contains("FortressText") and scene_text.contains("botón de suelo") and scene_text.contains("Resorte") and scene_text.contains("llaves"), "instrucciones: explican botones, objetos y llaves")


func _test_registry() -> void:
	var names := ["FOSO", "MURALLAS", "MAZMORRA", "CATAPULTAS", "SALA DEL TRONO"]
	for i in names.size():
		_check(LevelRegistry.get_level(26 + i).display_name == names[i], "%d: registrado como %s" % [26 + i, names[i]])
	var chain := [25, 26, 27, 28, 29]
	for number in chain:
		var level := await _load(number)
		_check(level.next_level_path == LevelRegistry.scene_path_for(number + 1), "%d encadena con %d" % [number, number + 1])
		await _unload(level)
	var last := await _load(30)
	_check(last.next_level_path == "res://scenes/ui/game_complete.tscn", "30 termina en la pantalla final")
	await _unload(last)


# --- Nivel 26 -------------------------------------------------------------

func _test_level_26() -> void:
	var level := await _load(26)
	var player := _player(level)
	var bridge_a := level.find_child("DrawbridgeA", true, false) as Drawbridge
	var button_a := level.find_child("MoatButtonA", true, false) as FloorButton
	var guard := level.find_child("MoatGuardA", true, false) as TrainingDummy
	_check(bridge_a != null and not bridge_a.is_down, "26: el puente A empieza levantado")
	_check(absf(absf(bridge_a.rotation) - PI * 0.5) < 0.01, "26: levantado = vertical (muro)")
	_check(guard != null and bool(guard.get_meta("channel_locked", false)), "26: el arquero está protegido por un candado")
	# Caminar sobre el botón NO lo activa; saltar encima sí.
	await _place_player(level, Vector2(button_a.global_position.x - 120.0, 616.0))
	Input.action_press("move_right")
	await _wait_physics(40)
	Input.action_release("move_right")
	_check(not button_a.is_on, "26: pisar el botón andando no lo activa (hay que saltar)")
	await _place_player(level, button_a.global_position + Vector2(0.0, -200.0))
	await _wait_physics(40)
	_check(button_a.is_on, "26: caer sobre el botón lo activa")
	await _wait_physics(10)
	_check(bridge_a.is_down, "26: el puente A baja al activar el botón")
	_check(not is_instance_valid(guard) or guard.health.is_dead, "26: el arquero con escudo cae al pulsar el botón")
	# El puente vuelve a subir y reinicia el botón.
	bridge_a.raise_after = 0.3
	bridge_a._time_left = 0.3
	await _wait_physics(40)
	_check(not bridge_a.is_down and not button_a.is_on, "26: tras unos segundos el puente sube y el botón se reinicia")
	# Alcance: con doble salto no se llega a la cima del muro, con la caja sí.
	var wall_top := LevelTwentysixLayout.WALL_TOP
	var open_x := 2300.0
	var ground_center_y := LevelTwentysixLayout.G - 24.0
	var reach_plain := await _max_rise(level, Vector2(open_x, ground_center_y))
	_check(ground_center_y - reach_plain < ground_center_y - (wall_top - 24.0) - 5.0, "26: sin ayuda no se llega al muro (sube %.0f px, hacen falta %.0f)" % [reach_plain, ground_center_y - (wall_top - 24.0)])
	var reach_crate := await _max_rise(level, Vector2(open_x, ground_center_y - 38.0))
	_check(reach_crate + 38.0 >= ground_center_y - (wall_top - 24.0) + 5.0, "26: con la caja se llega al muro (%.0f px)" % (reach_crate + 38.0))
	await _unload(level)


## Máxima altura (px) que sube el centro del jugador con salto + doble salto.
func _max_rise(level: Node, start: Vector2) -> float:
	var player := _player(level)
	player.global_position = start
	player.velocity = Vector2.ZERO
	await _wait_physics(30)
	var base_y := player.global_position.y
	var min_y := base_y
	Input.action_press("jump")
	for frame in 100:
		await _wait_physics(1)
		min_y = minf(min_y, player.global_position.y)
		if frame == 20:
			Input.action_release("jump")
		if frame == 22:
			Input.action_press("jump")
		if frame == 50:
			Input.action_release("jump")
	return base_y - min_y


# --- Objetos, gravedad, cañón y catapulta ---------------------------------

func _test_items_and_gravity() -> void:
	var level := await _load(26)
	var player := _player(level)
	var crate := level.find_child("MoatCrate", true, false) as GrabItem
	var before := crate.global_position
	await _place_player(level, crate.global_position + Vector2(0.0, -10.0))
	await _wait_physics(5)
	_check(player.held_item == crate, "objetos: la caja se agarra al tocarla")
	await _wait_physics(2)
	_check(crate.global_position.y < player.global_position.y - 30.0, "objetos: la caja se lleva sobre la cabeza")
	crate.place()
	await _wait_physics(40)
	_check(player.held_item == null and crate.placed and crate.collision_layer == 1, "objetos: ABAJO deja la caja como peldaño sólido")
	_check(absf(crate.global_position.y - (LevelTwentysixLayout.G - 19.0)) < 3.0, "objetos: la caja apoya sobre el suelo")
	await _wait_physics(40)
	_check(player.held_item == null, "objetos: una caja colocada no se vuelve a agarrar sola")
	crate.reset_to_start()
	await _wait_physics(3)
	_check(not crate.placed and crate.global_position.is_equal_approx(before), "objetos: reaparecer devuelve la caja a su sitio")
	# El botón es sólido, su parte pulsable va detrás del suelo y se hunde sin asomar.
	var button_c := level.find_child("MoatButtonC", true, false) as FloorButton
	var solid := button_c.get_node_or_null("Solid") as StaticBody2D
	var cap := button_c.get_node_or_null("Cap") as Polygon2D
	_check(solid != null and solid.collision_layer == 1, "botón: tiene colisión sólida")
	_check(cap != null and cap.z_index < 0, "botón: la parte pulsable se dibuja detrás del suelo")
	await _place_player(level, button_c.global_position + Vector2(0.0, -150.0))
	await _wait_physics(50)
	_check(player.is_on_floor() and player.global_position.y < button_c.global_position.y - 10.0, "botón: se puede estar de pie encima (y=%.0f)" % player.global_position.y)
	_check(button_c.is_on and cap.position.y > FloorButton.PRESS_DEPTH - 1.0, "botón: al pulsarlo la tapa se hunde %.0f px" % cap.position.y)
	# Los objetos no se agarran ni se sueltan a través de muros.
	var wall_crate := level.find_child("MoatCrate", true, false) as GrabItem
	wall_crate.global_position = Vector2(2960.0, 621.0)
	await _place_player(level, Vector2(2860.0, 616.0))
	_check(wall_crate._blocked_to(player), "objetos: un muro entre el jugador y el objeto impide agarrarlo")
	wall_crate.reset_to_start()
	wall_crate.global_position = Vector2(2300.0, 621.0)
	await _place_player(level, Vector2(2300.0, 616.0))
	_check(not wall_crate._blocked_to(player), "objetos: sin muro sí se puede agarrar")
	await _wait_physics(25)
	await _place_player(level, Vector2(2860.0, 616.0))
	player.held_item = wall_crate
	wall_crate.held_by = player
	wall_crate.place()
	_check(not wall_crate.placed and wall_crate.held_by == player, "objetos: no se deja la caja dentro de un muro")
	wall_crate.held_by = null
	player.held_item = null
	await _unload(level)

	# Resorte y roca sobre un nivel vacío de enemigos cercanos (nivel 28).
	level = await _load(28)
	player = _player(level)
	var spring := level.find_child("DungeonSpring", true, false) as GrabItem
	await _place_player(level, spring.global_position)
	await _wait_physics(5)
	_check(player.held_item == spring and is_equal_approx(player.jump_height_scale, GrabItem.SPRING_BOOST), "resorte: se agarra y sube el salto")
	spring.on_jump()
	spring.on_jump()
	_check(player.held_item == spring, "resorte: aguanta dos saltos")
	spring.on_jump()
	await _wait_physics(2)
	_check(player.held_item == null and is_equal_approx(player.jump_height_scale, 1.0), "resorte: se gasta al tercer salto y el salto vuelve a la normalidad")
	await _wait_physics(int(1.0 / 0.016))
	# Con el resorte la repisa alta de la celda es alcanzable.
	spring.reset_to_start()
	await _wait_physics(25)
	await _place_player(level, spring.global_position)
	await _wait_physics(5)
	var rise := await _max_rise(level, Vector2(2650.0, 616.0))
	_check(rise >= 616.0 - (LevelTwentyeightLayout.HIGH_LEDGE_TOP - 24.0) + 5.0, "resorte: con él se llega a la repisa alta (%.0f px)" % rise)
	# Roca: lanzada contra un enemigo libre lo derriba; contra uno con escudo, no.
	player.held_item = null
	spring.reset_to_start()
	var rock := level.find_child("DungeonRockC0", true, false) as GrabItem
	var target := level.find_child("DungeonArcher0", true, false) as TrainingDummy
	var locked := level.find_child("DungeonGuardL", true, false) as TrainingDummy
	await _place_player(level, rock.global_position)
	await _wait_physics(5)
	_check(player.held_item == rock, "roca: se agarra")
	_check(locked != null and bool(locked.get_meta("channel_locked", false)), "roca: el guardián de la celda tiene escudo")
	_check(rock.wants_dash() and rock.thrown, "roca: Ctrl la lanza")
	rock.global_position = target.global_position + Vector2(-70.0, -4.0)
	rock.velocity = Vector2(500.0, 0.0)
	await _wait_physics(60)
	_check(not is_instance_valid(target) or target.health.is_dead, "roca: derriba al arquero sin escudo")
	_check(not player.has_method("attack"), "roca: no se añadió ninguna acción de ataque propia")
	var rock2 := level.find_child("DungeonRockC1", true, false) as GrabItem
	rock2.reset_to_start()
	rock2.held_by = null
	rock2.thrown = true
	rock2.collision_mask = 1 | 4
	rock2.global_position = locked.global_position + Vector2(-120.0, -10.0)
	rock2.velocity = Vector2(500.0, 0.0)
	await _wait_physics(40)
	_check(is_instance_valid(locked) and not locked.health.is_dead, "roca: no daña a un enemigo con escudo")
	await _unload(level)

	# Zona de gravedad y cañón (nivel 27).
	level = await _load(27)
	player = _player(level)
	var zone := level.find_child("CorridorGravity", true, false) as GravityZone
	await _place_player(level, zone.global_position)
	await _wait_physics(10)
	_check(player.inverted_gravity, "gravedad: dentro de la zona la gravedad se invierte")
	await _wait_physics(80)
	var ceiling_bottom := LevelTwentysevenLayout.CEILING_Y + LevelTwentysevenLayout.CEILING_THICKNESS
	_check(player.global_position.y < ceiling_bottom + 40.0 and player.is_on_floor(), "gravedad: el jugador cae al techo y camina por debajo (y=%.0f)" % player.global_position.y)
	await _place_player(level, Vector2(zone.global_position.x + zone.zone_size.x * 0.5 + 60.0, 300.0))
	await _wait_physics(10)
	_check(not player.inverted_gravity, "gravedad: fuera de la zona vuelve a la normal")
	await _place_player(level, zone.global_position)
	await _wait_physics(5)
	zone.reset()
	_check(not player.inverted_gravity, "gravedad: reaparecer restaura la gravedad")
	await _place_player(level, Vector2(150.0, 616.0))
	var cannon := level.find_child("BattlementCannon0", true, false) as WallCannon
	var shots := 0
	cannon.reset()
	cannon.tick(cannon.initial_delay + 0.01)
	cannon.tick(cannon.warning_time + 0.01)
	for node in get_nodes_in_group("enemy_projectiles"):
		shots += 1
	_check(shots >= 1, "cañón: tras el aviso dispara una bola")
	await _unload(level)

	# Catapulta: el peñasco cae donde marca el círculo.
	level = await _load(29)
	var catapult := level.find_child("Catapult0", true, false) as Catapult
	var origin := catapult.global_position + Vector2(0.0, -70.0)
	var target_point := Vector2(2100.0, catapult.ground_y - ThrownBoulder.DIAMETER * 0.5)
	var speed := catapult.launch_speed(origin, target_point)
	var velocity := Vector2(cos(Catapult.LAUNCH_ANGLE), -sin(Catapult.LAUNCH_ANGLE)) * speed
	var position := origin
	var t := 0.0
	while position.y < target_point.y or velocity.y < 0.0:
		velocity.y += catapult.gravity * 0.001
		position += velocity * 0.001
		t += 0.001
		if t > 10.0:
			break
	_check(absf(position.x - target_point.x) < 25.0, "catapulta: el peñasco cae en el blanco (error %.0f px)" % absf(position.x - target_point.x))
	catapult.reset()
	catapult.tick(catapult.initial_delay + 0.01)
	_check(catapult.state == Hazard.State.WARNING and catapult._marker_visible, "catapulta: marca la zona de impacto durante el aviso")
	catapult.tick(catapult.warning_time + 0.01)
	_check(not get_nodes_in_group("thrown_boulders").is_empty(), "catapulta: lanza el peñasco al terminar el aviso")
	await _unload(level)


# --- Nivel 27 -------------------------------------------------------------

func _test_level_27() -> void:
	var level := await _load(27)
	_check(level.find_children("*Cannon*", "Node2D", true, false).size() >= 8, "27: varios cañones de pared")
	var zone := level.find_child("CorridorGravity", true, false) as GravityZone
	var ceiling := level.find_child("CorridorCeiling", true, false) as Node2D
	_check(zone != null and ceiling != null and zone.global_position.x < ceiling.global_position.x + 200.0, "27: pasillo con zona de gravedad bajo un techo")
	_check(level.find_children("FallZone*", "Area2D", true, false).size() >= 1, "27: foso mortal bajo el pasillo")
	await _unload(level)


# --- Nivel 28: llaves ------------------------------------------------------

func _test_level_28() -> void:
	var level := await _load(28)
	var player := _player(level)
	var portal := level.get_node("ExitPortal") as ExitPortal
	var victory := level.find_child("Victory", true, false) as VictoryCondition
	_check(portal.locked, "28: el portal empieza bloqueado")
	_check(get_nodes_in_group("keys").size() == 3, "28: tres llaves (una por celda)")
	var gate_l := level.find_child("DungeonGateL", true, false) as SwitchGate
	var lever_l := level.find_child("DungeonLeverL", true, false) as LeverSwitch
	lever_l.activate()
	await _wait_physics(3)
	_check(gate_l.is_open, "28: la palanca abre el rastrillo izquierdo")
	var guard_l := level.find_child("DungeonGuardL", true, false) as TrainingDummy
	await _wait_physics(30)
	_check(not is_instance_valid(guard_l) or guard_l.health.is_dead, "28: el guardián de la celda cae al abrir el rastrillo")
	var reached := [0]
	portal.reached.connect(func(): reached[0] += 1)
	await _place_player(level, portal.global_position)
	await _wait_physics(5)
	_check(reached[0] == 0, "28: un portal bloqueado no deja pasar")
	var keys := get_nodes_in_group("keys")
	for i in keys.size() - 1:
		await _place_player(level, (keys[i] as Node2D).global_position)
		await _wait_physics(3)
	_check(portal.locked and victory.progress().x == 2, "28: con 2 de 3 llaves sigue cerrado")
	await _place_player(level, (keys[keys.size() - 1] as Node2D).global_position)
	await _wait_physics(20)
	_check(not portal.locked and victory.is_fulfilled, "28: con las 3 llaves la salida se abre")
	await _place_player(level, Vector2(portal.global_position.x - 200.0, 616.0))
	await _place_player(level, portal.global_position)
	await _wait_physics(10)
	_check(reached[0] == 1, "28: con la salida abierta el portal funciona")
	await _unload(level)


# --- Nivel 29 -------------------------------------------------------------

func _test_level_29() -> void:
	var level := await _load(29)
	_check(get_nodes_in_group("hazards").size() >= 3, "29: tres catapultas")
	_check(level.find_children("CatapultWall*", "Node", true, false).size() == 3, "29: tres muros que exigen caja o resorte")
	var kinds := {}
	for item in get_nodes_in_group("grab_items"):
		kinds[(item as GrabItem).kind] = true
	_check(kinds.has(GrabItem.Kind.CRATE) and kinds.has(GrabItem.Kind.SPRING) and kinds.has(GrabItem.Kind.ROCK), "29: hay cajas, resortes y rocas")
	await _unload(level)


# --- Nivel 30 -------------------------------------------------------------

func _test_level_30() -> void:
	var level := await _load(30)
	var player := _player(level)
	var portal := level.get_node("ExitPortal") as ExitPortal
	var victory := level.find_child("Victory", true, false) as VictoryCondition
	_check(player.stats.dash_speed > 100.0 and player.stats.dash_cooldown < 5.0, "30: el impulso está disponible")
	var shared := load("res://resources/player/player_stats.tres") as PlayerStats
	_check(shared.dash_speed > 100.0, "30: el recurso compartido de estadísticas no se contamina")
	_check(portal.locked and victory.progress() == Vector2i(0, 2), "30: el portal empieza bloqueado (0/2 botones)")
	var enemies := get_nodes_in_group("arena_enemies")
	_check(enemies.size() == 6, "30: seis enemigos en la arena (%d)" % enemies.size())
	_check(level.find_children("ThroneLock*", "Node2D", true, false).size() == 2 and get_nodes_in_group("channel_locks").size() == 2, "30: dos élites con escudo")
	# Botón del techo: gravedad invertida y aterrizar sobre él.
	var ceiling_button := level.find_child("ThroneButtonCeiling", true, false) as FloorButton
	var zone := level.find_child("ThroneGravity", true, false) as GravityZone
	await _place_player(level, Vector2(ceiling_button.global_position.x, 500.0))
	await _wait_physics(90)
	_check(ceiling_button.is_on, "30: el botón del techo se activa con la gravedad invertida")
	var high_button := level.find_child("ThroneButtonHigh", true, false) as FloorButton
	high_button.activate()
	await _wait_physics(40)
	var left := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not (enemy as TrainingDummy).health.is_dead:
			left += 1
	_check(left == 4, "30: los dos botones eliminan a los dos élites (quedan %d)" % left)
	_check(victory.mode == VictoryCondition.Mode.CHANNEL and victory.is_fulfilled and not portal.locked, "30: al pisar los dos botones el portal se abre (aunque queden soldados)")
	await _unload(level)


func _wait_physics(frames: int) -> void:
	for _i in frames:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
