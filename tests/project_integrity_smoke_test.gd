extends SceneTree
## Integridad del proyecto (2026-11-27): carga TODOS los scripts (.gd) de
## scripts/, resources/ y tools/ y todas las escenas (.tscn) de scenes/ salvo
## las de niveles (ya las cargan all_levels/critical_path). Detecta en un solo
## proceso errores de sintaxis y escenas con referencias rotas en archivos que
## ningún otro test toca (p. ej. tras renombrar un script o borrar un asset).
## Ejecutar con:
## godot --headless --path . --script res://tests/project_integrity_smoke_test.gd

const SCRIPT_DIRS := ["res://scripts", "res://resources", "res://tools"]
const SCENE_DIRS := ["res://scenes"]
const SKIP_SCENE_DIRS := ["res://scenes/levels"]

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scripts: Array[String] = []
	for dir in SCRIPT_DIRS:
		_collect(dir, ".gd", scripts)
	var broken_scripts: Array[String] = []
	for path in scripts:
		var script := load(path) as Script
		if script == null or not script.can_instantiate() and not _is_abstract_ok(script):
			broken_scripts.append(path)
	_check(scripts.size() > 100, "Se encuentran los scripts del proyecto (%d)" % scripts.size())
	_check(broken_scripts.is_empty(), "Todos los scripts compilan %s" % str(broken_scripts))

	var scenes: Array[String] = []
	for dir in SCENE_DIRS:
		_collect(dir, ".tscn", scenes)
	var broken_scenes: Array[String] = []
	for path in scenes:
		var skip := false
		for prefix in SKIP_SCENE_DIRS:
			if path.begins_with(prefix):
				skip = true
		if skip:
			continue
		var scene := load(path) as PackedScene
		if scene == null or not scene.can_instantiate():
			broken_scenes.append(path)
	_check(broken_scenes.is_empty(), "Todas las escenas (salvo niveles) cargan %s" % str(broken_scenes))

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _is_abstract_ok(script: Script) -> bool:
	## Scripts que extienden un tipo no instanciable (p. ej. RefCounted
	## estáticos o editores) cargan bien aunque can_instantiate() sea false.
	return script.has_source_code() and script.get_instance_base_type() != &""


func _collect(dir: String, extension: String, out: Array[String]) -> void:
	var access := DirAccess.open(dir)
	if access == null:
		return
	for file in access.get_files():
		if file.ends_with(extension):
			out.append(dir.path_join(file))
	for sub in access.get_directories():
		if not sub.begins_with("."):
			_collect(dir.path_join(sub), extension, out)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
