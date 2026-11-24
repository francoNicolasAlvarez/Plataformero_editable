extends SceneTree
## Comprueba el rediseño del ambiente (2026-11-11): SVGs de decoración con
## detalle (raíces/corteza/frutas en el árbol, bayas y briznas en el arbusto,
## bultos y borde iluminado en la nube, plumas y patas en el ave, doble capa
## de rayos en el sol), colinas con capas de nieve/cresta/sombra vía
## MountainBuilder en los tres niveles, y detalles del nivel 3 (cráteres de
## luna y granja).
## Ejecutar con:
## godot --headless --path . --script res://tests/decor_detail_smoke_test.gd

const LEVEL_ONE_SCENE := preload("res://scenes/levels/level_one.tscn")
const LEVEL_TWO_SCENE := preload("res://scenes/levels/level_two.tscn")
const LEVEL_THREE_SCENE := preload("res://scenes/levels/level_three.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_decor_svgs()
	await _test_mountain_builder()
	await _test_level_hills()
	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_decor_svgs() -> void:
	_test_svg_markers(
		"res://assets/decor/tree.svg",
		["Roots", "Bark", "Branches", "Fruit"],
		"El árbol tiene raíces, corteza, ramas y frutas"
	)
	_test_svg_markers(
		"res://assets/decor/bush.svg",
		["Berries", "flowers", "Grass"],
		"El arbusto tiene bayas, florecitas y briznas de hierba"
	)
	_test_svg_markers(
		"res://assets/decor/cloud.svg",
		["Bumps", "Lit top"],
		"La nube tiene bultos y bordes iluminados"
	)
	_test_svg_markers(
		"res://assets/decor/bird.svg",
		["Tail feathers", "feather layers", "toes"],
		"El ave tiene cola, capas de plumas y patas con dedos"
	)

	var sun_text := _read_text("res://assets/decor/sun.svg")
	_check(
		sun_text.count("<line") >= 20 and sun_text.contains("Layered halo"),
		"El sol tiene dos capas de rayos y halos superpuestos"
	)


func _test_svg_markers(path: String, markers: Array, message: String) -> void:
	var text := _read_text(path)
	var found := not text.is_empty()
	for marker in markers:
		if not text.contains(marker):
			found = false
	_check(found, message)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	return content


func _test_mountain_builder() -> void:
	var hill := Polygon2D.new()
	hill.polygon = PackedVector2Array([
		Vector2(-300.0, 0.0), Vector2(-60.0, -220.0), Vector2(320.0, 0.0),
	])
	root.add_child(hill)
	MountainBuilder.decorate(hill, Color.WHITE, Color.WHITE, Color.BLACK, true)

	var detail := hill.get_node_or_null("MountainDetail")
	_check(detail != null, "MountainBuilder crea la capa de detalle en la colina")
	if detail != null:
		var names: Array[String] = []
		for child in detail.get_children():
			names.append(child.name)
		_check(names.has("Cap"), "La colina nevada recibe cima en zigzag")
		_check(names.has("RidgeLight"), "La colina recibe cresta iluminada")
		_check(names.has("SlopeShade"), "La colina recibe ladera en sombra")
		_check(names.has("FarTree3"), "La colina recibe arbolitos lejanos")

	MountainBuilder.decorate(hill, Color.WHITE, Color.WHITE, Color.BLACK, true)
	_check(hill.get_child_count() == 1, "decorate() es idempotente y no duplica capas")

	var bare := Polygon2D.new()
	bare.polygon = PackedVector2Array([Vector2.ZERO, Vector2.ONE])
	MountainBuilder.decorate(bare, Color.WHITE, Color.WHITE, Color.BLACK, true)
	_check(bare.get_child_count() == 0, "Una colina sin 3 puntos no se decora")
	hill.queue_free()
	bare.queue_free()


func _test_level_hills() -> void:
	var level_one := LEVEL_ONE_SCENE.instantiate()
	root.add_child(level_one)
	await _wait_physics(10)
	var decorated_one := 0
	for hill in level_one.get_node("BackgroundDecor").get_children():
		if hill.get_node_or_null("MountainDetail") != null:
			decorated_one += 1
	_check(decorated_one >= 10, "Las colinas diurnas del nivel 1 llevan capas de detalle")
	level_one.queue_free()

	var level_two := LEVEL_TWO_SCENE.instantiate()
	root.add_child(level_two)
	await _wait_physics(10)
	var hills_two := level_two.get_node("LevelTwoGenerated/HillParallax").get_children()
	var decorated_two := 0
	for hill in hills_two:
		if hill.get_node_or_null("MountainDetail") != null:
			decorated_two += 1
	_check(decorated_two == hills_two.size() and hills_two.size() > 0, "Todas las colinas del atardecer llevan detalle")
	level_two.queue_free()

	var level_three := LEVEL_THREE_SCENE.instantiate()
	root.add_child(level_three)
	await _wait_physics(10)
	var hills_three := level_three.get_node("LevelThreeGenerated/HillParallax").get_children()
	var decorated_three := 0
	for hill in hills_three:
		if hill.get_node_or_null("MountainDetail") != null:
			decorated_three += 1
	_check(decorated_three == hills_three.size() and hills_three.size() > 0, "Todas las colinas nocturnas llevan detalle")

	var moon := level_three.get_node("LevelThreeGenerated/MoonParallax")
	_check(moon.get_child_count() >= 5, "La luna del nivel 3 tiene cráteres dibujados")
	level_three.queue_free()


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
