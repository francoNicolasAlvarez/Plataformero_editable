extends SceneTree
## Comprueba la unidad de referencia "J" (2026-11-18) y que coincide con el
## cuerpo real del jugador y con medidas conocidas del juego.
## Ejecutar con: godot --headless --path . --script res://tests/units_smoke_test.gd

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	root.add_child(player)
	await physics_frame
	var shape := (player.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	_check(is_equal_approx(shape.size.y, GameUnits.PLAYER_HEIGHT_PX), "1 J equivale a la altura real del jugador (%.0f px)" % shape.size.y)
	_check(is_equal_approx(shape.size.x, GameUnits.PLAYER_WIDTH_PX), "El ancho del jugador es %.0f px" % shape.size.x)
	_check(is_equal_approx(GameUnits.to_players(96.0), 2.0), "Un muro bajo del laberinto (96 px) mide 2 J")
	_check(is_equal_approx(GameUnits.from_players(6.0), 288.0), "Un pasillo del laberinto mide 6 J")
	_check(is_equal_approx(GameUnits.to_players(player.stats.run_speed), 532.0 / 48.0), "Correr son ~11 J por segundo")
	var dash := player.stats.dash_speed * player.stats.dash_time
	_check(absf(GameUnits.to_players(dash) - 3.2) < 0.1, "El impulso recorre ~3,2 J (%s)" % GameUnits.describe(dash))
	_check(GameUnits.to_players(1152.0) == 24.0, "La pantalla mide 24 J de ancho")
	_check(absf(GameUnits.to_meters(48.0) - 1.7) < 0.001, "Con 1,7 m por jugador, 48 px son 1,7 m")
	_check(GameUnits.describe(205.0) == "205 px = 4.3 J", "describe() da un texto legible")
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
