class_name PlatformTexture
extends RefCounted
## Textura procedural sutil para plataformas (2026-11-16): vetas horizontales
## y motas de baja opacidad que siguen el tamaño y el color base. No usa
## assets externos y es idempotente: cada llamada reconstruye el detalle y lo
## deja por debajo de los remates y del contorno.

const DETAIL_NAME := "TextureDetail"


static func apply(owner: Node2D, size: Vector2, base_color: Color) -> void:
	var detail := owner.get_node_or_null(DETAIL_NAME) as Node2D
	if detail == null:
		detail = Node2D.new()
		detail.name = DETAIL_NAME
		owner.add_child(detail)
	_clear(detail)

	var half := size * 0.5
	var light := base_color.lightened(0.16)
	light.a = 0.18
	var dark := base_color.darkened(0.32)
	dark.a = 0.16

	var rng := RandomNumberGenerator.new()
	rng.seed = int(
		size.x * 131.0
		+ size.y * 977.0
		+ base_color.r * 10000.0
		+ base_color.g * 100.0
		+ base_color.b
	)

	var vein_count := clampi(int(size.y / 8.0), 1, 4)
	for index in vein_count:
		var y := lerpf(-half.y * 0.55, half.y * 0.55, float(index + 1) / float(vein_count + 1))
		var vein := Line2D.new()
		vein.name = "Vein%d" % index
		vein.width = 1.0
		vein.default_color = light if index % 2 == 0 else dark
		vein.points = PackedVector2Array([
			Vector2(-half.x + 4.0, y),
			Vector2(half.x - 4.0, y),
		])
		detail.add_child(vein)

	var speckle_count := clampi(int(size.x / 34.0), 2, 8)
	for index in speckle_count:
		var chip := Polygon2D.new()
		chip.name = "Chip%d" % index
		var chip_width := rng.randf_range(2.0, 5.0)
		var chip_height := rng.randf_range(1.0, 2.5)
		var chip_x := rng.randf_range(-half.x + 6.0, half.x - 6.0)
		var chip_y := rng.randf_range(-half.y + 4.0, half.y - 4.0)
		chip.polygon = PackedVector2Array([
			Vector2(chip_x - chip_width * 0.5, chip_y - chip_height * 0.5),
			Vector2(chip_x + chip_width * 0.5, chip_y - chip_height * 0.5),
			Vector2(chip_x + chip_width * 0.5, chip_y + chip_height * 0.5),
			Vector2(chip_x - chip_width * 0.5, chip_y + chip_height * 0.5),
		])
		chip.color = light if index % 2 == 0 else dark
		detail.add_child(chip)

	_move_below_finish(owner, detail)


static func _clear(detail: Node2D) -> void:
	for child in detail.get_children():
		child.free()


static func _move_below_finish(owner: Node2D, detail: Node2D) -> void:
	var anchor := owner.get_node_or_null("TopHighlight") as Node
	if anchor == null:
		anchor = owner.get_node_or_null("Top") as Node
	if anchor == null:
		anchor = owner.get_node_or_null("Outline") as Node
	if anchor != null:
		owner.move_child(detail, anchor.get_index())
