class_name BossState
extends ActorState
var boss: KilnBoss

func setup(actor: Node) -> void:
	boss = actor as KilnBoss
