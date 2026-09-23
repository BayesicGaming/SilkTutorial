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
	var health := HealthComponent.new()
	health.max_health = 3
	root.add_child(health)
	var deaths := [0]
	health.died.connect(func(): deaths[0] += 1)
	check(not health.take_damage(-1), "negative damage is rejected")
	check(health.take_damage(1) and health.current_health == 2, "damage reduces shared health")
	check(not health.take_damage(1), "invulnerability rejects immediate repeated damage")
	await frames(10)
	check(health.take_damage(99) and health.current_health == 0, "health clamps to zero")
	await frames(10)
	check(not health.take_damage(1) and deaths[0] == 1, "death occurs once")
	var lab: Node2D = load("res://tests/movement_lab.tscn").instantiate()
	root.add_child(lab)
	var player: Player = lab.get_node("Player")
	var target: Player = load("res://player/player.tscn").instantiate()
	target.position = Vector2(342, 560)
	lab.add_child(target)
	target.set_physics_process(false)
	target.get_node("Hurtbox").collision_layer = 16
	await frames(4)
	var hit_stops := [0]
	root.get_node("Feedback").impact_created.connect(func(_at):
		if Engine.time_scale < 1.0:
			hit_stops[0] += 1)
	Input.action_press("attack")
	await frames(1)
	check(player.attack_phase == &"Startup" and not player.hitbox.enabled, "attack begins with harmless startup")
	Input.action_release("attack")
	await frames(7)
	check(target.health.current_health == 5, "real hitbox overlap reaches hurtbox and health")
	check(target.velocity.x > 0 and target.velocity.y < 0, "damage applies directional knockback")
	check(target.motion_machine.current_name == &"Hurt" and target.motion_machine.current.remaining > 0, "damage briefly locks movement control")
	check(hit_stops[0] == 1, "landed hit starts hit-stop")
	# The engine uses fixed simulation delta here; feedback uses real-time-equivalent delta.
	await frames(40)
	check(target.health.current_health == 5, "one swing only damages a target once")
	check(not player.hitbox.enabled and player.attack_phase == &"Ready", "attack ends after recovery")
	check(is_equal_approx(Engine.time_scale, 1.0), "hit-stop restores time scale")
	player.health.invulnerability_remaining = 0.0
	var respawns := [0]
	player.respawn_requested.connect(func(): respawns[0] += 1)
	player.health.take_damage(99)
	await frames(45)
	check(player.dead and respawns[0] == 1, "player death emits delayed respawn request")
	print("COMBAT: ", checks - failures, "/", checks, " passed")
	quit(1 if failures else 0)
