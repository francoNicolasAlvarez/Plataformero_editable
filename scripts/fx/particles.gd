class_name Fx
extends RefCounted
## Fábrica central de efectos visuales (2026-11-11): partículas procedurales
## para el polvo del jugador, las chispas de la hierba curativa y el aura del
## portal de salida. Todo se configura por código reutilizando una única
## textura de punto blanco (assets/fx/spark.svg).

const SPARK_TEXTURE := preload("res://assets/fx/spark.svg")


static func make_dust(parent: Node2D, offset: Vector2 = Vector2.ZERO) -> CPUParticles2D:
	## Nube de polvo de un solo disparo (aterrizar/saltar del jugador).
	## Se reutiliza llamando restart() cada vez que hace falta.
	var dust := _make(parent, offset)
	dust.name = "DustPuff"
	dust.one_shot = true
	dust.emitting = false
	dust.amount = 9
	dust.lifetime = 0.4
	dust.explosiveness = 0.95
	dust.direction = Vector2(0.0, -1.0)
	dust.spread = 85.0
	dust.gravity = Vector2(0.0, 240.0)
	dust.initial_velocity_min = 50.0
	dust.initial_velocity_max = 120.0
	dust.scale_amount_min = 1.4
	dust.scale_amount_max = 3.0
	dust.color_ramp = _fade(Color(0.85, 0.8, 0.68, 0.8), 0.25)
	return dust


static func make_sparkle(parent: Node2D, offset: Vector2, color: Color) -> CPUParticles2D:
	## Destello suave y continuo (hierba curativa).
	var sparkle := _make(parent, offset)
	sparkle.name = "Sparkle"
	sparkle.amount = 2
	sparkle.lifetime = 0.8
	sparkle.preprocess = 0.6
	sparkle.explosiveness = 0.15
	sparkle.direction = Vector2(0.0, -1.0)
	sparkle.spread = 180.0
	sparkle.gravity = Vector2(0.0, -14.0)
	sparkle.initial_velocity_min = 6.0
	sparkle.initial_velocity_max = 24.0
	sparkle.scale_amount_min = 0.7
	sparkle.scale_amount_max = 1.6
	sparkle.color_ramp = _fade(color, 0.15)
	return sparkle


static func make_burst(parent: Node2D, position: Vector2, color: Color) -> void:
	## Estallido de un solo uso colocado en el mundo; el nodo se libera solo.
	## El padre debe ser un nodo que sobreviva al recolector (p.ej. el nivel),
	## no el propio objeto que va a liberarse.
	var burst := _make(parent, position)
	burst.name = "SparkBurst"
	burst.one_shot = true
	burst.amount = 14
	burst.lifetime = 0.5
	burst.explosiveness = 1.0
	burst.direction = Vector2(0.0, -1.0)
	burst.spread = 180.0
	burst.gravity = Vector2(0.0, 320.0)
	burst.initial_velocity_min = 90.0
	burst.initial_velocity_max = 220.0
	burst.scale_amount_min = 1.0
	burst.scale_amount_max = 2.4
	burst.color_ramp = _fade(color, 0.3)
	_auto_free(burst, 1.2)


static func make_portal_aura(parent: Node2D, offset: Vector2, color: Color) -> CPUParticles2D:
	## Aura ascendente y continua alrededor del portal de salida.
	var aura := _make(parent, offset)
	aura.name = "PortalAura"
	aura.amount = 14
	aura.lifetime = 1.2
	aura.preprocess = 1.0
	aura.explosiveness = 0.1
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	aura.emission_rect_extents = Vector2(30.0, 44.0)
	aura.direction = Vector2(0.0, -1.0)
	aura.spread = 25.0
	aura.gravity = Vector2(0.0, -46.0)
	aura.initial_velocity_min = 28.0
	aura.initial_velocity_max = 70.0
	aura.tangential_accel_min = 26.0
	aura.tangential_accel_max = 60.0
	aura.scale_amount_min = 1.2
	aura.scale_amount_max = 2.8
	aura.color_ramp = _fade(color, 0.25)
	return aura


static func make_fire_trail(parent: Node2D, offset: Vector2 = Vector2.ZERO) -> CPUParticles2D:
	## Estela de llamas continua alrededor de una bola de fuego en vuelo.
	## Es omnidireccional (spread 180 con gravedad hacia arriba) para que el
	## giro del proyectil no afecte al resultado: las llamas suben siempre.
	return _make_trail(parent, offset, _fire_ramp())


static func make_sentry_trail(parent: Node2D, offset: Vector2 = Vector2.ZERO) -> CPUParticles2D:
	## Estela roja de las descargas del centinela del nivel 6.
	return _make_trail(parent, offset, _sentry_ramp())


static func apply_fire_trail(trail: CPUParticles2D) -> void:
	if trail != null:
		trail.color_ramp = _fire_ramp()


static func apply_sentry_trail(trail: CPUParticles2D) -> void:
	if trail != null:
		trail.color_ramp = _sentry_ramp()


static func _make_trail(parent: Node2D, offset: Vector2, ramp: Gradient) -> CPUParticles2D:
	var flame := _make(parent, offset)
	flame.name = "FlameTrail"
	flame.amount = 10
	flame.lifetime = 0.32
	flame.explosiveness = 0.0
	flame.direction = Vector2(1.0, 0.0)
	flame.spread = 180.0
	flame.gravity = Vector2(0.0, -70.0)
	flame.initial_velocity_min = 8.0
	flame.initial_velocity_max = 26.0
	flame.scale_amount_min = 0.5
	flame.scale_amount_max = 1.4
	flame.color_ramp = ramp
	return flame


static func _make(parent: Node2D, offset: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = SPARK_TEXTURE
	particles.position = offset
	parent.add_child(particles)
	return particles


static func _fade(color: Color, min_alpha: float = 0.0) -> Gradient:
	## Degradado del color dado a transparente; se construye a mano porque un
	## Gradient recién creado puede traer puntos por defecto distintos.
	var ramp := Gradient.new()
	var start := Color(color.r, color.g, color.b, maxf(color.a, 0.01))
	var end := Color(color.r, color.g, color.b, min_alpha)
	if ramp.get_point_count() >= 2:
		ramp.set_offset(0, 0.0)
		ramp.set_color(0, start)
		ramp.set_offset(1, 1.0)
		ramp.set_color(1, end)
	else:
		ramp.add_point(0.0, start)
		ramp.add_point(1.0, end)
	return ramp


static func _fire_ramp() -> Gradient:
	## Cian -> azul -> azul profundo transparente (energia del mago).
	## Se asignan offsets/colors completos porque remove_point no permite
	## vaciar el degradado (siempre queda 1 punto como mínimo).
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.82, 0.96, 1.0, 0.95),
		Color(0.33, 0.78, 1.0, 0.8),
		Color(0.09, 0.32, 0.83, 0.0),
	])
	return ramp


static func _sentry_ramp() -> Gradient:
	## Blanco -> rojo -> rojo oscuro transparente (descarga del centinela).
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 0.92, 0.7, 0.95),
		Color(1.0, 0.32, 0.12, 0.8),
		Color(0.55, 0.03, 0.02, 0.0),
	])
	return ramp


static func _auto_free(node: Node, delay: float) -> void:
	var tree := node.get_tree()
	if tree == null:
		return
	tree.create_timer(delay).timeout.connect(
		func() -> void:
			if is_instance_valid(node):
				node.queue_free()
	)
