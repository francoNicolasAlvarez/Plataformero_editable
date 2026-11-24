class_name PlayerStats
extends Resource
## Estadísticas base del personaje.
## Al ser un Resource se puede crear una variante por personaje o mejorarla
## desde el campamento sin tocar el script del controlador.

@export_group("Movimiento horizontal")
@export_range(0.0, 1000.0, 1.0) var max_speed: float = 266.0
@export_range(0.0, 1500.0, 1.0) var run_speed: float = 532.0
@export_range(0.0, 10000.0, 10.0) var acceleration: float = 1400.0
@export_range(0.0, 10000.0, 10.0) var deceleration: float = 1700.0
@export_range(0.0, 20000.0, 10.0) var turn_acceleration: float = 2400.0
@export_range(0.0, 10000.0, 10.0) var air_acceleration: float = 850.0
@export_range(0.0, 10000.0, 10.0) var air_deceleration: float = 450.0

@export_group("Salto y gravedad")
@export_range(0.0, 5000.0, 10.0) var gravity: float = 1450.0
@export_range(0.0, 3.0, 0.05) var fall_gravity_multiplier: float = 1.35
@export_range(0.0, 500.0, 1.0) var jump_height: float = 125.0
@export_range(0.0, 2000.0, 10.0) var max_fall_speed: float = 900.0
@export_range(0.0, 3000.0, 10.0) var fast_fall_speed: float = 900.0
@export_range(0.0, 1.0, 0.01) var jump_cut_multiplier: float = 0.45
@export_range(1, 4, 1) var max_jumps: int = 1
@export_range(0.0, 1.0, 0.01) var jump_hold_time: float = 0.25
@export_range(0.0, 2000.0, 5.0) var jump_hold_acceleration: float = 385.0
@export_range(0.0, 0.5, 0.01) var coyote_time: float = 0.10
@export_range(0.0, 0.5, 0.01) var jump_buffer_time: float = 0.12

@export_group("Impulso")
@export_range(0.0, 2500.0, 10.0) var dash_speed: float = 1140.0
@export_range(0.05, 0.6, 0.01) var dash_time: float = 0.135
@export_range(0.0, 2.0, 0.05) var dash_cooldown: float = 0.4

@export_group("Combate")
@export_range(0.0, 5.0, 0.05) var invulnerability_time: float = 0.5
@export_range(0.0, 1000.0, 10.0) var knockback_force: float = 260.0
@export_range(0.0, 1000.0, 10.0) var knockback_up_force: float = 220.0
