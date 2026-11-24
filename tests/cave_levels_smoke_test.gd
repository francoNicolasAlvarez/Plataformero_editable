extends SceneTree
## Comprueba los niveles 16 "GRUTA", 17 "MINA", 18 "CRISTALES", 19 "GALERÍA" y
## 20 "DERRUMBE" (2026-11-18, mundo 4): cadena de niveles, obstáculos de la
## Fase 4 (plataformas que se derrumban, respiraderos, zonas oscuras), control,
## hierbas, portal, zona de caída y alcance de los saltos. Ejecutar con:
## godot --headless --path . --script res://tests/cave_levels_smoke_test.gd

const SCENES := {
	16: "res://scenes/levels/level_sixteen.tscn",
	17: "res://scenes/levels/level_seventeen.tscn",
	18: "res://scenes/levels/level_eighteen.tscn",
	19: "res://scenes/levels/level_nineteen.tscn",
	20: "res://scenes/levels/level_twenty.tscn",
}
const NEXT := {
	16: "res://scenes/levels/level_seventeen.tscn",
	17: "res://scenes/levels/level_eighteen.tscn",
	18: "res://scenes/levels/level_nineteen.tscn",
	19: "res://scenes/levels/level_twenty.tscn",
	20: "res://scenes/levels/level_twentyone.tscn",
}
const NAMES := {16: "GRUTA", 17: "MINA", 18: "CRISTALES", 19: "GALERÍA", 20: "DERRUMBE"}
const WORLDS := {16: "LevelSixteenGenerated", 17: "LevelSeventeenGenerated", 18: "LevelEighteenGenerated", 19: "LevelNineteenGenerated", 20: "LevelTwentyGenerated"}
const MAX_JUMP_GAP := 300.0

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for number in [16, 17, 18, 19, 20]:
		var level: Node = (load(SCENES[number]) as PackedScene).instantiate()
		root.add_child(level)
		await _wait_physics(30)
		_check_common(level, number)
		match number:
			16: _check_sixteen(level)
			17: _check_seventeen(level)
			18: _check_eighteen(level)
			19: _check_nineteen(level)
			20: _check_twenty(level)
		level.queue_free()
		await _wait_physics(3)

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _world(level: Node, number: int) -> Node:
	return level.get_node_or_null(WORLDS[number])


func _of_type(world: Node, type: Variant) -> Array:
	var result: Array = []
	for node in world.get_children():
		if is_instance_of(node, type):
			result.append(node)
	return result


func _check_common(level: Node, number: int) -> void:
	var tag := "Nivel %d" % number
	_check(level.next_level_path == NEXT[number], "%s: lleva a %s" % [tag, NEXT[number].get_file()])
	_check(LevelRegistry.get_level(number).display_name == NAMES[number], "%s: se llama %s en el registro" % [tag, NAMES[number]])
	_check(LevelRegistry.get_level(number).world_number == 4, "%s: pertenece al mundo 4" % tag)
	var world := _world(level, number)
	_check(world != null, "%s: genera su mundo" % tag)
	if world == null:
		return
	_check(world.get_node_or_null("CaveSky") != null and world.get_node_or_null("CaveCeiling") != null, "%s: tiene fondo de cueva con techo" % tag)
	var zone := world.get_node_or_null("FallZone%s" % _zone_suffix(number)) as Area2D
	_check(zone != null, "%s: tiene zona de caída" % tag)
	if zone != null:
		var shape := zone.get_node("CollisionShape2D").shape as RectangleShape2D
		_check(shape.size.x >= _width(number), "%s: la zona de caída cubre todo el ancho" % tag)
	_check(not get_nodes_in_group("checkpoints").is_empty() and get_nodes_in_group("checkpoints").size() == 1, "%s: tiene un único control" % tag)
	var portal := level.get_node("ExitPortal") as Node2D
	_check(portal.position.x > _width(number) - 1800.0, "%s: el portal está al final" % tag)
	_check(not level.get_node("Player").health.is_dead, "%s: el jugador está vivo" % tag)


