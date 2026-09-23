extends SceneTree
## Synthesized device events test bindings, not physical hardware.
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
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func button(index: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func stick(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func run() -> void:
	var lab: Node2D = load("res://tests/movement_lab.tscn").instantiate()
	root.add_child(lab)
	var player: Player = lab.get_node("Player")
	await frames(4)
	key(KEY_D, true)
	await frames(12)
	check(player.velocity.x > 280, "physical D event moves player right")
	key(KEY_D, false)
	await frames(12)
	stick(0.1)
	await frames(4)
	check(absf(player.velocity.x) < 1, "stick noise stays inside deadzone")
	stick(0.6)
	await frames(12)
	var partial_speed := player.velocity.x
	check(partial_speed > 80 and partial_speed < 230, "partial stick gives partial movement speed")
	stick(1.0)
	await frames(12)
	check(player.velocity.x > 280, "full stick reaches max speed without changing modes")
	stick(0.0)
	button(JOY_BUTTON_DPAD_LEFT, true)
	await frames(18)
	check(player.velocity.x < -280, "D-pad is digital movement")
	button(JOY_BUTTON_DPAD_LEFT, false)
	key(KEY_SPACE, true)
	await frames(2)
	check(player.velocity.y < -400, "Space device event jumps")
	key(KEY_SPACE, false)
	await frames(45)
	button(JOY_BUTTON_A, true)
	await frames(2)
	check(player.velocity.y < -400, "south face button uses the same jump path")
	button(JOY_BUTTON_A, false)
	await frames(45)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await frames(1)
	check(player.attacking, "left mouse device event starts attack")
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await frames(30)
	button(JOY_BUTTON_X, true)
	await frames(1)
	check(player.attacking, "west face button starts attack")
	button(JOY_BUTTON_X, false)
	for pair in [[KEY_E, JOY_BUTTON_Y, "interact"], [KEY_ESCAPE, JOY_BUTTON_START, "pause"], [KEY_R, JOY_BUTTON_BACK, "restart"]]:
		key(pair[0], true)
		check(Input.is_action_pressed(pair[2]), "keyboard maps to " + pair[2])
		key(pair[0], false)
		button(pair[1], true)
		check(Input.is_action_pressed(pair[2]), "controller maps to " + pair[2])
		button(pair[1], false)
	print("Measured 0.6 stick speed: ", partial_speed)
	print("INPUT: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
