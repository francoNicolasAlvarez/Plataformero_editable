class_name EnemyVisualVariant
extends RefCounted

const MARKER := "Level7Variant"
const HAT_NAME := "Level7Hat"
const HAT_COLOR := Color(1.0, 0.86, 0.12, 1.0)
const HAT_PATHS := [
	"SombreroDome",
	"SombreroDomeShade",
	"SombreroBrimLine",
	"WizardHat",
	"ArcherHood",
]

static func apply_inverted_style(enemy: Node2D) -> void:
	var visual := enemy.get_node_or_null("Visual") as Node2D
	if visual == null or visual.get_node_or_null(MARKER) != null:
		return

	var marker := Node.new()
	marker.name = MARKER
	visual.add_child(marker)

	for hat_path in HAT_PATHS:
		var hat := visual.get_node_or_null(hat_path) as CanvasItem
		if hat != null:
			hat.visible = false

	var triangle := Polygon2D.new()
	triangle.name = HAT_NAME
	triangle.color = HAT_COLOR
	triangle.polygon = PackedVector2Array([
		Vector2(0.0, -45.0),
		Vector2(-12.0, -26.0),
		Vector2(12.0, -26.0),
	])
	visual.add_child(triangle)
	visual.move_child(triangle, visual.get_child_count() - 1)

	var outline := Line2D.new()
	outline.name = "Level7HatOutline"
	outline.width = 2.0
	outline.default_color = Color(0.0, 0.0, 0.0, 1.0)
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
	outline.end_cap_mode = Line2D.LINE_CAP_ROUND
	outline.closed = true
	outline.points = triangle.polygon
	triangle.add_child(outline)

	var left := visual.get_node_or_null("EyeLeft") as Polygon2D
	var right := visual.get_node_or_null("EyeRight") as Polygon2D
	var center_y := -20.0
	if left != null and left.polygon.size() > 0:
		center_y = (left.polygon[0].y + left.polygon[2].y) * 0.5
	if left != null:
		left.polygon = _almond(-3.0, center_y, -1.0)
	if right != null:
		right.polygon = _almond(3.0, center_y, 1.0)

	var pupil_left := visual.get_node_or_null("PupilLeft") as Polygon2D
	var pupil_right := visual.get_node_or_null("PupilRight") as Polygon2D
	if pupil_left != null:
		pupil_left.polygon = _almond(-2.8, center_y, -1.0, 0.55)
	if pupil_right != null:
		pupil_right.polygon = _almond(2.8, center_y, 1.0, 0.55)
	for brow_name in ["BrowLeft", "BrowRight"]:
		var brow := visual.get_node_or_null(brow_name) as CanvasItem
		if brow != null:
			brow.visible = false


static func _almond(cx: float, cy: float, side: int, scale: float = 1.0) -> PackedVector2Array:
	var outer := cx + 1.8 * scale * side
	var inner := cx - 1.8 * scale * side
	return PackedVector2Array([
		Vector2(outer, cy - 0.4 * scale),
		Vector2(cx, cy - 1.2 * scale),
		Vector2(inner, cy + 0.4 * scale),
		Vector2(cx, cy + 1.2 * scale),
	])
