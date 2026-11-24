class_name RunTimer
extends RefCounted
## Cronómetro de la fase contrarreloj (2026-11-17). Separa el tiempo real
## transcurrido (`elapsed`) de la cuenta regresiva visible (`remaining`) para
## que las medallas no se vean afectadas por recompensas de tiempo ni por
## reapariciones. La pausa se gestiona fuera: al pausar el árbol no se llama a
## `tick()`, por lo que ambos contadores quedan congelados.

var limit: float = 0.0
var remaining: float = 0.0
var elapsed: float = 0.0
var running: bool = false
var expired: bool = false


func start(time_limit: float) -> void:
	limit = maxf(0.0, time_limit)
	remaining = limit
	elapsed = 0.0
	running = true
	expired = false


func tick(delta: float) -> void:
	if not running or expired:
		return
	var step := maxf(0.0, delta)
	elapsed += step
	remaining = maxf(0.0, remaining - step)
	if remaining <= 0.0:
		remaining = 0.0
		expired = true
		running = false


func reset_countdown() -> void:
	## Reaparición (2026-11-17): la cuenta regresiva vuelve al límite completo;
	## el tiempo real (`elapsed`, base de la medalla) sigue acumulándose.
	remaining = limit
	expired = false
	running = true


func stop() -> void:
	running = false


func set_remaining(seconds: float) -> void:
	## Utilidad para pruebas y depuración: no modifica el tiempo transcurrido.
	remaining = clampf(seconds, 0.0, limit)


func set_elapsed(seconds: float) -> void:
	## Utilidad para probar umbrales de medallas sin esperar segundos reales.
	elapsed = maxf(0.0, seconds)
