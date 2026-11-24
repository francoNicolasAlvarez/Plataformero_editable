class_name TowerKit
extends RefCounted
## Utilidades compartidas de los niveles del mundo 5 "TORRES Y ALTURAS"
## (2026-11-23): cielo vertical, losas con huecos y atajos para colocar las
## mecánicas nuevas (corrientes, plataformas temporizadas, prensas, palancas,
## compuertas, lanzadores y ruedas). Se apoya en `DesertKit` para enemigos,
## controles y hierbas, de modo que los generadores de los niveles 22-25 solo
## describen su diseño.

const LAUNCH_PAD_SCENE := preload("res://scenes/world/launch_pad.tscn")
const BLADE_WHEEL_SCENE := preload("res://scenes/world/blade_wheel.tscn")
const MINE_SCENE := preload("res://scenes/world/proximity_mine.tscn")
const FALL_ZONE_SCENE := preload("res://scenes/world/fall_zone.tscn")

const SKY_TOP := Color("#7fb4e8")
const SKY_MID := Color("#b9d8f2")
const SKY_BOTTOM := Color("#eaf4fb")
const STONE := Color("#9aa3b8")
const STONE_LIGHT := Color("#c4cbdb")
const STONE_DARK := Color("#6b7390")
const CLOUD := Color("#ffffff")


## Cielo degradado y nubes de decorado en el rectángulo dado.
static func sky(world: Node2D, rect: Rect2, palette: Dictionary = {}) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		palette.get("top", SKY_TOP), palette.get("mid", SKY_MID), palette.get("bottom", SKY_BOTTOM),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 16
	texture.height = 256
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	var back := TextureRect.new()
	back.name = "SkyBackdrop"
	back.texture = texture
	back.position = rect.position
	back.size = rect.size
	back.stretch_mode = TextureRect.STRETCH_SCALE
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.z_index = -30
	world.add_child(back)
	var cloud_color: Color = palette.get("cloud", CLOUD)
	var count := int(rect.size.x * rect.size.y / 900000.0) + 6
	for i in count:
		var x := rect.position.x + fposmod(float(i) * 733.0 + 140.0, rect.size.x)
		var y := rect.position.y + fposmod(float(i) * 541.0 + 90.0, rect.size.y)
		cloud(world, Vector2(x, y), 0.8 + float(i % 4) * 0.25, cloud_color)


static func cloud(world: Node2D, position: Vector2, scale_factor: float, color: Color) -> void:
	var node := Node2D.new()
	node.name = "DecorCloud"
	node.position = position
	node.z_index = -20
	node.modulate = Color(color.r, color.g, color.b, 0.85)
	var offsets := [Vector2(-60.0, 10.0), Vector2(-20.0, -10.0), Vector2(30.0, -4.0), Vector2(66.0, 12.0), Vector2(0.0, 14.0)]
	var radii := [28.0, 38.0, 34.0, 26.0, 40.0]
	for i in offsets.size():
		var puff := Polygon2D.new()
		var points := PackedVector2Array()
		for step in 14:
			points.append(Vector2.from_angle(TAU * float(step) / 14.0) * float(radii[i]))
		puff.polygon = points
		puff.position = offsets[i]
		node.add_child(puff)
	node.scale = Vector2(scale_factor, scale_factor)
	world.add_child(node)


## Losa horizontal de `from_x` a `to_x` con huecos [[x0, x1], ...].
static func slab(world: Node2D, from_x: float, to_x: float, top: float, thickness: float, holes: Array, node_name: String, color: Color = STONE) -> void:
	var edges: Array = [from_x]
	for hole in holes:
		edges.append(float(hole[0]))
		edges.append(float(hole[1]))
	edges.append(to_x)
	var piece := 0
	var i := 0
	while i < edges.size():
		var a: float = edges[i]
		var b: float = edges[i + 1]
		if b - a > 1.0:
			DesertKit.platform(world, Vector2((a + b) * 0.5, top + thickness * 0.5), Vector2(b - a, thickness), color, Platform.Kind.STATIC, "%s_%d" % [node_name, piece])
			piece += 1
		i += 2


static func block(world: Node2D, rect: Rect2, node_name: String, color: Color = STONE_DARK) -> Platform:
	return DesertKit.platform(world, rect.position + rect.size * 0.5, rect.size, color, Platform.Kind.STATIC, node_name)


static func cloud_platform(world: Node2D, center: Vector2, width: float, node_name: String) -> Platform:
	return DesertKit.platform(world, center, Vector2(width, 26.0), Color("#e8f1fa"), Platform.Kind.STATIC, node_name)


static func fall_zone(world: Node2D, y: float, width: float, node_name: String) -> void:
	var zone := DesertKit.spawn(FALL_ZONE_SCENE, world, Vector2(width * 0.5, y))
	zone.name = node_name
	var shape := zone.get_node("CollisionShape2D").shape as RectangleShape2D
	shape.size = Vector2(width + 800.0, 120.0)