func _zone_suffix(number: int) -> String:
	return {16: "Grotto", 17: "Mine", 18: "Crystals", 19: "Gallery", 20: "Collapse"}[number]


func _width(number: int) -> float:
	return {16: 15000.0, 17: 15000.0, 18: 15000.0, 19: 16000.0, 20: 16000.0}[number]


func _check_sixteen(level: Node) -> void:
	var world := _world(level, 16)
	var crumbling := _of_type(world, CrumblingPlatform)
	_check(crumbling.size() == 10, "Nivel 16: 10 plataformas que se derrumban (una por foso)")
	_check(_of_type(world, SteamVent).is_empty(), "Nivel 16: sin respiraderos (presenta solo el derrumbe)")
	_check(get_nodes_in_group("gimmick_zones").is_empty(), "Nivel 16: sin zonas oscuras")
	_check(get_nodes_in_group("healing_herbs").size() == 3 or _herbs(level) == 3, "Nivel 16: tres hierbas")
	_check(_crumbling_reaches_ground(crumbling, LevelSixteenLayout.START_WIDTH, LevelSixteenLayout.SECTION_START_X), "Nivel 16: cada plataforma que se derrumba alcanza los dos bordes del foso")


func _check_seventeen(level: Node) -> void:
	var world := _world(level, 17)
	var vents := _of_type(world, SteamVent)
	_check(vents.size() == 18, "Nivel 17: 18 respiraderos (dos por sección)")
	var delays := {}
	for vent in vents:
		delays[(vent as SteamVent).initial_delay] = true
	_check(delays.size() >= 2, "Nivel 17: los respiraderos están desfasados")
	_check(world.get_node_or_null("RockfallSpawner") != null, "Nivel 17: caen rocas")
	_check(_of_type(world, CrumblingPlatform).is_empty(), "Nivel 17: sin plataformas que se derrumban")
	_check(_herbs(level) == 3, "Nivel 17: tres hierbas")


func _check_eighteen(level: Node) -> void:
	var world := _world(level, 18)
	var zones := _of_type(world, DarkZone)
	_check(zones.size() == 2, "Nivel 18: dos zonas oscuras")
	var checkpoint := get_nodes_in_group("checkpoints")[0] as Node2D
	var lit := true
	for zone in zones:
		if (zone as DarkZone).contains_x(checkpoint.global_position.x):
			lit = false
	_check(lit, "Nivel 18: el control queda fuera de la oscuridad")
	_check(world.get_node_or_null("FlyingSpawner") != null, "Nivel 18: hay murciélagos")
	_check(_of_type(world, SteamVent).size() == 2, "Nivel 18: dos respiraderos entre las zonas")
	_check(_herbs(level) == 3, "Nivel 18: tres hierbas")


func _check_nineteen(level: Node) -> void:
	var world := _world(level, 19)
	var steps := 0
	for node in world.get_children():
		if node is Platform or node is CrumblingPlatform:
			if String(node.name).begins_with("Gallery"):
				steps += 1
	_check(steps == LevelNineteenLayout.ROUTE_COUNT, "Nivel 19: 28 plataformas en la ascensión (%d)" % steps)
	_check(not _of_type(world, CrumblingPlatform).is_empty(), "Nivel 19: hay plataformas que se derrumban")
	_check(_of_type(world, SteamVent).size() == 2, "Nivel 19: dos respiraderos en las cornisas")
	_check(_of_type(world, DarkZone).size() == 1, "Nivel 19: un tramo a oscuras")
	_check(not get_nodes_in_group("sky_sentries").is_empty(), "Nivel 19: hay centinela superior")
	_check(_herbs(level) == 3, "Nivel 19: tres hierbas")
	var max_gap := 0.0
	for index in range(LevelNineteenLayout.ROUTE_COUNT - 1):
		var width_a := LevelNineteenLayout.LEDGE_WIDTH if index in LevelNineteenLayout.LEDGES else LevelNineteenLayout.PLATFORM_WIDTH
		var width_b := LevelNineteenLayout.LEDGE_WIDTH if (index + 1) in LevelNineteenLayout.LEDGES else LevelNineteenLayout.PLATFORM_WIDTH
		var gap := LevelNineteenLayout.route_x(index + 1) - LevelNineteenLayout.route_x(index) - (width_a + width_b) * 0.5
		max_gap = maxf(max_gap, gap)
	_check(max_gap <= MAX_JUMP_GAP, "Nivel 19: ningún salto horizontal supera %.0f px (máx %.0f)" % [MAX_JUMP_GAP, max_gap])


