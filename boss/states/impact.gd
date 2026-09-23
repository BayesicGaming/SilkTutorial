extends BossState

func enter() -> void:
	remaining = boss.hitbox.attack.active_time
	boss.hitbox.begin_swing()
	boss.get_node("/root/Feedback").impact(boss.global_position, 0.025)

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		machine.change_state(&"Recovery")

func exit() -> void:
	boss.hitbox.end_swing()
