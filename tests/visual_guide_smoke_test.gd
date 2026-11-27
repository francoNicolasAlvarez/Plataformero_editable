extends SceneTree
## Comprueba las mejoras de la guía de diseño visual (2026-11-25): halo verde en
## la hierba curativa (acento de curación).

var _failures: int = 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[OK]    ", message)
	else:
		print("[FALLO] ", message)
		_failures += 1


func _initialize() -> void:
	var herb := (load("res://scenes/pickups/healing_herb.tscn") as PackedScene).instantiate()
	root.add_child(herb)
	await process_frame
	var halo := herb.get_node_or_null("Visual/Halo") as Polygon2D
	_check(halo != null, "la hierba tiene halo")
	if halo != null:
		_check(halo.color.g > halo.color.r and halo.color.a < 0.4, "el halo es verde y translúcido")
	var lever := LeverSwitch.new()
	root.add_child(lever)
	await process_frame
	await process_frame
	_check(lever.scale == Vector2.ONE and lever.get("_lamp") != null, "la palanca construye su lámpara")
	var lamp := lever.get("_lamp") as Polygon2D
	_check(lamp.scale.x >= 0.74 and lamp.scale.x <= 1.26, "la lámpara apagada pulsa suavemente")
	lever.activate()
	await process_frame
	_check(lamp.scale == Vector2.ONE, "la lámpara activada deja de pulsar")
	await _check_draw_layers()
	quit(1 if _failures > 0 else 0)


## Capas (2026-11-27): trampas y objetos se dibujan DETRÁS del suelo y las
## plataformas para que su base quede tapada; la sombra va por encima.
func _check_draw_layers() -> void:
	var level := (load("res://scenes/levels/level_two.tscn") as PackedScene).instantiate()
	root.add_child(level)
	for _frame in 5:
		await process_frame
	var ground_z := 0
	for platform in level.find_children("*", "Platform", true, false):
		ground_z = _effective_z(platform)
		break
	var groups := ["spikes", "healing_pickups", "checkpoints", "exit_portals"]
	for group in groups:
		var items := get_nodes_in_group(group)
		var in_front := 0
		for item in items:
			if _effective_z(item) >= ground_z:
				in_front += 1
		_check(not items.is_empty() and in_front == 0, "%s: %d de %d se dibujan detrás del suelo" % [group, items.size() - in_front, items.size()])
	var herb := get_nodes_in_group("healing_pickups")[0] as Node
	var shadow := herb.get_node_or_null("Shadow") as CanvasItem
	_check(shadow != null and _effective_z(shadow) > ground_z, "la sombra de la hierba se ve sobre el suelo")
	level.queue_free()
	await process_frame


func _effective_z(node: Node) -> int:
	var z := 0
	var current := node
	while current is CanvasItem:
		var item := current as CanvasItem
		z += item.z_index
		if not item.z_as_relative:
			break
		current = current.get_parent()
	return z
