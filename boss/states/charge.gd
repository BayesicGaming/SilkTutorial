extends BossState

func enter() -> void:
	remaining = boss.hitbox.attack.active_time
	boss.hitbox.begin_swing()

func physics_update(delta: float) -> void:
	remaining -= delta
	boss.velocity.x = boss.facing * boss.charge_speed
	if remaining <= 0.0 or boss.is_on_wall():
		machine.change_state(&"Recovery")

func exit() -> void:
	boss.hitbox.end_swing()
