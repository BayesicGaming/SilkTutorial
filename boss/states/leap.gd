extends BossState
var horizontal_speed: float = 0.0

func enter() -> void:
	boss.velocity.y = -boss.jump_speed
	horizontal_speed = (boss.target_x - boss.global_position.x) / (boss.jump_speed / boss.gravity)

func physics_update(_delta: float) -> void:
	boss.velocity.x = horizontal_speed
	if boss.velocity.y >= 0.0:
		machine.change_state(&"Fall")
