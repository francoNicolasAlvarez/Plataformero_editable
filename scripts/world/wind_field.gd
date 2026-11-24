class_name WindField
extends Node2D
## Viento del nivel (2026-11-17). Divide el recorrido en tramos con su propia
## dirección e intensidad; dentro de cada tramo el viento sopla a ráfagas
## (oscila entre el 40 % y el 100 % de su fuerza con periodo `gust_period`).
## Cada frame de física escribe `Player.wind_speed`. Dibuja rayas de viento en
## pantalla y una etiqueta con la dirección. Los tramos son diccionarios
## {"from": x, "to": x, "speed": px/s con signo}; fuera de ellos no hay viento.

@export var segments: Array[Dictionary] = []
@export var gust_period: float = 7.0
@export_range(0.0, 1.0, 0.05) var gust_min: float = 0.4
@export var show_effects: bool = true

var current_speed: float = 0.0

var _time: float = 0.0
var _layer: CanvasLayer
var _label: Label
var _streaks: Array[Line2D] = []
var _streak_offsets: Array[float] = []


func _ready() -> void:
	add_to_group("wind_fields")
	if show_effects:
		_build_effects()


func speed_at(x: float) -> float:
	## Fuerza del viento en la coordenada x, con la ráfaga actual aplicada.
	for segment in segments:
		if x >= float(segment["from"]) and x < float(segment["to"]):
			return float(segment["speed"]) * gust_factor()
	return 0.0


func gust_factor() -> float:
	var wave := 0.5 + 0.5 * sin(TAU * _time / maxf(gust_period, 0.1))
	return gust_min + (1.0 - gust_min) * wave


func _physics_process(delta: float) -> void:
	_time += delta
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	current_speed = 0.0 if player.health.is_dead else speed_at(player.global_position.x)
	player.wind_speed = current_speed


func _process(delta: float) -> void:
	if not show_effects or _layer == null:
		return
	var size := get_viewport().get_visible_rect().size
	var strength := clampf(absf(current_speed) / 140.0, 0.0, 1.0)
	_layer.visible = strength > 0.02
	if not _layer.visible:
		return
	var direction := signf(current_speed)
	_label.text = "VIENTO " + ("»»»" if direction > 0.0 else "«««")
	_label.modulate.a = 0.5 + 0.5 * strength
	for index in _streaks.size():
		var streak := _streaks[index]
		var length := 40.0 + 120.0 * strength
		_streak_offsets[index] += direction * (260.0 + 700.0 * strength) * delta
		var x := fposmod(_streak_offsets[index], size.x + 200.0) - 100.0
		var y := fposmod(float(index) * 97.0, size.y - 140.0) + 100.0
		streak.points = PackedVector2Array([Vector2(x, y), Vector2(x - direction * length, y)])
		streak.default_color = Color(1.0, 1.0, 1.0, 0.18 + 0.25 * strength)


func _build_effects() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 3
	add_child(_layer)
	_label = Label.new()
	_label.position = Vector2(24.0, 108.0)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color("#dff3ff"))
	_label.add_theme_color_override("font_outline_color", Color("#16303f"))
	_label.add_theme_constant_override("outline_size", 5)
	_layer.add_child(_label)
	for index in 22:
		var streak := Line2D.new()
		streak.width = 2.0
		_layer.add_child(streak)
		_streaks.append(streak)
		_streak_offsets.append(float(index) * 83.0)
