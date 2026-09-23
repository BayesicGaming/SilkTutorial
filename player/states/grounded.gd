extends PlayerState

func enter() -> void:
	player.resume_attacks()
	# An exercise could reset its available air jumps here, on landing.

func physics_update(delta: float) -> void:
	player.steer(delta, true)
	if player.try_buffered_jump():
		machine.change_state(&"Airborne")

func after_move() -> void:
	if not player.is_on_floor():
		machine.change_state(&"Airborne")