static func updraft(world: Node2D, center: Vector2, size: Vector2, node_name: String, tint: Color = Color(0.7, 0.9, 1.0, 1.0), haze_alpha: float = 0.14, streak_alpha: float = 0.55) -> UpdraftZone:
	var zone := UpdraftZone.new()
	zone.tint = tint
	zone.haze_alpha = haze_alpha
	zone.streak_alpha = streak_alpha
	zone.name = node_name
	zone.zone_size = size
	zone.position = center
	world.add_child(zone)
	return zone


static func timed(world: Node2D, center: Vector2, width: float, node_name: String, solid_time: float, gone_time: float, phase: float) -> TimedPlatform:
	var node := TimedPlatform.new()
	node.name = node_name
	node.platform_size = Vector2(width, 24.0)
	node.solid_time = solid_time
	node.gone_time = gone_time
	node.initial_delay = phase
	node.position = center
	world.add_child(node)
	return node


static func crusher(world: Node2D, position: Vector2, node_name: String, drop: float = 200.0, auto: bool = false, phase: float = 0.0) -> CrusherTrap:
	var node := CrusherTrap.new()
	node.name = node_name
	node.drop_height = drop
	node.auto_cycle = auto
	node.initial_delay = phase
	node.position = position
	world.add_child(node)
	return node


static func lever(world: Node2D, position: Vector2, channel: String, node_name: String) -> LeverSwitch:
	var node := LeverSwitch.new()
	node.name = node_name
	node.channel = channel
	node.position = position
	world.add_child(node)
	return node


static func gate(world: Node2D, center: Vector2, size: Vector2, channel: String, node_name: String) -> SwitchGate:
	var node := SwitchGate.new()
	node.name = node_name
	node.channel = channel
	node.gate_size = size
	node.position = center
	world.add_child(node)
	return node


## Trampolín: lanzador con dirección fija hacia arriba (o la indicada).
static func bounce_pad(world: Node2D, position: Vector2, node_name: String, speed: float = 900.0, direction: Vector2 = Vector2.UP) -> Node2D:
	var pad := DesertKit.spawn(LAUNCH_PAD_SCENE, world, position)
	pad.name = node_name
	pad.set("mode", 1)  # LaunchPad.Mode.FIXED
	pad.set("launch_direction", direction)
	pad.set("launch_speed", speed)
	pad.set("zone_size", Vector2(90.0, 24.0))
	pad.set("control_lock", 0.15)
	return pad


static func wheel(world: Node2D, center: Vector2, node_name: String, clockwise: bool, arm: float = 110.0, speed: float = 0.25, angle: float = 0.0) -> Node2D:
	var node := DesertKit.spawn(BLADE_WHEEL_SCENE, world, center)
	node.name = node_name
	node.set("arm_length", arm)
	node.set("spin_speed", speed)
	node.set("clockwise", clockwise)
	node.set("start_angle_degrees", angle)
	return node


static func mine(world: Node2D, position: Vector2, node_name: String) -> Node2D:
	var node := DesertKit.spawn(MINE_SCENE, world, position)
	node.name = node_name
	return node


## Coloca la cámara con límites y seguimiento vertical opcional.
static func camera(level: Node2D, limits: Rect2, follow_y: bool) -> void:
	var node := level.get_node_or_null("Camera") as HorizontalCamera
	if node == null:
		return
	node.follow_y = follow_y
	node.limit_left = int(limits.position.x)
	node.limit_top = int(limits.position.y)
	node.limit_right = int(limits.end.x)
	node.limit_bottom = int(limits.end.y)
	node.snap_to_target()


static func portal(level: Node2D, position: Vector2) -> void:
	var node := level.get_node_or_null("ExitPortal")
	if node != null:
		node.position = position


## Centinela aspirador azul (esquina inferior izquierda de la pantalla).
static func vacuum_sentry(world: Node2D, node_name: String = "VacuumSentry") -> VacuumSentry:
	var node := VacuumSentry.new()
	node.name = node_name
	world.add_child(node)
	return node


## Techo con espinas: tira de pinchos pegada a la cara inferior de la losa de
## arriba (sin viga ni cadenas). `center_y` es el centro de las espinas.
static func spike_ceiling(world: Node2D, center_x: float, center_y: float, width: float, height: float, node_name: String) -> Node2D:
	var spikes := DesertKit.spawn(preload("res://scenes/world/spike_trap.tscn"), world, Vector2(center_x, center_y))
	spikes.name = node_name + "Spikes"
	spikes.rotation = PI
	spikes.scale = Vector2(width / 140.0, height / 20.0)
	return spikes
