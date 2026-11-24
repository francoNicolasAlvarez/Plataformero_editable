class_name RockPile
extends StaticBody2D
## Pila de rocas (2026-11-17): dos bloques escalonados sólidos sobre los que el
## jugador puede saltar y posarse, junto al bruto del nivel 9. La posición del
## nodo es el centro de la base a ras de suelo. Se construye por código.

const BASE_SIZE := Vector2(130.0, 44.0)
const TOP_SIZE := Vector2(80.0, 44.0)


static func total_height() -> float:
	return BASE_SIZE.y + TOP_SIZE.y


func _ready() -> void:
	add_to_group("rock_piles")
	collision_layer = 1
	collision_mask = 0
	_add_block("Base", Vector2(0.0, -BASE_SIZE.y * 0.5), BASE_SIZE, Color("#8b7a66"))
	_add_block("Top", Vector2(-8.0, -BASE_SIZE.y - TOP_SIZE.y * 0.5), TOP_SIZE, Color("#9a8873"))


func _add_block(block_name: String, center: Vector2, size: Vector2, color: Color) -> void:
	var shape := CollisionShape2D.new()
	shape.name = "%sShape" % block_name
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.position = center
	add_child(shape)

	var half := size * 0.5
	var points := PackedVector2Array([
		center + Vector2(-half.x + 6.0, half.y), center + Vector2(-half.x, -half.y + 10.0),
		center + Vector2(-half.x + 18.0, -half.y), center + Vector2(half.x - 14.0, -half.y),
		center + Vector2(half.x, -half.y + 8.0), center + Vector2(half.x - 4.0, half.y),
	])
	var body := Polygon2D.new()
	body.name = "%sVisual" % block_name
	body.color = color
	body.polygon = points
	add_child(body)
	var crack := Line2D.new()
	crack.points = PackedVector2Array([
		center + Vector2(-half.x * 0.3, -half.y * 0.6), center + Vector2(0.0, 0.0), center + Vector2(half.x * 0.25, half.y * 0.6),
	])
	crack.width = 2.0
	crack.default_color = Color("#4a3f33")
	add_child(crack)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color.BLACK
	add_child(outline)
