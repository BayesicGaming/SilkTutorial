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
	var state := root.get_node("GameState")
	state.reset_run()
	state.room_index = 3
	var game = load("res://game.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	var boss = game.room.get_node("Enemies/Boss")
	check(boss.active and game.get_node("HUD/Boss").visible, "arena activates boss and health UI")
	game.player.position = boss.position + Vector2(-95, 0)
	boss.choose_attack()
	check(boss.state == &"Windup" and not boss.hitbox.enabled, "boss sweep telegraphs before damage")
	var before: int = game.player.health.current_health
	await frames(65)
	check(game.player.health.current_health < before, "boss sweep damages player")
	check(boss.state == &"Recovery", "boss sweep enters recovery")
	game.player.position = boss.position + Vector2(-45, 0)
	game.player.velocity = Vector2.ZERO
	game.player.facing = 1
	game.player.motion_machine.change_state(&"Grounded")
	Input.action_press("attack")
	await frames(12)
	Input.action_release("attack")
	check(boss.health.current_health < boss.health.max_health, "player melee damages boss")
	check(game.get_node("HUD/Boss/Bar").value == boss.health.current_health, "boss health signal updates UI")
	await frames(30)
	boss.next_attack = boss.Attack.SLAM
	boss.hitbox.end_swing()
	game.player.position = boss.position + Vector2(-120, 0)
	game.player.health.invulnerability_remaining = 0.0
	before = game.player.health.current_health
	boss.choose_attack()
	var saw_leap := false
	var saw_fall := false
	var saw_impact := false
	var apex: float = boss.position.y
	for frame in range(115):
		await frames(1)
		saw_leap = saw_leap or boss.state == &"Leap"
		saw_fall = saw_fall or boss.state == &"Fall"
		saw_impact = saw_impact or boss.state == &"Impact"
		apex = minf(apex, boss.position.y)
	check(saw_leap and saw_fall and saw_impact, "slam executes leap, fall, and impact phases")
	check(apex < 620.0 and boss.is_on_floor(), "slam physically jumps and lands")
	check(game.player.health.current_health < before, "slam impact area damages nearby player")
	boss.next_attack = boss.Attack.CHARGE
	boss.hitbox.end_swing()
	game.player.position = boss.position + Vector2(165, 0)
	game.player.velocity = Vector2.ZERO
	game.player.health.invulnerability_remaining = 0.0
	before = game.player.health.current_health
	var start_x: float = boss.position.x
	boss.choose_attack()
	check(not boss.hitbox.enabled and boss.state == &"Windup", "charge telegraph is harmless")
	var saw_charge := false
	for frame in range(112):
		await frames(1)
		saw_charge = saw_charge or boss.state == &"Charge"
	check(saw_charge and absf(boss.position.x - start_x) > 200, "charge commits to a fast horizontal movement")
	check(game.player.health.current_health < before, "charge hitbox damages player")
	check(boss.state == &"Recovery", "charge ends in a punishable recovery")
	boss.health.invulnerability_remaining = 0.0
	boss.health.take_damage(99)
	await frames(2)
	check(boss.dead and not boss.hitbox.enabled, "boss death ends damaging attacks")
	check(state.victory and game.get_node("HUD/Victory").visible and not game.get_node("HUD/Boss").visible, "boss death triggers victory and hides bar")
	print("BOSS: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
