class_name SpreadEnemy
extends RangedEnemy
## Enemigo común (antiguo jefe del nivel 1), rediseñado en 2026-11-11 como
## arquero con arco: dispara una sola flecha algo más rápida que la bola de
## fuego del mago.
## Cambio 2026-11: los jefes dejaron de bloquear el portal y se convirtieron
## en enemigos comunes que aparecen repartidos en los tres niveles.
## Cambio 2026-11-11 (visuales): ya no dispara abanicos de virotes; lanza una
## flecha horizontal por disparo (el abanico queda para el mago).


const BOW_MAX_PULL := 10.0


func _setup_telegraph() -> void:
	## Arquero: flecha encajada en el arco; al aproximarse el disparo la cuerda
	## se tensa hacia atrás y la punta brilla.
	var bow := get_node_or_null("Visual/Bow")
	if bow == null:
		return
	var arrow := Node2D.new()
	arrow.name = "NockedArrow"
	arrow.visible = false
	bow.add_child(arrow)
	var shaft := Polygon2D.new()
	shaft.name = "Shaft"
	shaft.color = Color("#d9c49a")
	shaft.polygon = PackedVector2Array([Vector2(0, -1), Vector2(24, -1), Vector2(24, 1), Vector2(0, 1)])
	arrow.add_child(shaft)
	var head := Polygon2D.new()
	head.name = "Head"
	head.color = Color("#cfd6df")
	head.polygon = PackedVector2Array([Vector2(24, -3), Vector2(31, 0), Vector2(24, 3)])
	arrow.add_child(head)
	var fletch := Polygon2D.new()
	fletch.name = "Fletching"
	fletch.color = Color("#c62828")
	fletch.polygon = PackedVector2Array([Vector2(0, -3), Vector2(5, -1), Vector2(5, 1), Vector2(0, 3)])
	arrow.add_child(fletch)
	var glow := EnergyCharge.new()
	glow.name = "TipGlow"
	glow.position = Vector2(30.0, 0.0)
	glow.max_radius = 12.0
	glow.core_max = 4.5
	glow.color = Color(1.0, 0.85, 0.3, 1.0)
	arrow.add_child(glow)


func _telegraph_update(progress: float) -> void:
	var bow := get_node_or_null("Visual/Bow")
	if bow == null:
		return
	var arrow := bow.get_node_or_null("NockedArrow") as Node2D
	var string := bow.get_node_or_null("BowString") as Polygon2D
	if arrow == null or string == null:
		return
	var pull := BOW_MAX_PULL * progress
	arrow.visible = true
	arrow.position = Vector2(-pull, 0.0)
	string.polygon = PackedVector2Array([Vector2(0, -14), Vector2(-pull + 1.0, 0), Vector2(0, 14), Vector2(-pull - 1.0, 0)])
	(arrow.get_node("TipGlow") as EnergyCharge).set_progress(progress)


func _telegraph_end() -> void:
	if not _telegraphing:
		return
	_telegraphing = false
	var bow := get_node_or_null("Visual/Bow")
	if bow == null:
		return
	var arrow := bow.get_node_or_null("NockedArrow") as Node2D
	if arrow != null:
		arrow.visible = false
		(arrow.get_node("TipGlow") as EnergyCharge).stop()
	var string := bow.get_node_or_null("BowString") as Polygon2D
	if string != null:
		string.polygon = PackedVector2Array([Vector2(0, -14), Vector2(1, 0), Vector2(0, 14), Vector2(-1, 0)])


func _shoot(direction: float) -> void:
	# Flecha única: mismo origen y lógica horizontal, pero un solo proyectil.
	var projectile := PROJECTILE_SCENE.instantiate()
	_projectile_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(direction * 40.0, -18.0)
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = 18
	projectile.velocity = Vector2(direction, 0.0) * projectile_speed
	projectile.rotation = 0.0 if direction > 0.0 else PI
	projectile.use_bolt_style()

	Sfx.play("arrow", -8.0)
