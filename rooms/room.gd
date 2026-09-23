@tool
extends Node2D
@export var room_title: String = "01 / THE THRESHOLD"
@export var room_hint: String = "Hold jump to rise higher. Release for a short hop."
@export var room_color: Color = Color("#1c3545")
@export var bounds: Rect2 = Rect2(0, 0, 1440, 810)

func _draw() -> void:
	draw_rect(bounds, Color("#0b1420"))
	for x in range(100, int(bounds.size.x), 240):
		draw_rect(Rect2(x, 90, 110, 610), room_color.darkened(0.6))
		draw_arc(Vector2(x + 55, 90), 55, PI, TAU, 20, room_color.darkened(0.2), 2.0)
		draw_line(Vector2(x + 55, 155), Vector2(x + 55, 700), room_color.darkened(0.25), 1)
	draw_circle(Vector2(1140, 200), 54, room_color.darkened(0.3))
	draw_arc(Vector2(1140, 200), 68, 0, TAU, 48, room_color, 1)
