extends PlayerState

func enter() -> void:
	remaining = player.hitbox.attack.active_time
	player.hitbox.begin_swing()

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		machine.change_state(&"Recovery")

func exit() -> void:
	# Runs on normal completion AND damage/death interruption.
	player.hitbox.end_swing()
