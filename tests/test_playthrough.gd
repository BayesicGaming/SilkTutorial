extends SceneTree
## A deterministic action-driven route. No teleport, health cheats or direct damage.
var game
var state: Node
var failures: int = 0
var checks: int = 0
var tick: int = 0
var seen_attacks: Dictionary = {}
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame
		tick += 1
func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)
func steer(axis: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if axis < 0:
		Input.action_press("move_left")
	elif axis > 0:
		Input.action_press("move_right")
func walk_to(x: float, limit: int = 240) -> bool:
	for frame in range(limit):
		var difference: float = x - game.player.position.x
		if absf(difference) < 7.0:
			steer(0)
			await frames(8)
			return true
		steer(signf(difference))
		await frames(1)
	steer(0)
	return false
func jump_to(x: float, landing_height: float) -> bool:
	var jump_direction: float = signf(x - game.player.position.x)
	Input.action_press("jump")
	for frame in range(60):
		steer(jump_direction if (x - game.player.position.x) * jump_direction > 6 else 0.0)
		await frames(1)
		if frame > 10 and game.player.is_on_floor():
			Input.action_release("jump")
			steer(0)
			await frames(8)
			return absf(game.player.position.y - landing_height) < 2
	Input.action_release("jump")
	steer(0)
	return false
func jump_to_upper_room() -> bool:
	steer(0)
	Input.action_press("jump")
	for frame in range(60):
		await frames(1)
		if state.room_index == 1:
			Input.action_release("jump")
			await frames(8)
			return true
	Input.action_release("jump")
	return false
func reach_next_room(destination: int) -> bool:
	steer(1)
	for frame in range(400):
		await frames(1)
		if state.room_index == destination:
			steer(0)
			await frames(8)
			return true
	steer(0)
	return false
func tap_event(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
func fight_boss() -> bool:
	var jump_held: int = 0
	for frame in range(18000):
		if state.victory:
			steer(0)
			Input.action_release("attack")
			Input.action_release("jump")
			return true
		if game.player.dead:
			return false
		var boss = game.room.get_node("Enemies/Boss")
		if boss.state == &"Windup":
			seen_attacks[boss.current_attack] = true
		var distance: float = boss.position.x - game.player.position.x
		var desired_x: float = boss.position.x - signf(distance) * 57.0
		var slam_warning: bool = boss.current_attack == boss.Attack.SLAM and boss.state in [&"Windup", &"Leap", &"Fall", &"Impact"]
		if slam_warning:
			var escape_side: float = -1 if game.player.position.x < boss.target_x else 1
			if boss.target_x < 290:
				escape_side = 1
			elif boss.target_x > 1150:
				escape_side = -1
			desired_x = boss.target_x + escape_side * 240
		steer(signf(desired_x - game.player.position.x) if absf(desired_x - game.player.position.x) > 9 else 0)
		var should_jump: bool = boss.state == &"Windup" and boss.current_attack != boss.Attack.SLAM and boss.state_remaining < 0.22 and absf(distance) < 210
		should_jump = should_jump or (boss.state == &"Charge" and absf(distance) < 210)
		if should_jump and game.player.is_on_floor() and jump_held == 0:
			Input.action_press("jump")
			jump_held = 35
		if jump_held > 0:
			jump_held -= 1
		else:
			Input.action_release("jump")
		Input.action_release("attack")
		if frame % 26 == 0 and absf(distance) < 80 and not slam_warning:
			Input.action_press("attack")
		await frames(1)
	return false
func run() -> void:
	state = root.get_node("GameState")
	state.reset_run()
	game = load("res://game.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	check(await reach_next_room(1), "action-only route crosses room 1")
	check(await walk_to(620), "walk to junction opening")
	check(await jump_to(860, 740) and state.room_index == 1, "jump across junction opening without taking down exit")
	check(await reach_next_room(2), "junction right branch is reachable before collecting key")
	check(await walk_to(1270, 450), "reach locked gate before taking lower branch")
	await tap_event("interact")
	await frames(6)
	check(state.room_index == 2 and not state.door_unlocked, "gate remains locked without lower-room key")
	steer(-1)
	for frame in range(400):
		await frames(1)
		if state.room_index == 1:
			break
	steer(0)
	check(state.room_index == 1, "backtrack from gate to junction")
	steer(-1)
	for frame in range(240):
		await frames(1)
		if state.room_index == 4:
			break
	steer(0)
	await frames(8)
	check(state.room_index == 4 and game.player.is_on_floor(), "walk into opening and arrive safely in lower room")
	check(await walk_to(1030), "walk off top ledge toward bottom key")
	await frames(75)
	check(await walk_to(1030) and state.has_key and game.player.is_on_floor(), "collect key at bottom using movement only")
	check(await walk_to(680), "walk beside first solid ledge")
	check(await jump_to(580, 650), "jump left onto lowest well ledge")
	for step in range(5):
		var heading_right: bool = step % 2 == 0
		check(await walk_to(620 if heading_right else 740), "approach well ledge edge %d" % (step + 1))
		check(await jump_to(780 if heading_right else 580, 570 - step * 80), "climb alternating well ledge %d" % (step + 2))
	check(await walk_to(800), "stand beneath the up exit")
	check(await jump_to_upper_room(), "jump into up exit to return to junction")
	check(game.current_spawn == &"FromWell" and state.has_key, "return beside junction opening with key")
	check(await reach_next_room(2), "carry key into room 3")
	check(await walk_to(1270, 450), "cross room 3 to sealed door")
	await tap_event("interact")
	await frames(6)
	check(state.room_index == 3, "interaction enters boss encounter")
	if failures == 0:
		check(await fight_boss(), "action-only combat defeats boss and reaches victory")
		check(seen_attacks.size() == 3, "natural boss cycle executes all three attack choices")
		print("Playthrough simulation time: ", tick / 60.0, " seconds; remaining health: ", game.player.health.current_health)
		await tap_event("restart")
		await frames(5)
		check(state.room_index == 0 and not state.victory and not state.has_key and not state.door_unlocked, "victory restart resets the whole run")
	else:
		check(false, "boss route skipped after traversal failure")
	print("PLAYTHROUGH: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
