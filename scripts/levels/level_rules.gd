class_name LevelRules
extends RefCounted
## Cambios de reglas por nivel (2026-11-23). Los niveles los aplican desde su
## generador sobre el jugador de la escena; cada uno trabaja sobre una COPIA
## de `PlayerStats`, así el recurso compartido no se contamina entre niveles.

## Sin impulso: anula el impulso (Ctrl). Ningún nivel lo usa ahora (el 30 lo
## tuvo hasta 2026-11-24 y se retiró).
static func no_dash(player: Player) -> void:
	if player == null:
		return
	var stats := player.stats.duplicate() as PlayerStats
	stats.dash_speed = 0.0
	stats.dash_time = 0.05
	stats.dash_cooldown = 9999.0
	player.stats = stats


## Baja gravedad: `gravity_factor` multiplica la gravedad y `jump_factor` la
## altura del salto (con la mitad de gravedad y 1,6x de altura el salto sube
## ~200 px y se queda más tiempo en el aire).
static func low_gravity(player: Player, gravity_factor: float = 0.5, jump_factor: float = 1.6) -> void:
	if player == null:
		return
	var stats := player.stats.duplicate() as PlayerStats
	stats.gravity *= gravity_factor
	stats.jump_hold_acceleration *= gravity_factor
	stats.jump_height *= jump_factor
	stats.max_fall_speed *= 0.75
	player.stats = stats

