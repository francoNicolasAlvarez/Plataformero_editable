class_name PlatformSpacing
extends RefCounted
## Regla de espaciado entre plataformas (cambio 2026-11-11): cualquier hueco
## entre dos plataformas debe medir al menos 1.5x el tamaño del jugador en el
## eje del hueco: 45 px en horizontal (1.5x el ancho de 30) y 72 px en
## vertical (1.5x la altura de 48). Si dos plataformas se tocan o se solapan
## en un eje, en ese eje no existe hueco y se toleran (suelo continuo,
## plataformas apiladas). Así ningún hueco queda "atascado" para el jugador.
## Las plataformas móviles (AnimatableBody2D) quedan fuera de la regla porque
## se desplazan continuamente.

const PLAYER_SIZE := Vector2(30.0, 48.0)
const MIN_GAP_X: float = PLAYER_SIZE.x * 1.5
const MIN_GAP_Y: float = PLAYER_SIZE.y * 1.5


static func platform_rect(platform: Platform) -> Rect2:
	## Rectángulo mundial de una plataforma (posición = centro, tamaño completo).
	var size: Vector2 = platform.platform_size
	return Rect2(platform.global_position - size * 0.5, size)


static func axis_gap(a_start: float, a_end: float, b_start: float, b_end: float) -> float:
	## Hueco entre dos intervalos: <= 0 cuando se tocan o se solapan.
	return maxf(b_start - a_end, a_start - b_end)


static func separation(a: Rect2, b: Rect2) -> Vector2:
	return Vector2(
		axis_gap(a.position.x, a.end.x, b.position.x, b.end.x),
		axis_gap(a.position.y, a.end.y, b.position.y, b.end.y)
	)


static func is_pair_valid(a: Rect2, b: Rect2) -> bool:
	var gap := separation(a, b)
	var x_ok := gap.x <= 0.0 or gap.x >= MIN_GAP_X
	var y_ok := gap.y <= 0.0 or gap.y >= MIN_GAP_Y
	return x_ok and y_ok


static func collect_platforms(root: Node) -> Array[Platform]:
	var found: Array[Platform] = []
	_gather_platforms(root, found)
	return found


static func _gather_platforms(node: Node, found: Array[Platform]) -> void:
	if node is Platform and not node.is_moving():
		found.append(node)
	for child in node.get_children():
		_gather_platforms(child, found)


static func collect_violations(root: Node) -> Array[Dictionary]:
	## Pares de plataformas que incumplen la regla, con posición, tamaño y hueco.
	var platforms := collect_platforms(root)
	var violations: Array[Dictionary] = []
	for i in platforms.size():
		for j in range(i + 1, platforms.size()):
			var first: Platform = platforms[i]
			var second: Platform = platforms[j]
			var rect_a := platform_rect(first)
			var rect_b := platform_rect(second)
			if is_pair_valid(rect_a, rect_b):
				continue
			violations.append({
				"a_position": first.global_position,
				"a_size": first.platform_size,
				"b_position": second.global_position,
				"b_size": second.platform_size,
				"gap": separation(rect_a, rect_b),
			})
	return violations
