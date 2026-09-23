extends Node
## Rendered snapshots for visual QA, not a claim of human playtesting.
func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Snapshots need a rendered window; omit --headless.")
		get_tree().quit(1)
		return
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
	var game = load("res://game.tscn").instantiate()
	add_child(game)
	for index in range(game.ROOMS.size()):
		game.load_room(index)
		game.player.position.x = 680 if index != 1 else 720
		if index == 2:
			game.player.position.x = 1170
		if index == 1:
			game.player.position.y = 550
			game.player.position.x = 860
		if index == 4:
			game.player.position = Vector2(980, 740)
		for frame in range(35):
			await get_tree().physics_frame
		if index == 3:
			var boss = game.room.get_node("Enemies/Boss")
			boss.next_attack = boss.Attack.SLAM
			boss.choose_attack()
		game.get_node("Camera").reset_smoothing()
		await RenderingServer.frame_post_draw
		var screenshot := get_viewport().get_texture().get_image()
		var result := screenshot.save_png("res://tests/artifacts/room_%d.png" % (index + 1))
		print("Snapshot room ", index + 1, ": ", result)
		if index == 4:
			game.player.position = Vector2(800, 250)
			game.player.velocity = Vector2.ZERO
			for frame in range(10):
				await get_tree().physics_frame
			game.get_node("Camera").reset_smoothing()
			await RenderingServer.frame_post_draw
			var upper_view := get_viewport().get_texture().get_image()
			print("Snapshot well up exit: ", upper_view.save_png("res://tests/artifacts/room_5_up.png"))
	get_tree().quit()
