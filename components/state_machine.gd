class_name StateMachine
extends Node
## One current child state. The actor controls tick order explicitly.
signal state_changed(previous: StringName, current: StringName)
var current: ActorState
var current_name: StringName:
	get:
		return current.name if current != null else &""
var states: Dictionary[StringName, ActorState] = {}
var changing: bool = false

func initialize(actor: Node, initial_state: StringName = &"") -> void:
	for child in get_children():
		assert(child is ActorState, "StateMachine children must use ActorState scripts.")
		states[child.name] = child
		child.machine = self
		child.setup(actor)
	if initial_state != &"":
		change_state(initial_state)

func change_state(next: StringName, restart: bool = false) -> void:
	assert(not changing, "Request transitions from update, not this machine's enter/exit hooks.")
	assert(states.has(next), "Unknown state: " + str(next))
	if current_name == next and not restart:
		return
	var previous := current_name
	changing = true
	if current != null:
		current.exit()
	current = states[next]
	current.enter()
	changing = false
	state_changed.emit(previous, current_name)

func physics_update(delta: float) -> void:
	if current != null:
		current.physics_update(delta)

func after_move() -> void:
	if current != null:
		current.after_move()
