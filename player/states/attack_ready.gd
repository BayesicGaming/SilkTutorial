extends PlayerState

func physics_update(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		machine.change_state(&"Startup")
