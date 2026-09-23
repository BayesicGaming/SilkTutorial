extends PlayerState
## Hurt/Dead enter this state. Grounded/Airborne restore Ready when appropriate.
func enter() -> void:
	player.hitbox.end_swing()
