class_name PlayerState
extends ActorState
## A typed context shared by player states, not a second player controller.
var player: Player

func setup(actor: Node) -> void:
	player = actor as Player
