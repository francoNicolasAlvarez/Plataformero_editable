extends SceneTree
## Comprueba el asset modular de plataformas (2026-11-13): los cinco tipos,
## el movimiento horizontal/circular/giratorio, los pinchos solo en los bordes
## y la exclusión de las plataformas móviles en la regla de espaciado.
## Ejecutar con:
## godot --headless --path . --script res://tests/platform_asset_smoke_test.gd

const PLATFORM_SCENE := preload("res://scenes/world/platform.tscn")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var holder := Node2D.new()
	holder.name = "Holder"
	root.add_child(holder)

	var static_platform := _make(holder, Platform.Kind.STATIC)
	await _wait_physics(20)
	var static_position := static_platform.position
	await _wait_physics(20)
	_check(static_platform is AnimatableBody2D, "La plataforma base es un cuerpo animado")
	_check(is_equal_approx(static_platform.position.x, static_position.x), "La plataforma estática no se mueve")
	_check(not static_platform.sync_to_physics, "La plataforma estática no usa sincronía física")

	var horizontal := _make(holder, Platform.Kind.HORIZONTAL)
	horizontal.position += Vector2(300.0, 0.0)
	horizontal.travel = Vector2(90.0, 0.0)
	horizontal.speed = 1.5
	await _wait_physics(2)
	var horizontal_start := horizontal.position
	await _wait_physics(25)
	_check(horizontal.position.distance_to(horizontal_start) > 2.0, "La plataforma horizontal se desplaza")
	_check(horizontal.sync_to_physics, "La plataforma móvil sincroniza su cuerpo físico")

	var circular := _make(holder, Platform.Kind.CIRCULAR)
	circular.position += Vector2(600.0, 0.0)
	circular.circle_radius = 55.0
	circular.circle_speed = 1.2
	await _wait_physics(2)
	var circular_start := circular.position
	await _wait_physics(25)
	_check(circular.position.distance_to(circular_start) > 3.0, "La plataforma circular orbita")

	var rotating := _make(holder, Platform.Kind.ROTATING)
	rotating.position += Vector2(900.0, 0.0)
	rotating.rotation_speed = 1.4
	await _wait_physics(2)
	var rotation_start := rotating.rotation
	await _wait_physics(30)
	_check(not is_equal_approx(rotating.rotation, rotation_start), "La plataforma giratoria oscila sobre su eje")
	_check(absf(rad_to_deg(rotating.rotation)) <= 30.01, "La inclinación nunca supera 30 grados")

	var spiked := _make(holder, Platform.Kind.SPIKED)
	spiked.position += Vector2(1200.0, 0.0)
	await _wait_physics(3)
	var left := spiked.get_node_or_null("SpikeLeft") as Area2D
	var right := spiked.get_node_or_null("SpikeRight") as Area2D
	_check(left != null and right != null, "La plataforma con pinchos crea pinchos en ambos bordes")
	if left != null and right != null:
		_check(left.position.x < -50.0 and right.position.x > 50.0, "Los pinchos quedan en los bordes, no en el centro")
		_check(left.visible and right.visible, "Los pinchos de borde son visibles")
		var left_shape := left.get_node("CollisionShape2D") as CollisionShape2D
		_check(not left_shape.disabled, "Los pinchos de borde tienen colisión activa")
	_check(static_platform.get_node("SpikeLeft").visible == false, "Las plataformas sin pinchos ocultan sus bordes")

	_check(PlatformSpacing.collect_platforms(holder).size() == 2, "La regla de espaciado solo cuenta plataformas fijas")
	var moving_count := 0
	for platform in holder.get_children():
		if platform is Platform and platform.is_moving():
			moving_count += 1
	_check(moving_count == 3, "El asset distingue tres tipos móviles")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _make(parent: Node, kind: Platform.Kind) -> Platform:
	var platform := PLATFORM_SCENE.instantiate() as Platform
	platform.kind = kind
	parent.add_child(platform)
	return platform


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
