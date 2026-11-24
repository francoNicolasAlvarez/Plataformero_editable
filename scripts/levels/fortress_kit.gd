class_name FortressKit
extends RefCounted
## Utilidades compartidas de los niveles del mundo 6 "FORTALEZA MEDIEVAL"
## (2026-11-24): cielo de crepúsculo, muros, y colocadores de las mecánicas nuevas
## (botones, candados de enemigo, puente levadizo, cañones, catapultas, zonas de
## gravedad, objetos sujetables, llaves y condiciones de victoria). Se apoya en
## `DesertKit`/`TowerKit` para suelo, enemigos y cámara.

const GROUND := 640.0
const SKY := {"top": Color("#2f3354"), "mid": Color("#6a5f86"), "bottom": Color("#c49aa6")}
const BRICK := Color("#7d7488")
const BRICK_DARK := Color("#58506a")


static func start(level: Node2D, node_name: String, width: float) -> Node2D:
	var world := DesertKit.begin(level, node_name)
	TowerKit.sky(world, Rect2(-300.0, -300.0, width + 600.0, 1400.0), SKY)
	return world


static func finish(level: Node2D, world: Node2D, width: float, spawn: Vector2, portal: Vector2, route: PackedVector2Array) -> void:
	TowerKit.fall_zone(world, 780.0, width, "FallZone")
	DesertKit.place_player(level, spawn)
	TowerKit.portal(level, portal)
	TowerKit.camera(level, Rect2(0.0, 0.0, width, 720.0), false)
	level.call("set_route", route)


## Muro de ladrillo desde `top` hasta el suelo (x = centro).
static func wall(world: Node2D, x: float, top: float, node_name: String, thickness: float = 60.0) -> Platform:
	return TowerKit.block(world, Rect2(x - thickness * 0.5, top, thickness, GROUND - top), node_name, BRICK_DARK)


static func ledge(world: Node2D, from_x: float, to_x: float, top: float, node_name: String) -> Platform:
	return TowerKit.block(world, Rect2(from_x, top, to_x - from_x, 24.0), node_name, BRICK)


static func button(world: Node2D, position: Vector2, channel: String, node_name: String, reset_after: float = 0.0) -> FloorButton:
	var node := FloorButton.new()
	node.name = node_name
	node.channel = channel
	node.reset_after = reset_after
	node.position = position
	world.add_child(node)
	return node


static func lock(world: Node2D, enemy: Node2D, channel: String, node_name: String) -> ChannelLock:
	var node := ChannelLock.new()
	node.name = node_name
	node.channel = channel
	node.target = NodePath("../%s" % enemy.name)
	node.position = enemy.position
	world.add_child(node)
	return node


static func bridge(world: Node2D, hinge: Vector2, channel: String, node_name: String, length: float = 300.0, raise_after: float = 10.0, side: float = 1.0) -> Drawbridge:
	var node := Drawbridge.new()
	node.name = node_name
	node.channel = channel
	node.bridge_size = Vector2(length, 24.0)
	node.raise_after = raise_after
	node.hinge_side = side
	node.position = hinge
	world.add_child(node)
	return node


static func cannon(world: Node2D, position: Vector2, direction: float, node_name: String, delay: float = 0.0, cooldown: float = 2.6) -> WallCannon:
	var node := WallCannon.new()
	node.name = node_name
	node.direction = direction
	node.initial_delay = delay
	node.cooldown_time = cooldown
	node.position = position
	world.add_child(node)
	return node


static func catapult(world: Node2D, x: float, min_x: float, max_x: float, node_name: String, delay: float = 0.0) -> Catapult:
	var node := Catapult.new()
	node.name = node_name
	node.position = Vector2(x, GROUND)
	node.ground_y = GROUND
	node.min_x = min_x
	node.max_x = max_x
	node.initial_delay = delay
	world.add_child(node)
	return node


static func gravity_zone(world: Node2D, rect: Rect2, node_name: String) -> GravityZone:
	var node := GravityZone.new()
	node.name = node_name
	node.zone_size = rect.size
	node.position = rect.position + rect.size * 0.5
	world.add_child(node)
	return node


static func item(world: Node2D, kind: GrabItem.Kind, position: Vector2, node_name: String, respawn: float = 0.0) -> GrabItem:
	var node := GrabItem.new()
	node.name = node_name
	node.kind = kind
	node.respawn_time = respawn
	node.position = position
	world.add_child(node)
	return node


static func key(world: Node2D, position: Vector2, node_name: String) -> KeyPickup:
	var node := KeyPickup.new()
	node.name = node_name
	node.position = position
	world.add_child(node)
	return node


static func victory(world: Node2D, mode: VictoryCondition.Mode, node_name: String = "Victory", channel: String = "A") -> VictoryCondition:
	var node := VictoryCondition.new()
	node.name = node_name
	node.mode = mode
	node.channel = channel
	world.add_child(node)
	return node


## Marca un enemigo como parte de la arena (cuenta para `VictoryCondition.ENEMIES`).
static func arena(enemy: Node) -> void:
	enemy.add_to_group("arena_enemies", true)
