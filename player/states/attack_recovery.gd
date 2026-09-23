extends PlayerState

func enter() -> void:
	remaining = player.hitbox.attack.recovery

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		machine.change_state(&"Ready")
