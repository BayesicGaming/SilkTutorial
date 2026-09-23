class_name ActorState
extends Node
## States do not process themselves. Their machine ticks only the current state.
var machine: StateMachine
var remaining: float = 0.0

func setup(_actor: Node) -> void:
	pass

func enter() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func after_move() -> void:
	pass

func exit() -> void:
	pass
