extends PlayerState

func enter() -> void:
	player.resume_attacks()

func physics_update(delta: float) -> void:
	player.steer(delta, false)
	player.apply_gravity(delta)
	player.try_buffered_jump()
	# A future extra air jump belongs here, after trying the coyote jump.

func after_move() -> void:
	if player.is_on_floor():
		machine.change_state(&"Grounded")
