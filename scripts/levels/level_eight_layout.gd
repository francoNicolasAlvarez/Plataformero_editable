class_name LevelEightLayout
extends RefCounted
## Nivel 8 (2026-11-16): espejo horizontal del nivel 2. El recorrido empieza
## en la derecha, termina en la izquierda y los controles horizontales van
## invertidos. Reutiliza el generador del nivel 2 con ancho de espejo para que
## cada posición sea exactamente x' = ancho - x.

const LEVEL_WIDTH := 13400.0
const PLAYER_START_X := LEVEL_WIDTH - 620.0
const PLAYER_Y := 600.0


static func build(level: Node2D) -> void:
	LevelTwoLayout.build(level, LEVEL_WIDTH)
	var generated := level.get_node_or_null("LevelTwoGenerated")
	if generated != null:
		generated.name = "LevelEightGenerated"
	_configure_player(level)
	_configure_camera(level)


static func _configure_player(level: Node2D) -> void:
	var player := level.get_node_or_null("Player") as Player
	if player == null:
		return
	player.inverted_controls = true
	player.configure_controls()
	player.global_position = Vector2(PLAYER_START_X, PLAYER_Y)


static func _configure_camera(level: Node2D) -> void:
	var camera := level.get_node_or_null("Camera") as Camera2D
	if camera != null:
		camera.snap_to_target()


static func mirror_x(x: float) -> float:
	## Helper público para los tests: posición del nivel 2 reflejada en el 8.
	return LEVEL_WIDTH - x
