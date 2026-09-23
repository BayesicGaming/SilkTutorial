extends SceneTree
var failures: int = 0
var checks: int = 0
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
	var lab: Node2D = load("res://tests/movement_lab.tscn").instantiate()
	root.add_child(lab)
	var player: Player = lab.get_node("Player")
	var guard = load("res://enemies/guard.tscn").instantiate()
	guard.position = Vector2(490, 560)
	lab.add_child(guard)
	await frames(12)
	check(guard.state == guard.State.CHASE and guard.velocity.x < 0, "guard detects and approaches player")
	var saw_windup := false
	var saw_active := false
	var saw_recovery := false
	for frame in range(160):
		await frames(1)
		saw_windup = saw_windup or guard.state == guard.State.WINDUP
		saw_active = saw_active or guard.state == guard.State.ACTIVE
		saw_recovery = saw_recovery or guard.state == guard.State.RECOVERY
	check(saw_windup and saw_active and saw_recovery, "guard executes telegraph, attack, recovery")
	check(player.health.current_health < player.health.max_health, "guard hitbox damages player")
	player.position = guard.position + Vector2(-43, 0)
	player.facing = 1.0
	player.motion_machine.change_state(&"Grounded")
	guard.enter_state(guard.State.RECOVERY, 5.0)
	guard.velocity = Vector2.ZERO
	Input.action_press("attack")
	await frames(12)
	Input.action_release("attack")
	check(guard.health.current_health < guard.health.max_health, "player melee damages guard")
	guard.health.invulnerability_remaining = 0.0
	guard.health.take_damage(99)
	await frames(18)
	check(not is_instance_valid(guard), "dead guard is removed")
	player.position = Vector2(300, 560)
	player.health.invulnerability_remaining = 0.0
	var moth = load("res://enemies/moth.tscn").instantiate()
	moth.position = Vector2(465, 475)
	lab.add_child(moth)
	var health_before: int = player.health.current_health
	var saw_dive := false
	var saw_return := false
	await frames(2)
	check(moth.state == moth.State.WINDUP and not moth.hitbox.enabled, "moth telegraphs before diving")
	for frame in range(120):
		await frames(1)
		saw_dive = saw_dive or moth.state == moth.State.DIVE
		saw_return = saw_return or moth.state == moth.State.RECOVERY
	check(saw_dive and saw_return, "moth dives and returns toward home")
	check(player.health.current_health < health_before, "moth dive damages player")
	moth.health.take_damage(99)
	await frames(18)
	check(not is_instance_valid(moth), "moth shares health and death behavior")
	print("ENEMIES: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
