extends PlayerState

func enter() -> void:
	remaining = player.movement.knockback_recovery
	player.attack_machine.change_state(&"Disabled")

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		var next := &"Grounded" if player.is_on_floor() else &"Airborne"
		machine.change_state(next)
		# Steering resumes on this tick, not one tick after recovery expires.
		machine.physics_update(delta)
		return
	player.apply_gravity(delta)
