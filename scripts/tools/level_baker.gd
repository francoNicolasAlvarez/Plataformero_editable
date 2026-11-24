class_name LevelBaker
extends RefCounted
## "Hornea" un nivel generado por código en una escena .tscn normal que se
## puede abrir y editar a mano en el editor de Godot (mover plataformas,
## enemigos, trampas, decorado...). Se usa desde `tools/bake_levels.gd`:
##
##   godot --headless --path . --script res://tools/bake_levels.gd
##
## Cómo funciona: instancia el nivel (el generador coloca todo), marca como
## "propios" los nodos creados por el generador para que se guarden en la
## escena, descarta lo que se crea solo en tiempo de ejecución (muros
## invisibles, viñeta, fundido, HUD, hijos internos de cada objeto), activa
## `baked` en la raíz y guarda la escena. Los scripts generadores (`*_layout.gd`)
## siguen existiendo por si se quiere volver a generar.

const HUD_SCENE_PATH := "res://scenes/ui/level_hud.tscn"
## Nodos que el nivel crea al arrancar y que no deben guardarse.
const RUNTIME_NODES := ["BoundaryWalls", "VignetteLayer", "FadeLayer"]
## Scripts que generan hijos por código: en la escena horneada pasan a ser
## nodos normales (si no, volverían a generarlos y quedarían duplicados).
const GENERATOR_CLASSES := [&"LevelOneExtension", &"LevelFourRoute"]


## Crea (si no existe) la escena del HUD compartida por todos los niveles.
static func ensure_hud_scene() -> PackedScene:
	if ResourceLoader.exists(HUD_SCENE_PATH):
		return load(HUD_SCENE_PATH) as PackedScene
	var base := (load("res://scenes/levels/test_level.tscn") as PackedScene).instantiate()
	var hud := base.get_node("HUD")
	base.remove_child(hud)
	_set_owner_recursive(hud, hud)
	var packed := PackedScene.new()
	packed.pack(hud)
	ResourceSaver.save(packed, HUD_SCENE_PATH)
	hud.free()
	base.free()
	return load(HUD_SCENE_PATH) as PackedScene


## Guarda `level` (ya instanciado y dentro del árbol) como escena horneada.
static func bake(level: Node, out_path: String) -> int:
	var hud_scene := ensure_hud_scene()
	for node_name in RUNTIME_NODES:
		var runtime_node := level.get_node_or_null(node_name)
		if runtime_node != null:
			runtime_node.free()

	for node in level.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and script.get_global_name() in GENERATOR_CLASSES:
			node.set_script(null)
		elif script != null and script.get_global_name() == &"":
			if String(script.resource_path).ends_with("fall_zone.gd"):
				var shape := (node.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
				node.set("zone_size", shape.size)

	var old_hud := level.get_node_or_null("HUD")
	var hud_index := 0
	if old_hud != null:
		hud_index = old_hud.get_index()
		level.remove_child(old_hud)
		old_hud.free()
	var hud := hud_scene.instantiate()
	hud.name = "HUD"
	level.add_child(hud)
	level.move_child(hud, hud_index)

	var brightness := level.get_node_or_null("Brightness") as CanvasModulate
	if brightness != null:
		brightness.color = Color.WHITE

	level.scene_file_path = ""
	level.set("baked", true)
	level.set("route_points", level.get("_route"))
	level.owner = null
	var counter := [0]
	hud.owner = level
	_own_children(level, level, counter)

	var packed := PackedScene.new()
	var err := packed.pack(level)
	if err != OK:
		return err
	return ResourceSaver.save(packed, out_path)


## Marca como propios (se guardan en la escena) los nodos que creó el
## generador. Reglas:
##  - Un nodo "componente" (tiene script o es una escena instanciada) construye
##    sus propios hijos al arrancar: solo se guardan sus hijos que sean escenas
##    instanciadas por el generador (p. ej. un arquero sobre una plataforma).
##  - Un nodo simple (Node2D, Polygon2D, Parallax2D...) se guarda con todos sus
##    hijos.
static func _own_children(node: Node, root: Node, counter: Array) -> void:
	var is_component := node != root and (node.get_script() != null or node.scene_file_path != "")
	for child in node.get_children():
		if child.name == &"HUD" and node == root:
			continue
		if is_component:
			if child.owner != null or child.scene_file_path == "":
				continue
			# Los pinchos de borde los crea cada Platform al arrancar: guardarlos
			# dejaría copias siempre activas (e invisibles) que dañan al pisar.
			if node is Platform and (child.name == &"SpikeLeft" or child.name == &"SpikeRight"):
				continue
		elif node == root and child.owner != null and child.owner != root:
			continue
		child.owner = root
		if String(child.name).contains("@"):
			counter[0] += 1
			child.name = "%s_%d" % [child.get_class(), counter[0]]
		_own_children(child, root, counter)


static func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
