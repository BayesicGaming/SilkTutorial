extends BossState

func enter() -> void:
	remaining = boss.hitbox.attack.startup

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		machine.change_state(boss.attack_states[boss.current_attack])
