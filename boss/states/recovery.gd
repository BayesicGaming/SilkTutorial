extends BossState

func enter() -> void:
	remaining = boss.hitbox.attack.recovery

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		machine.change_state(&"Idle")
