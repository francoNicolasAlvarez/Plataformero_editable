extends SceneTree
## Comprueba los efectos de pantalla (2026-11-18): la viñeta queda bajo el HUD,
## es idempotente y el hit-stop no toca el tiempo en headless. También que la
## babosa salta más a menudo y que el saltador explosivo tiene onda grande.
## Ejecutar con: godot --headless --path . --script res://tests/screen_fx_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := (load("res://scenes/levels/level_one.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await physics_frame
	var vignette := level.get_node_or_null("VignetteLayer") as CanvasLayer
	_check(vignette != null and vignette.get_node_or_null("Vignette") != null, "El nivel tiene viñeta")
	_check(vignette != null and vignette.layer < (level.get_node("HUD") as CanvasLayer).layer, "La viñeta queda por debajo del HUD")
	_check(ScreenFx.add_vignette(level) == vignette, "Añadir la viñeta dos veces no la duplica")
	ScreenFx.hit_stop(self)
	_check(is_equal_approx(Engine.time_scale, 1.0), "El hit-stop no altera el tiempo en headless")

	var slug := SlugEnemy.new()
	_check(slug.idle_max <= 1.2 and slug.idle_min <= 0.6, "La babosa descansa poco entre saltos (%.1f-%.1f s)" % [slug.idle_min, slug.idle_max])
	slug.free()
	var jumper := BlastJumperEnemy.new()
	_check(jumper.wave_radius >= 250.0, "La onda del saltador explosivo es grande (%.0f px)" % jumper.wave_radius)
	_check(jumper.detect_range >= 500.0, "El saltador explosivo detecta desde lejos")
	jumper.free()

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OK]    ", message)
	else:
		_failures += 1
		print("[FALLO] ", message)
