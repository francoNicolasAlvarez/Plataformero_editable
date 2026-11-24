extends SceneTree

const LEVEL_SCENE := preload("res://scenes/levels/level_seven.tscn")
const NEXT_SCENE := "res://scenes/levels/level_eight.tscn"
const HAT_PATHS := ["SombreroDome", "SombreroDomeShade", "SombreroBrimLine", "WizardHat", "ArcherHood"]

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await _wait_physics(30)

	var player: Player = level.get_node("Player")
	var portal: ExitPortal = level.get_node("ExitPortal")
	var camera: Camera2D = level.get_node("Camera")
	var generated := level.get_node_or_null("LevelSevenGenerated")

	_check(level.level_variant == 7, "El nivel 7 usa la variante INVERSO")
	_check(level.level_name == "NIVEL 2-2", "El nivel se identifica como NIVEL 2-2")
	_check(level.time_limit == 70.0, "El nivel 7 tiene 70 segundos")
	_check(level.next_level_path == NEXT_SCENE, "El nivel 7 lleva al nivel 8")
	_check(generated != null, "Se generó el mundo invertido del nivel 7")
	_check(level.get_node("Platforms").get_child_count() == 0, "El nivel 7 limpia las plataformas base")

	_check(player.inverted_gravity, "El jugador usa gravedad invertida")
	_check(player.up_direction == Vector2.DOWN, "El jugador considera el techo como suelo")
	_check(player.visual.scale.y < 0.0, "El jugador está dibujado boca arriba")
	var player_shadow := player.get_node_or_null("Shadow") as Polygon2D
	_check(player_shadow != null and player_shadow.position.y < 0.0, "La sombra del jugador está sobre la cabeza")
	_check(player.global_position.y > 80.0 and player.global_position.y < 130.0, "El jugador aparece bajo el techo")

	var platforms := _collect_platforms(generated)
	_check(platforms.size() >= 100, "El nivel 7 tiene un recorrido de plataformas similar al nivel 1")
	var ceiling_tiles := 0
	for platform in platforms:
		if is_equal_approx(platform.position.y, 40.0):
			ceiling_tiles += 1
	_check(ceiling_tiles >= 24, "El suelo del nivel 1 se convirtió en techo")
	_check(platforms[0].scale.y < 0.0, "Las plataformas están invertidas")

	var fall_zone := generated.get_node_or_null("FallZoneInverted")
	_check(fall_zone != null and fall_zone.position.y < 0.0, "La zona mortal está por encima del techo")
	if fall_zone != null:
		var fall_shape := fall_zone.get_node("CollisionShape2D").shape as RectangleShape2D
		_check(fall_shape.size.x >= LevelSevenLayout.LEVEL_WIDTH, "La zona mortal cubre todo el ancho")

	_check(is_equal_approx(portal.position.y, 140.0), "El portal cuelga del techo")
	_check(portal.scale.y < 0.0, "El portal está invertido")
	_check(camera.limit_right == int(LevelSevenLayout.LEVEL_WIDTH), "La cámara cubre todo el recorrido")
	_check(camera.limit_bottom == 720, "La cámara mantiene la altura de pantalla")

	var checkpoints := level.get_tree().get_nodes_in_group("checkpoints")
	_check(checkpoints.size() == 1, "El nivel 7 tiene un control a mitad del recorrido")
	if not checkpoints.is_empty():
		var checkpoint := checkpoints[0] as Node2D
		_check(is_equal_approx(checkpoint.global_position.y, 128.0), "El control cuelga del techo")
		_check(checkpoint.scale.y < 0.0, "El control está invertido")

	var enemies := level.get_tree().get_nodes_in_group("enemies")
	_check(enemies.size() >= 25, "El nivel 7 reparte enemigos por todo el recorrido")
	var styled := 0
	for enemy in enemies:
		var body := enemy as TrainingDummy
		if body == null:
			continue
		_check(body.inverted_gravity, "Todos los enemigos del nivel 7 tienen gravedad invertida")
		_check(body.up_direction == Vector2.DOWN, "Los enemigos consideran el techo como suelo")
		var visual := body.get_node_or_null("Visual") as Node2D
		_check(visual != null and visual.scale.y < 0.0, "Los enemigos están dibujados boca arriba")
		var hat := visual.get_node_or_null("Level7Hat") as Polygon2D
		_check(hat != null, "Los enemigos llevan sombrero triangular")
		if hat != null:
			_check(hat.color == EnemyVisualVariant.HAT_COLOR, "El sombrero triangular es amarillo")
			_check(hat.polygon.size() == 3, "El sombrero es un triángulo")
		var original_hidden := 0
		for hat_path in HAT_PATHS:
			var original := visual.get_node_or_null(hat_path) as CanvasItem
			if original != null:
				if not original.visible:
					original_hidden += 1
		_check(original_hidden > 0, "El sombrero original está oculto")
		var eye := visual.get_node_or_null("EyeLeft") as Polygon2D
		_check(eye != null and eye.polygon.size() == 4, "Los ojos tienen forma almendrada")
		if eye != null and eye.polygon.size() >= 3:
			_check(eye.polygon[0].y < eye.polygon[2].y, "El ojo externo está más alto que el interno")
		styled += 1
	_check(styled == enemies.size(), "Todos los enemigos recibieron la variante visual")

	await _wait_physics(10)
	_check(player.is_on_floor(), "El jugador se apoya en el techo")
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	_check(player.velocity.y > 0.0, "El salto del nivel 7 empuja hacia abajo")

	print("")
	print("Comprobaciones: %d | Fallos: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _collect_platforms(node: Node) -> Array[Platform]:
	var result: Array[Platform] = []
	for child in node.get_children():
		if child is Platform:
			result.append(child)
		result.append_array(_collect_platforms(child))
	return result


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