func _check_twenty(level: Node) -> void:
	var world := _world(level, 20)
	var crumbling := _of_type(world, CrumblingPlatform)
	_check(crumbling.size() == 30, "Nivel 20: 30 plataformas que se derrumban en 5 cadenas")
	var islands := 0
	for node in world.get_children():
		if String(node.name).begins_with("CollapseIsland"):
			islands += 1
	_check(islands == 4, "Nivel 20: cuatro islas de descanso")
	_check(world.get_node_or_null("RockfallSpawner") != null, "Nivel 20: caen rocas")
	_check(world.get_node_or_null("FlyingSpawner") != null, "Nivel 20: hay murciélagos")
	_check(not get_nodes_in_group("sky_sentries").is_empty(), "Nivel 20: hay centinela superior")
	_check(_of_type(world, DarkZone).size() == 1, "Nivel 20: último tramo a oscuras")
	_check(_herbs(level) == 1, "Nivel 20: una hierba en la isla del control")
	_check(world.get_node_or_null("CollapseFinalBrute") != null, "Nivel 20: bruto en la isla final")
	var max_gap := 0.0
	for chain in LevelTwentyLayout.ISLAND_COUNT + 1:
		for k in range(LevelTwentyLayout.CHAIN_LENGTH - 1):
			var gap := LevelTwentyLayout.crumble_center(chain, k + 1).x - LevelTwentyLayout.crumble_center(chain, k).x - 150.0
			max_gap = maxf(max_gap, gap)
	_check(max_gap <= MAX_JUMP_GAP, "Nivel 20: los saltos entre plataformas son alcanzables (%.0f px)" % max_gap)
	var island_gap := LevelTwentyLayout.island_center_x(0) - LevelTwentyLayout.ISLAND_WIDTH * 0.5 - (LevelTwentyLayout.crumble_center(0, 5).x + 75.0)
	_check(island_gap <= MAX_JUMP_GAP, "Nivel 20: se llega a la primera isla (%.0f px)" % island_gap)
	var last_edge := LevelTwentyLayout.crumble_center(4, 5).x + 75.0
	_check(LevelTwentyLayout.FINAL_START_X - last_edge <= MAX_JUMP_GAP, "Nivel 20: se llega a la isla final desde la última cadena")
	_check(LevelTwentyLayout.crumble_center(0, 0).x - 75.0 - LevelTwentyLayout.START_WIDTH <= MAX_JUMP_GAP, "Nivel 20: se llega a la primera cadena desde el inicio")


func _herbs(level: Node) -> int:
	var count := 0
	for node in level.find_children("*", "Area2D", true, false):
		if String(node.name).contains("HealingHerb") or node.scene_file_path.ends_with("healing_herb.tscn"):
			count += 1
	return count


func _crumbling_reaches_ground(crumbling: Array, start_width: float, first_section_x: float) -> bool:
	## La plataforma del inicio debe estar a <= 300 px de ambos bordes del foso.
	var first := crumbling[crumbling.size() - 1] as CrumblingPlatform  # CrumblingStart
	var left_gap := first.position.x - first.platform_size.x * 0.5 - start_width
	var right_gap := first_section_x - (first.position.x + first.platform_size.x * 0.5)
	return left_gap <= MAX_JUMP_GAP and right_gap <= MAX_JUMP_GAP


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
