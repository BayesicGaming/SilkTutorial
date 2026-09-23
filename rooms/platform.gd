@tool
extends StaticBody2D
## Size edits update both the solid collider and the procedural platform.
@export var size: Vector2 = Vector2(200, 30):
	set(value):
		size = value
		if is_inside_tree():
			update_shape()
@export var accent: Color = Color("#50667c")

func _ready() -> void:
	update_shape()

func update_shape() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	$CollisionShape2D.shape = rectangle
	$CollisionShape2D.position = size * 0.5
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#172536"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 4)), accent)
	for x in range(16, int(size.x), 48):
		draw_line(Vector2(x, 9), Vector2(x, minf(20.0, size.y)), Color("#26394d"), 1.0)
