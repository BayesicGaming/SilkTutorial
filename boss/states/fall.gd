extends BossState

func enter() -> void:
	boss.velocity.y = boss.slam_fall_speed

func physics_update(_delta: float) -> void:
	if boss.is_on_floor():
		machine.change_state(&"Impact")
