class_name ExitPortal
extends Area2D
## Meta del nivel. Siempre está disponible: al tocarla se muestra el resumen
## de la partida y se avanza al siguiente nivel.

signal reached

## Portal bloqueado (2026-11-24): una `VictoryCondition` lo cierra hasta cumplirse.
var locked: bool = false
var _used: bool = false
var _time: float = 0.0

@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("exit_portals")
	body_entered.connect(_on_body_entered)
	# Aura 2026-11-11: partículas cian ascendentes alrededor del portal.
	Fx.make_portal_aura(self, Vector2(0.0, 10.0), Color(0.16, 0.88, 1.0, 0.75))


func _process(delta: float) -> void:
	_time += delta
	visual.scale = Vector2.ONE * (1.0 + sin(_time * 2.0) * 0.035)
	visual.modulate.a = 0.85 + sin(_time * 3.0) * 0.15


func set_locked(value: bool) -> void:
	locked = value
	modulate = Color(0.45, 0.45, 0.5, 1.0) if value else Color.WHITE
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
