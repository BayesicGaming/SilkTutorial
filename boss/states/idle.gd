extends BossState

func enter() -> void:
	remaining = boss.idle_duration

func physics_update(delta: float) -> void:
	remaining -= delta
	var player := boss.find_player()
	if not is_instance_valid(player) or player.dead:
		return
	var distance := player.global_position.x - boss.global_position.x
	boss.facing = -1.0 if distance < 0.0 else 1.0
	if absf(distance) > 100.0:
		boss.velocity.x = boss.facing * boss.move_speed
	if remaining <= 0.0:
		boss.choose_attack()
