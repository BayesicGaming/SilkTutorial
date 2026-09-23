extends Area2D
signal transition_requested(destination: int, spawn_name: StringName)
var triggered: bool = false
@onready var game_state: Node = get_node("/root/GameState")

func _process(_delta: float) -> void:
	queue_redraw()
	if Input.is_action_just_pressed("interact"):
		for body in get_overlapping_bodies():
			if body is Player and not body.dead:
				try_enter()
				break

func try_enter() -> bool:
	if triggered or not game_state.try_unlock_door():
		return false
	triggered = true
	transition_requested.emit(3, &"Entrance")
	return true

func _draw() -> void:
	var color := Color("#70dfc3") if game_state.door_unlocked else Color("#e4ac61")
	draw_rect(Rect2(-42, -128, 84, 128), Color("#152a38"))
	draw_rect(Rect2(-42, -128, 84, 128), color, false, 3)
	for offset in [-22, 0, 22]:
		draw_line(Vector2(offset, -115), Vector2(offset, -10), color.darkened(0.55), 2)
	draw_circle(Vector2(0, -65), 15, color)
	draw_circle(Vector2(0, -68), 4, Color("#152a38"))
	draw_line(Vector2(0, -65), Vector2(0, -56), Color("#152a38"), 4)
	draw_string(ThemeDB.fallback_font, Vector2(-44, -144), "E / Y : ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
