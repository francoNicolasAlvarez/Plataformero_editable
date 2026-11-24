extends SceneTree
## Verifica la regla de espaciado entre plataformas (2026-11-11): cualquier
## hueco entre dos plataformas debe medir al menos 1.5x el tamaño del jugador
## (45 px horizontal, 72 px vertical) o las plataformas se tocan/solapan en
## ese eje. Comprueba la regla en si misma y recorre los tres niveles.
## Ejecutar con:
## godot --headless --path . --script res://tests/platform_spacing_smoke_test.gd

const LEVEL_ONE := preload("res://scenes/levels/test_level.tscn")
const LEVEL_TWO := preload("res://scenes/levels/level_two.tscn")
const LEVEL_THREE := preload("res://scenes/levels/level_three.tscn")
const LEVEL_FOUR := preload("res://scenes/levels/level_four.tscn")
const LEVEL_FIVE := preload("res://scenes/levels/level_five.tscn")
const LEVEL_SIX := preload("res://scenes/levels/level_six.tscn")
const LEVEL_SEVEN := preload("res://scenes/levels/level_seven.tscn")
const LEVEL_EIGHT := preload("res://scenes/levels/level_eight.tscn")
const LEVEL_NINE := preload("res://scenes/levels/level_nine.tscn")
const LEVEL_TEN := preload("res://scenes/levels/level_ten.tscn")
const LEVEL_ELEVEN := preload("res://scenes/levels/level_eleven.tscn")
const LEVEL_TWELVE := preload("res://scenes/levels/level_twelve.tscn")
const LEVEL_THIRTEEN := preload("res://scenes/levels/level_thirteen.tscn")
const LEVEL_FOURTEEN := preload("res://scenes/levels/level_fourteen.tscn")
const LEVEL_FIFTEEN := preload("res://scenes/levels/level_fifteen.tscn")
const LEVEL_SIXTEEN := preload("res://scenes/levels/level_sixteen.tscn")
const LEVEL_SEVENTEEN := preload("res://scenes/levels/level_seventeen.tscn")
const LEVEL_EIGHTEEN := preload("res://scenes/levels/level_eighteen.tscn")
const LEVEL_NINETEEN := preload("res://scenes/levels/level_nineteen.tscn")
const LEVEL_TWENTY := preload("res://scenes/levels/level_twenty.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_rule_semantics()

	await _check_level(LEVEL_ONE.instantiate(), "Nivel 1", 110)
	await _check_level(LEVEL_TWO.instantiate(), "Nivel 2", 40)
	await _check_level(LEVEL_THREE.instantiate(), "Nivel 3", 30)
	await _check_level(LEVEL_FOUR.instantiate(), "Nivel 4", 2)
	await _check_level(LEVEL_FIVE.instantiate(), "Nivel 5", 10)
	await _check_level(LEVEL_SIX.instantiate(), "Nivel 6", 12)
	await _check_level(LEVEL_SEVEN.instantiate(), "Nivel 7", 100)
	await _check_level(LEVEL_EIGHT.instantiate(), "Nivel 8", 40)
	await _check_level(LEVEL_NINE.instantiate(), "Nivel 9", 40)
	await _check_level(LEVEL_TEN.instantiate(), "Nivel 10", 10)
	await _check_level(LEVEL_ELEVEN.instantiate(), "Nivel 11", 10)
	await _check_level(LEVEL_TWELVE.instantiate(), "Nivel 12", 20)
	await _check_level(LEVEL_THIRTEEN.instantiate(), "Nivel 13", 3)
	await _check_level(LEVEL_FOURTEEN.instantiate(), "Nivel 14", 10)
	await _check_level(LEVEL_FIFTEEN.instantiate(), "Nivel 15", 10)
	await _check_level(LEVEL_SIXTEEN.instantiate(), "Nivel 16", 20)
	await _check_level(LEVEL_SEVENTEEN.instantiate(), "Nivel 17", 20)
	await _check_level(LEVEL_EIGHTEEN.instantiate(), "Nivel 18", 20)
	await _check_level(LEVEL_NINETEEN.instantiate(), "Nivel 19", 10)
	await _check_level(LEVEL_TWENTY.instantiate(), "Nivel 20", 4)
	# El nivel 21 (laberinto) queda fuera: la regla compara todos los pares y en
	# un edificio de varios pisos hay pares de pisos distintos a menos de 72 px
	# en vertical que nunca se tocan. Sus holguras se comprueban en maze_level_smoke_test.

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check_rule_semantics() -> void:
	var parent := Node2D.new()
	root.add_child(parent)

	_check(PlatformSpacing.MIN_GAP_X == 45.0, "El hueco horizontal minimo es 1.5x el ancho del jugador")
	_check(PlatformSpacing.MIN_GAP_Y == 72.0, "El hueco vertical minimo es 1.5x la altura del jugador")

	_check(_pair_is_valid(parent, Vector2(0, 0), Vector2(245, 0)), "Un hueco horizontal de 45 px es valido")
	_check(not _pair_is_valid(parent, Vector2(0, 0), Vector2(230, 0)), "Un hueco horizontal menor que 45 px es invalido")
	_check(_pair_is_valid(parent, Vector2(0, 0), Vector2(200, 0)), "Dos plataformas que se tocan en horizontal son validas")
	_check(_pair_is_valid(parent, Vector2(0, 0), Vector2(1000, 0)), "Dos plataformas alineadas y lejanas son validas")
	_check(_pair_is_valid(parent, Vector2(0, 0), Vector2(0, 96)), "Un hueco vertical de 72 px es valido")
	_check(not _pair_is_valid(parent, Vector2(0, 0), Vector2(0, 84)), "Un hueco vertical menor que 72 px es invalido")
	_check(_pair_is_valid(parent, Vector2(0, 0), Vector2(0, 20)), "Dos plataformas apiladas que se solapan son validas")
	_check(not _pair_is_valid(parent, Vector2(0, 0), Vector2(230, 30)), "Un hueco diagonal estrecho es invalido")

	parent.queue_free()


func _pair_is_valid(parent: Node2D, pos_a: Vector2, pos_b: Vector2) -> bool:
	var a := Platform.new()
	var b := Platform.new()
	a.platform_size = Vector2(200, 24)
	b.platform_size = Vector2(200, 24)
	parent.add_child(a)
	parent.add_child(b)
	a.position = pos_a
	b.position = pos_b
	var valid := PlatformSpacing.is_pair_valid(
		PlatformSpacing.platform_rect(a),
		PlatformSpacing.platform_rect(b)
	)
	a.free()
	b.free()
	return valid


func _check_level(level: Node2D, label: String, min_platforms: int) -> void:
	root.add_child(level)
	await _wait_physics(30)

	var platforms := PlatformSpacing.collect_platforms(level)
	var violations := PlatformSpacing.collect_violations(level)
	_check(platforms.size() >= min_platforms, "%s mantiene bastantes plataformas (%d)" % [label, platforms.size()])
	_check(violations.is_empty(), "%s respeta el espaciado minimo de 1.5x el jugador" % label)
	if not violations.is_empty():
		for index in mini(violations.size(), 8):
			var data: Dictionary = violations[index]
			print("  [HUECO INVALIDO %s] A=%s %s  B=%s %s  hueco=%s" % [
				label,
				data["a_position"],
				data["a_size"],
				data["b_position"],
				data["b_size"],
				data["gap"],
			])
		if violations.size() > 8:
			print("  ... y %d huecos invalidos mas en %s" % [violations.size() - 8, label])
	level.queue_free()
	await _wait_physics(2)


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
