class_name LevelDesignRules
extends RefCounted
## Reglas generales de diseño de niveles (2026-11-27). Fuente única para tests
## y herramientas; el texto completo de cada regla está en DISENO_NIVELES.md
## (sección "Reglas generales") y en `.opencode/agent/levels-world.md`.
##
## R1 Salida a la vista: ningún enemigo en la PRIMERA MITAD de la pantalla
##    inicial (la mitad del lado por el que se empieza: la izquierda si el
##    portal está a la derecha, la derecha si el nivel va hacia la izquierda).
##    Así el jugador ve el nivel antes de que nada pueda atacarle.
##    -> `enemies_in_start_half()`, comprobada en critical_path_smoke_test.
## R2 Salida segura: el jugador nace apoyado y sin enemigos a < 160 px
##    (critical_path_smoke_test).
## R3 Espaciado: huecos entre plataformas >= 1,5x el jugador (PlatformSpacing).
## R4 Portal y controles apoyados en suelo y dentro de la cámara
##    (critical_path_smoke_test).
## R5 Trampas legibles: aviso antes de dañar salvo peligros estáticos y
##    visibles; los clavos sobre plataformas usan `Platform.Kind.SPIKED`
##    (clavos en los bordes, centro libre), nunca un pincho suelto encima.

const START_SAFE_RADIUS := 160.0


static func start_view(level: Node2D) -> Rect2:
	## Pantalla inicial: lo que muestra la cámara del nivel ahora mismo (llamar
	## justo tras cargarlo, con la cámara ya colocada sobre el jugador).
	return EnemySenses.visible_rect(level)


static func travel_direction(level: Node2D) -> float:
	var player := level.get_node_or_null("Player") as Node2D
	var portal := level.get_node_or_null("ExitPortal") as Node2D
	if player == null or portal == null:
		return 1.0
	var start: Vector2 = level.get_meta("start_point", player.global_position)
	return -1.0 if portal.global_position.x < start.x else 1.0


static func start_half(level: Node2D) -> Rect2:
	## Primera mitad de la pantalla inicial según el sentido del recorrido.
	var view := start_view(level)
	var half := Rect2(view.position, Vector2(view.size.x * 0.5, view.size.y))
	if travel_direction(level) < 0.0:
		half.position.x += view.size.x * 0.5
	return half


static func enemies_in_start_half(level: Node2D) -> Array[Node2D]:
	## R1: enemigos (grupo "enemies") dentro de la primera mitad de la pantalla
	## inicial. Debe devolver una lista vacía.
	var half := start_half(level)
	var found: Array[Node2D] = []
	if half.size == Vector2.ZERO:
		return found
	for enemy in level.get_tree().get_nodes_in_group("enemies"):
		var node := enemy as Node2D
		if node != null and level.is_ancestor_of(node) and half.has_point(node.global_position):
			found.append(node)
	return found
