extends PlayerState
@export var respawn_delay: float = 0.65
var requested_respawn: bool = false

func enter() -> void:
	player.attack_machine.change_state(&"Disabled")
	player.velocity = Vector2.ZERO
	remaining = respawn_delay
	requested_respawn = false

func physics_update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0 and not requested_respawn:
		requested_respawn = true
		player.respawn_requested.emit()
