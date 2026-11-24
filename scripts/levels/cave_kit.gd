class_name CaveKit
extends RefCounted
## Utilidades compartidas de los niveles del mundo 4 "CAVERNAS Y MINAS"
## (Fase 6, 2026-11-18): fondo de cueva (degradado, estalagmitas lejanas,
## techo con estalactitas y cristales), plataformas que se derrumban,
## respiraderos de vapor y zonas oscuras. Reutiliza `DesertKit` para suelo,
## plataformas del asset modular, enemigos, rocas, murciélagos y centinela.

const ROCK := Color("#4d4866")
const ROCK_DARK := Color("#37334d")
const STEP := Color("#5d5878")
const CRYSTAL := Color("#7fe3ff")
const GROUND_TOP := 640.0


static func backdrop(world: Node2D, width: float, palette: Dictionary) -> void:
	## palette: top/mid/bottom (degradado), far (Color), ceiling (Color),
	## crystal (Color).
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([palette["top"], palette["mid"], palette["bottom"]])
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 16
	texture.height = 256
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	var rect := TextureRect.new()
	rect.name = "CaveSky"
	rect.texture = texture
	rect.size = Vector2(width, 720.0)
	rect.z_index = -30
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	world.add_child(rect)

	var far := Parallax2D.new()
	far.name = "FarParallax"
	far.scroll_scale = Vector2(0.3, 1.0)
	world.add_child(far)
	var base := Polygon2D.new()
	base.color = palette["far"]
	base.polygon = PackedVector2Array([
		Vector2(-400.0, 650.0), Vector2(width + 400.0, 650.0),
		Vector2(width + 400.0, 720.0), Vector2(-400.0, 720.0),
	])
	base.z_index = -23
	far.add_child(base)
	for i in 16:
		var spire := Polygon2D.new()
		spire.color = (palette["far"] as Color).lightened(0.04 * float(i % 3))
		spire.position = Vector2(150.0 + float(i) * 560.0, 650.0)
		var height := 150.0 + float((i * 53) % 110)
		spire.polygon = PackedVector2Array([
			Vector2(-110.0, 0.0), Vector2(-30.0, -height), Vector2(0.0, -height - 30.0),
			Vector2(40.0, -height + 10.0), Vector2(130.0, 0.0),
		])
		spire.z_index = -22
		far.add_child(spire)

	_ceiling(world, width, palette["ceiling"])
	_crystals(world, width, palette["crystal"])


static func _ceiling(world: Node2D, width: float, color: Color) -> void:
	## Techo continuo con estalactitas en zigzag, solo decorativo.
	var points := PackedVector2Array([Vector2(-200.0, -40.0)])
	var x := -200.0
	var index := 0
	while x < width + 400.0:
		points.append(Vector2(x, 50.0 + float((index * 37) % 40)))
		points.append(Vector2(x + 55.0, 14.0))
		x += 110.0
		index += 1
	points.append(Vector2(width + 400.0, -40.0))
	var ceiling := Polygon2D.new()
	ceiling.name = "CaveCeiling"
	ceiling.color = color
	ceiling.polygon = points
	ceiling.z_index = -9
	world.add_child(ceiling)


static func _crystals(world: Node2D, width: float, color: Color) -> void:
	var x := 600.0
	var index := 0
	while x < width:
		var cluster := Node2D.new()
		cluster.name = "Crystal%d" % index
		cluster.position = Vector2(x, GROUND_TOP)
		cluster.z_index = -12
		for k in 3:
			var shard := Polygon2D.new()
			var h := 40.0 + float(((index + k) * 29) % 50)
			shard.color = color.darkened(0.15 * float(k))
			shard.polygon = PackedVector2Array([
				Vector2(-10.0 + float(k) * 14.0, 0.0), Vector2(-6.0 + float(k) * 14.0, -h),
				Vector2(float(k) * 14.0, -h - 12.0), Vector2(6.0 + float(k) * 14.0, -h + 6.0),
				Vector2(10.0 + float(k) * 14.0, 0.0),
			])
			cluster.add_child(shard)
		world.add_child(cluster)
		x += 520.0 + float((index * 173) % 420)
		index += 1


# --- Obstáculos de la Fase 4 -------------------------------------------------

static func crumbling(world: Node2D, center: Vector2, node_name: String, width: float = 150.0) -> CrumblingPlatform:
	var node := CrumblingPlatform.new()
	node.name = node_name
	node.platform_size = Vector2(width, 24.0)
	node.platform_color = STEP
	node.position = center
	world.add_child(node)
	return node


static func vent(world: Node2D, x: float, top: float, node_name: String, delay: float = 0.0) -> SteamVent:
	var node := SteamVent.new()
	node.name = node_name
	node.initial_delay = delay
	node.position = Vector2(x, top)
	world.add_child(node)
	return node


static func dark_zone(world: Node2D, from_x: float, to_x: float, node_name: String, radius: float = 250.0) -> DarkZone:
	var node := DarkZone.new()
	node.name = node_name
	node.zone_size = Vector2(to_x - from_x, 1000.0)
	node.light_radius = radius
	node.position = Vector2((from_x + to_x) * 0.5, 360.0)
	world.add_child(node)
	return node
