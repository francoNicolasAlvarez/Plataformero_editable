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
	quit(1 if _failures > 0 else 0)
