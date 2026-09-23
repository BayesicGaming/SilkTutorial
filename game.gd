extends Node2D
## Only this scene swaps rooms. Exits announce intent; state outlives the swap.
const ROOMS: Array[String] = [
	"res://rooms/room_1.tscn", "res://rooms/room_2.tscn",
	"res://rooms/room_3.tscn", "res://rooms/room_4.tscn",
	"res://rooms/room_5.tscn" # Lantern Well: the branch below Room 2 (index 4).
]
var room: Node2D
var player: Player
var transitioning: bool = false
var current_spawn: StringName = &"Entrance"
@onready var game_state: Node = get_node("/root/GameState")

func _ready() -> void:
	load_room(game_state.room_index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		$HUD.set_paused(get_tree().paused)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("restart"):
		if game_state.victory:
			game_state.reset_run()
			current_spawn = &"Entrance"
		get_tree().paused = false
		$HUD.set_paused(false)
		request_room(game_state.room_index, current_spawn)

func request_room(index: int, spawn_name: StringName = &"Entrance") -> void:
	if transitioning:
		return
	transitioning = true
	# Body-entered signals run during physics queries. Defer tree mutation.
	load_room.call_deferred(index, spawn_name)

func load_room(index: int, spawn_name: StringName = &"Entrance") -> void:
	get_node("/root/Feedback").clear()
	if is_instance_valid(room):
		$RoomRoot.remove_child(room)
		room.queue_free()
	game_state.room_index = index
	current_spawn = spawn_name
	room = load(ROOMS[index]).instantiate()
	$RoomRoot.add_child(room)
	player = room.get_node("Player")
	player.global_position = room.get_node(NodePath("Spawns/" + str(spawn_name))).global_position
	player.respawn_requested.connect(_on_respawn)
	for exit_node in room.get_node("Exits").get_children():
		exit_node.transition_requested.connect(request_room)
	$Camera.target = player
	$Camera.limit_left = int(room.bounds.position.x)
	$Camera.limit_top = int(room.bounds.position.y)
	$Camera.limit_right = int(room.bounds.end.x)
	$Camera.limit_bottom = int(room.bounds.end.y)
	$Camera.global_position = player.global_position + Vector2(0, -110)
	$Camera.reset_smoothing()
	$HUD.bind_player(player.health)
	$HUD.show_room(room.room_title, room.room_hint)
	if room.has_node("Enemies/Boss"):
		var boss = room.get_node("Enemies/Boss")
		$HUD.bind_boss(boss.health)
		boss.defeated.connect(_on_boss_defeated)
		boss.activate()
	transitioning = false

func _on_respawn() -> void:
	request_room(game_state.room_index, current_spawn)

func _on_boss_defeated() -> void:
	game_state.victory = true
	game_state.changed.emit()
	$HUD.show_victory()
