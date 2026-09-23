class_name HealthComponent
extends Node
## The one health implementation shared by every combatant.
signal health_changed(current: int, maximum: int)
signal damaged(amount: int, impulse: Vector2)
signal died

@export_range(1, 100) var max_health: int = 5
@export var invulnerability_duration: float = 0.12
var current_health: int
var invulnerability_remaining: float = 0.0

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)

func take_damage(amount: int, impulse: Vector2 = Vector2.ZERO) -> bool:
	if amount <= 0 or current_health <= 0 or invulnerability_remaining > 0.0:
		return false
	var applied := mini(amount, current_health)
	current_health -= applied
	invulnerability_remaining = invulnerability_duration
	health_changed.emit(current_health, max_health)
	damaged.emit(applied, impulse)
	if current_health == 0:
		died.emit()
	return true
