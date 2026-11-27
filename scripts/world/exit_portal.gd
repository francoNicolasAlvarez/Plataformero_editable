class_name ExitPortal
extends Area2D
## Meta del nivel. Siempre está disponible: al tocarla se muestra el resumen
## de la partida y se avanza al siguiente nivel.

signal reached

## Portal bloqueado (2026-11-24): una `VictoryCondition` lo cierra hasta cumplirse.
var locked: bool = false
var _used: bool = false
var _time: float = 0.0
var _lock: Node2D

@onready var visual: Node2D = $Visual


func _ready() -> void:
	DrawLayers.behind_ground(self)  # base tapada por el suelo (2026-11-27)
	add_to_group("exit_portals")
	body_entered.connect(_on_body_entered)
	# Aura 2026-11-11: partículas cian ascendentes alrededor del portal.
	Fx.make_portal_aura(self, Vector2(0.0, 10.0), Color(0.16, 0.88, 1.0, 0.75))


func _process(delta: float) -> void:
	_time += delta
	visual.scale = Vector2.ONE * (1.0 + sin(_time * 2.0) * 0.035)
	visual.modulate.a = 0.85 + sin(_time * 3.0) * 0.15


func set_locked(value: bool) -> void:
	var was_locked := locked
	locked = value
	# Solo se tiñe el dibujo del portal (`Visual`): el candado, hijo del portal,
	# no hereda el gris y se ve con su color.
	var tint := Color(0.45, 0.45, 0.5) if value else Color.WHITE
	visual.modulate = Color(tint.r, tint.g, tint.b, visual.modulate.a)
	# Candado (2026-11-27): el bloqueo no depende solo del color gris (guía de
	# diseño, accesibilidad). Al abrirse salta y se desvanece con un destello.
	if value:
		_ensure_lock().visible = true
		_lock.modulate = Color.WHITE
		_lock.scale = Vector2.ONE
	elif was_locked and _lock != null:
		var tween := create_tween()
		tween.tween_property(_lock, "scale", Vector2(1.5, 1.5), 0.25)
		tween.parallel().tween_property(_lock, "modulate:a", 0.0, 0.35)
		tween.tween_callback(_lock.hide)
		var parent := get_parent() as Node2D
		if parent != null:
			Fx.make_burst(parent, global_position, Color(1.0, 0.85, 0.3))
	# Reactivar la vigilancia vuelve a avisar de un jugador que ya esté dentro.
	set_deferred("monitoring", false)
	set_deferred("monitoring", true)


func _on_body_entered(body: Node2D) -> void:
	if _used or locked or not body is Player:
		return
	_used = true
	set_deferred("monitoring", false)
	Sfx.play("portal", -5.0)
	reached.emit()


func is_lock_visible() -> bool:
	return _lock != null and _lock.visible


func _ensure_lock() -> Node2D:
	## Candado dorado con contorno negro sobre el núcleo del portal. Va fuera de
	## `Visual` para no heredar su pulso ni su tinte gris.
	if _lock != null:
		return _lock
	_lock = Node2D.new()
	_lock.name = "Lock"
	_lock.position = Vector2(0.0, 4.0)
	_lock.z_index = 2
	add_child(_lock)
	var shackle := Line2D.new()
	shackle.name = "Shackle"
	shackle.width = 5.0
	shackle.default_color = Color("#1b1b22")
	for i in 9:
		var angle := PI + PI * float(i) / 8.0
		shackle.add_point(Vector2(cos(angle) * 10.0, -8.0 + sin(angle) * 12.0))
	_lock.add_child(shackle)
	var inner := shackle.duplicate() as Line2D
	inner.width = 2.5
	inner.default_color = Color("#c9cbd6")
	_lock.add_child(inner)
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = Color("#f2c440")
	body.polygon = PackedVector2Array([Vector2(-15, -8), Vector2(15, -8), Vector2(15, 14), Vector2(-15, 14)])
	_lock.add_child(body)
	var outline := Line2D.new()
	outline.width = 2.5
	outline.default_color = Color.BLACK
	outline.closed = true
	outline.points = body.polygon
	body.add_child(outline)
	var hole := Polygon2D.new()
	hole.color = Color("#1b1b22")
	hole.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(2, 9), Vector2(-2, 9)])
	_lock.add_child(hole)
	return _lock

