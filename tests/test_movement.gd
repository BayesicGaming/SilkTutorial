extends SceneTree
## Runs the real CharacterBody2D against the lab floor using named actions.
var lab: Node2D
var player: Player
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func reset_player() -> void:
	for action in ["move_left", "move_right", "jump", "attack"]:
		Input.action_release(action)
	player.position = Vector2(300, 560)
	player.velocity = Vector2.ZERO
	player.coyote_remaining = 0.0
	player.jump_buffer_remaining = 0.0
	await frames(3)

func jump_height(hold_frames: int) -> float:
	await reset_player()
	var start_y := player.position.y
	var minimum_y := start_y
	Input.action_press("jump")
	for frame in range(65):
		if frame == hold_frames:
			Input.action_release("jump")
		await frames(1)
		minimum_y = minf(minimum_y, player.position.y)
	return start_y - minimum_y

func run() -> void:
	lab = load("res://tests/movement_lab.tscn").instantiate()
	root.add_child(lab)
	player = lab.get_node("Player")
	await reset_player()
	check(player.is_on_floor(), "player settles on real floor")
	Input.action_press("move_right")
	await frames(2)
	check(player.velocity.x > 0.0 and player.velocity.x < player.movement.max_speed, "accelerates gradually")
	await frames(15)
	check(absf(player.velocity.x - player.movement.max_speed) < 1.0, "reaches configured max speed")
	Input.action_release("move_right")
	await frames(10)
	check(absf(player.velocity.x) < 1.0, "decelerates to rest")
	Input.action_press("move_right", 0.4)
	await frames(12)
	check(absf(player.velocity.x - player.movement.max_speed * 0.4) < 1.0, "analog action magnitude sets slower speed")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(8)
	check(player.velocity.x < 0.0 and player.facing == -1.0, "turns responsively")
	var full_height := await jump_height(40)
	check(full_height > 95.0 and full_height < 125.0, "full jump has expected trajectory")
	check(player.is_on_floor(), "jump returns to floor")
	var tap_height := await jump_height(2)
	check(tap_height < full_height * 0.65, "released jump produces lower apex")
	print("Measured jump heights: held=", full_height, " tap=", tap_height)

	# Walk over the physical edge, then press within/outside the grace window.
	for delay in [2, 10]:
		await reset_player()
		player.position.x = 997.0
		Input.action_press("move_right")
		while player.is_on_floor():
			await frames(1)
		await frames(delay)
		Input.action_press("jump")
		await frames(1)
		check((player.velocity.y < -300.0) == (delay == 2), "coyote window: " + str(delay) + " frames after edge")

	for distance in [20.0, 190.0]:
		await reset_player()
		player.position.y = 560.0 - distance
		player.velocity.y = 150.0
		await frames(1)
		player.coyote_remaining = 0.0 # Teleporting is a test fixture, not walking off an edge.
		Input.action_press("jump")
		var jumped := false
		for frame in range(32):
			await frames(1)
			if player.velocity.y < -300.0:
				jumped = true
		check(jumped == (distance == 20.0), "jump buffer expires correctly from distance " + str(distance))
	await reset_player()
	player.position = Vector2(1100, -5000)
	await frames(140)
	check(player.velocity.y <= player.movement.terminal_velocity, "terminal velocity is capped")
	for action in ["move_left", "move_right", "jump", "attack", "interact", "pause", "restart"]:
		var has_desktop := false
		var has_pad := false
		for event in InputMap.action_get_events(action):
			has_desktop = has_desktop or event is InputEventKey or event is InputEventMouseButton
			has_pad = has_pad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		check(has_desktop and has_pad, action + " has desktop and controller bindings")
	print("MOVEMENT: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
