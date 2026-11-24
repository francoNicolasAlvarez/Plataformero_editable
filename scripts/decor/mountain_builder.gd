class_name MountainBuilder
extends RefCounted
## Decorador de colinas (2026-11-11): añade capas de detalle (cima pálida con
## borde en zigzag, cresta iluminada, ladera en sombra y arbolitos lejanos)
## como hijos Polygon2D de cada colina existente, reutilizando su geometría
## triangular de 3 puntos [izquierda, cima, derecha]. Los tres niveles llaman
## a decorate() tras crear o heredar sus colinas; es idempotente.

const CAP_FRACTION := 0.32
const RIDGE_WIDTH := 9.0
const SHADE_WIDTH := 14.0


static func decorate(
	hill: Polygon2D,
	cap_color: Color,
	ridge_color: Color,
	shade_color: Color,
	snow: bool
) -> void:
	## Añade el detalle a una colina de 3 puntos. La capa completa vive bajo
	## un hijo "MountainDetail" para no duplicar si se llama dos veces.
	if hill == null or hill.polygon.size() < 3:
		return
	if hill.get_node_or_null("MountainDetail") != null:
		return

	var left: Vector2 = hill.polygon[0]
	var peak: Vector2 = hill.polygon[1]
	var right: Vector2 = hill.polygon[2]

	var detail := Node2D.new()
	detail.name = "MountainDetail"
	hill.add_child(detail)

	if snow:
		_add_cap(detail, left, peak, right, cap_color)
	_add_ridge(detail, peak, left, ridge_color)
	_add_shade(detail, peak, right, shade_color)
	_add_far_trees(detail, left, right, shade_color.darkened(0.25))


static func _add_cap(parent: Node, left: Vector2, peak: Vector2, right: Vector2, color: Color) -> void:
	## Cima pálida con borde inferior en zigzag (nieve o luz de luna).
	var cap_left := peak.lerp(left, CAP_FRACTION)
	var cap_right := peak.lerp(right, CAP_FRACTION)
	var points := PackedVector2Array([peak, cap_left])
	var steps := 4
	for i in steps:
		var t := float(i + 1) / float(steps + 1)
		var base := cap_left.lerp(cap_right, t)
		points.append(base + Vector2(0.0, 8.0 if i % 2 == 0 else -4.0))
	points.append(cap_right)

	var cap := Polygon2D.new()
	cap.name = "Cap"
	cap.color = color
	cap.polygon = points
	parent.add_child(cap)


static func _add_ridge(parent: Node, peak: Vector2, left: Vector2, color: Color) -> void:
	## Franja iluminada a lo largo de la ladera izquierda (lado del sol).
	var down := left - peak
	var normal := Vector2(down.y, -down.x).normalized()
	var a := peak.lerp(left, 0.85)
	var ridge := Polygon2D.new()
	ridge.name = "RidgeLight"
	ridge.color = color
	ridge.polygon = PackedVector2Array([
		peak,
		a,
		a + normal * RIDGE_WIDTH,
		peak + normal * RIDGE_WIDTH * 0.66,
	])
	parent.add_child(ridge)


static func _add_shade(parent: Node, peak: Vector2, right: Vector2, color: Color) -> void:
	## Franja de sombra a lo largo de la ladera derecha.
	var down := right - peak
	var normal := Vector2(-down.y, down.x).normalized()
	var a := peak.lerp(right, 0.9)
	var shade := Polygon2D.new()
	shade.name = "SlopeShade"
	shade.color = color
	shade.polygon = PackedVector2Array([
		peak,
		a,
		a + normal * SHADE_WIDTH,
		peak + normal * SHADE_WIDTH * 0.7,
	])
	parent.add_child(shade)


static func _add_far_trees(parent: Node, left: Vector2, right: Vector2, color: Color) -> void:
	## Tres arbolitos triangulares sobre la línea base de la colina.
	for i in 3:
		var t := 0.3 + 0.2 * float(i)
		var base := left.lerp(right, t)
		var height := 14.0 + 5.0 * float(i % 2)
		var tree := Polygon2D.new()
		tree.name = "FarTree%d" % (i + 1)
		tree.color = color
		tree.polygon = PackedVector2Array([
			base + Vector2(-5.0, 0.0),
			base + Vector2(0.0, -height),
			base + Vector2(5.0, 0.0),
		])
		parent.add_child(tree)
