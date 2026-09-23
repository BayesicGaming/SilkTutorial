class_name HitboxComponent
extends Area2D
## Monitoring stays on; enabled controls the damaging window.
## Polling overlaps also catches targets already touching at swing start.
signal hit_landed(target: HurtboxComponent)
@export var attack: AttackData
var enabled: bool = false
var hit_targets: Array[HurtboxComponent] = []

func begin_swing() -> void:
	hit_targets.clear()
	enabled = true

func end_swing() -> void:
	enabled = false

func _physics_process(_delta: float) -> void:
	if not enabled or attack == null:
		return
	for area in get_overlapping_areas():
		if area is HurtboxComponent and not hit_targets.has(area):
			var direction := signf(area.global_position.x - get_parent().global_position.x)
			if is_zero_approx(direction):
				direction = 1.0
			var impulse := Vector2(direction * attack.knockback, -attack.knockback_lift)
			if area.receive_hit(attack.damage, impulse):
				hit_targets.append(area)
				hit_landed.emit(area)
				get_node("/root/Feedback").impact(area.global_position, attack.hit_stop)
