extends PlayerState

func enter() -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(axis):
		player.facing = signf(axis)
	remaining = player.hitbox.attack.startup

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		machine.change_state(&"Active")
