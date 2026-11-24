class_name Hazard
extends Node2D
## Base de los obstáculos con ciclo y aviso (Fase 4, 2026-11-18). Una máquina
## de estados común: IDLE -> WARNING (aviso legible) -> ACTIVE (peligro o
## efecto) -> COOLDOWN -> IDLE. Con `auto_cycle` el ciclo arranca solo tras
## `initial_delay`; si no, espera a `trigger()` (p. ej. al pisarlo).
## `reset()` devuelve el obstáculo a su estado inicial: `TestLevel` lo llama
## en cada muerte, igual que con enemigos y proyectiles.
## Las subclases solo reaccionan en `_on_state_entered()` y `_on_reset()`.

signal state_changed(new_state: int)

enum State { IDLE, WARNING, ACTIVE, COOLDOWN }

@export var warning_time: float = 1.0
@export var active_time: float = 1.2
@export var cooldown_time: float = 2.0
@export var initial_delay: float = 0.0
@export var auto_cycle: bool = true

var state: int = State.IDLE
var _state_time: float = 0.0
var _delay_left: float = 0.0


func _ready() -> void:
	add_to_group("hazards")
	_delay_left = initial_delay


func _physics_process(delta: float) -> void:
	tick(delta)


## Avanza la máquina de estados (público para poder probarla sin esperar).
func tick(delta: float) -> void:
	match state:
		State.IDLE:
			if auto_cycle:
				_delay_left -= delta
				if _delay_left <= 0.0:
					_set_state(State.WARNING)
		State.WARNING:
			_state_time += delta
			if _state_time >= warning_time:
				_set_state(State.ACTIVE)
		State.ACTIVE:
			_state_time += delta
			_on_active_tick(delta)
			if _state_time >= active_time:
				_set_state(State.COOLDOWN)
		State.COOLDOWN:
			_state_time += delta
			if _state_time >= cooldown_time:
				_set_state(State.IDLE)
				_delay_left = 0.0


## Arranca el ciclo manualmente (solo desde IDLE).
func trigger() -> void:
	if state == State.IDLE:
		_set_state(State.WARNING)


func reset() -> void:
	state = State.IDLE
	_state_time = 0.0
	_delay_left = initial_delay
	_on_reset()
	state_changed.emit(state)


## 0..1 durante el aviso, útil para animaciones.
func warning_progress() -> float:
	if state != State.WARNING:
		return 0.0
	return clampf(_state_time / maxf(warning_time, 0.001), 0.0, 1.0)


func _set_state(new_state: int) -> void:
	state = new_state
	_state_time = 0.0
	_on_state_entered(new_state)
	state_changed.emit(new_state)


func _on_state_entered(_new_state: int) -> void:
	pass


func _on_active_tick(_delta: float) -> void:
	pass


func _on_reset() -> void:
	pass
