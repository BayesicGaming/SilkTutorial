extends BossState

func enter() -> void:
	boss.velocity = Vector2.ZERO
	boss.defeated.emit()
