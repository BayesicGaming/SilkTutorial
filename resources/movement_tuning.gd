class_name MovementTuning
extends Resource
## Shared tuning data. Runtime timers and velocity belong to the player, not here.
@export_group("Run")
@export var max_speed: float = 285.0
@export var ground_acceleration: float = 2200.0
@export var ground_deceleration: float = 2600.0
@export var turn_acceleration: float = 3600.0
@export var air_acceleration: float = 1500.0
@export var air_deceleration: float = 650.0
@export_group("Jump")
@export var jump_velocity: float = -570.0
@export var gravity: float = 1450.0
@export var fall_multiplier: float = 1.55
@export var terminal_velocity: float = 850.0
@export var released_jump_speed: float = 220.0
@export var coyote_time: float = 0.11
@export var jump_buffer_time: float = 0.12
@export_group("Combat")
@export var attack_move_multiplier: float = 0.72
@export var knockback_strength: float = 330.0
@export var knockback_lift: float = 220.0
@export var knockback_recovery: float = 0.18
