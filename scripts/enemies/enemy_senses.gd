class_name EnemySenses
extends RefCounted
## Percepción común de los enemigos (2026-11-27).
##
## - `player(node)`: devuelve el jugador con una caché débil, en vez de recorrer
##   el grupo "player" en cada fotograma de cada enemigo.
## - `on_screen(node, margin)`: true si el enemigo está dentro del área visible
##   de la cámara actual (más un margen). Los enemigos solo EMPIEZAN un ataque
##   (aviso incluido) cuando se les ve: así ningún disparo, peñasco o salto
##   llega desde fuera de pantalla sin aviso visible (guía de diseño, sección 3).
##   Sin cámara activa (tests aislados) se considera visible.
## - `can_engage(node, offset, range_x, range_y)`: rango rectangular + visible.

## Margen por defecto: medio cuerpo del enemigo puede asomar por el borde.
const SCREEN_MARGIN := 24.0

static var _cached_player: WeakRef = null


static func player(node: Node) -> Node2D:
	if _cached_player != null:
		var cached := _cached_player.get_ref() as Node2D
		if cached != null and cached.is_inside_tree() and cached.get_tree() == node.get_tree():
			return cached
	var found := node.get_tree().get_first_node_in_group("player") as Node2D
	_cached_player = weakref(found) if found != null else null
	return found


static func visible_rect(node: Node) -> Rect2:
	## Rectángulo del mundo que muestra la cámara actual; vacío si no hay cámara.
	var viewport := node.get_viewport()
	if viewport == null:
		return Rect2()
	var camera := viewport.get_camera_2d()
	if camera == null:
		return Rect2()
	var size := viewport.get_visible_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - size * 0.5, size)


static func on_screen(node: Node2D, margin: float = SCREEN_MARGIN) -> bool:
	var rect := visible_rect(node)
	if rect.size == Vector2.ZERO:
		return true
	return rect.grow(margin).has_point(node.global_position)


static func can_engage(node: Node2D, offset: Vector2, range_x: float, range_y: float) -> bool:
	if absf(offset.x) > range_x or absf(offset.y) > range_y:
		return false
	return on_screen(node)
