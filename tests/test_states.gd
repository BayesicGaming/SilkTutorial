extends SceneTree
## FSM lifecycle plus real actor transitions/interruption boundaries.
var checks: int = 0
var failures: int = 0

class RecordingState extends ActorState:
	var trace: Array[String]
	func enter() -> void:
		trace.append(str(name) + ".enter")
	func physics_update(_delta: float) -> void:
		trace.append(str(name) + ".update")
	func exit() -> void:
		trace.append(str(name) + ".exit")

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func run() -> void:
	var trace: Array[String] = []
	var machine := StateMachine.new()
	root.add_child(machine)
	for label in ["First", "Second"]:
		var state := RecordingState.new()
		state.name = label
		state.trace = trace
		machine.add_child(state)
	machine.initialize(root, &"First")
	check(trace == ["First.enter"], "initialization enters exactly one state")
	machine.physics_update(0.1)
	check(trace == ["First.enter", "First.update"], "only the current state receives a tick")
	trace.clear()
	machine.state_changed.connect(func(previous, next): trace.append(str(previous) + ">" + str(next)))
	machine.change_state(&"Second")
	check(trace == ["First.exit", "Second.enter", "First>Second"], "transition exits, enters, then announces")
	trace.clear()
	machine.change_state(&"Second")
	check(trace.is_empty(), "same-state selection does not restart accidentally")
	machine.change_state(&"Second", true)
	check(trace == ["Second.exit", "Second.enter", "Second>Second"], "explicit restart reruns lifecycle hooks")

	var lab: Node2D = load("res://tests/movement_lab.tscn").instantiate()
	root.add_child(lab)
	var player: Player = lab.get_node("Player")
	await frames(4)
	check(player.motion_machine.current_name == &"Grounded", "landing enters Grounded")
	Input.action_press("jump")
	Input.action_press("attack")
	await frames(8)
	Input.action_release("attack")
	check(player.motion_machine.current_name == &"Airborne" and player.attack_phase == &"Active", "movement and attack states run concurrently")
	check(player.hitbox.enabled, "Active entry enables the player hitbox")
	player.health.take_damage(1, Vector2(200, -100))
	check(player.motion_machine.current_name == &"Hurt" and player.attack_phase == &"Disabled", "damage switches motion and disables attack input")
	check(not player.hitbox.enabled, "interrupting Active calls exit and clears hitbox")
	Input.action_release("jump")
	Input.action_press("move_left")
	Input.action_press("attack")
	await frames(3)
	check(player.velocity.x > 0 and not player.attacking, "Hurt blocks steering and new attacks")
	Input.action_release("move_left")
	Input.action_release("attack")
	await frames(20)
	check(player.motion_machine.current_name != &"Hurt" and player.attack_phase == &"Ready", "recovery restores movement and Ready")
	await frames(50)
	check(player.motion_machine.current_name == &"Grounded", "air recovery eventually lands normally")
	Input.action_press("jump")
	await frames(10)
	Input.action_release("jump")
	await frames(2)
	var vertical_speed := player.velocity.y
	Input.action_press("jump")
	await frames(1)
	check(player.velocity.y >= vertical_speed, "refactor does not silently add a double jump")
	Input.action_release("jump")

	# Exercise death from each offensive phase; all must cancel safely.
	for phase in [&"Startup", &"Active", &"Recovery"]:
		var victim: Player = load("res://player/player.tscn").instantiate()
		victim.position = Vector2(800, 560)
		lab.add_child(victim)
		victim.attack_machine.change_state(phase)
		victim.health.take_damage(99)
		check(victim.dead and victim.attack_phase == &"Disabled" and not victim.hitbox.enabled,
			"player death cancels " + str(phase))
		victim.queue_free()
	await frames(2)

	var boss: KilnBoss = load("res://boss/boss.tscn").instantiate()
	boss.position = Vector2(750, 560)
	lab.add_child(boss)
	check(not boss.active and boss.state == &"", "boss machine waits for encounter activation")
	boss.activate()
	check(boss.state == &"Idle", "activation enters boss Idle")
	for state_name in [&"Sweep", &"Impact", &"Charge"]:
		boss.state_machine.change_state(state_name)
		check(boss.hitbox.enabled, str(state_name) + " entry starts a swing")
		boss.state_machine.change_state(&"Recovery")
		check(not boss.hitbox.enabled, str(state_name) + " exit clears damage")
	boss.state_machine.change_state(&"Charge")
	var victories := [0]
	boss.defeated.connect(func(): victories[0] += 1)
	boss.health.take_damage(99)
	check(boss.dead and not boss.active and not boss.hitbox.enabled and victories[0] == 1,
		"boss death interrupts Charge and announces defeat once")
	boss.activate()
	boss.choose_attack()
	check(boss.dead and victories[0] == 1, "dead boss cannot restart its encounter")
	print("STATES: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
