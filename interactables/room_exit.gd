extends Area2D
signal transition_requested(destination: int, spawn_name: StringName)
@export var destination: int = 1
@export var spawn_name: StringName = &"Entrance"
# Left/right arrows use -1/+1. Rotate the exit node +/-90 degrees for down/up;
# its trigger rotates too. Destination and spawn_name still determine travel.
@export var direction: float = 1.0
# Keep the arrow visible above a floor opening without moving its trigger.
@export var arrow_offset: Vector2 = Vector2.ZERO
var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.dead and not triggered:
		triggered = true
		transition_requested.emit(destination, spawn_name)

func _draw() -> void:
	draw_set_transform(arrow_offset)
	var color := Color("#62b5b0")
	draw_line(Vector2(-direction * 10, -12), Vector2(direction * 10, 0), color, 3)
	draw_line(Vector2(direction * 10, 0), Vector2(-direction * 10, 12), color, 3)
	draw_line(Vector2(0, -85), Vector2(0, -30), Color("#29454c"), 1)
