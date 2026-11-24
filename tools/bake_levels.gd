extends SceneTree
## Convierte los niveles generados por código en escenas editables a mano.
## Lee `scenes/levels/generated/level_*.tscn` (los niveles originales, que
## ejecutan su generador) y escribe `scenes/levels/level_*.tscn` (escenas
## normales con todos los objetos colocados). Uso:
##
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/bake_levels.gd
##
## Con un argumento se hornea un solo nivel (número): `-- 12`.
## ¡Atención! Sobrescribe las escenas de `scenes/levels/`: si editaste algún
## nivel a mano, haz copia antes de volver a hornear.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only := -1
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		only = int(args[0])
	var failures := 0
	for config in LevelRegistry.implemented_levels():
		if only > 0 and config.number != only:
			continue
		var source := config.scene_path.replace("res://scenes/levels/", "res://scenes/levels/generated/")
		var level := (load(source) as PackedScene).instantiate()
		root.add_child(level)
		var err := LevelBaker.bake(level, config.scene_path)
		if err == OK:
			print("[OK]    nivel %d horneado -> %s" % [config.number, config.scene_path])
		else:
			failures += 1
			print("[FALLO] nivel %d (error %d)" % [config.number, err])
		root.remove_child(level)
		level.free()
		await process_frame
	quit(1 if failures > 0 else 0)
