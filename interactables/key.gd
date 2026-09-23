extends Area2D
var elapsed: float = 0.0
var collected: bool = false
@onready var game_state: Node = get_node("/root/GameState")

func _ready() -> void:
	if game_state.has_key:
		queue_free()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.dead and not collected:
		collected = true
		game_state.collect_key()
		get_node("/root/Feedback").impact(global_position, 0.0)
		queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var at := Vector2(0, sin(elapsed * 3) * 4)
	draw_circle(at, 28, Color(1, 0.75, 0.25, 0.07))
	draw_arc(at + Vector2(0, -8), 8, 0, TAU, 24, Color("#ffd67e"), 3)
	draw_line(at, at + Vector2(0, 18), Color("#ffd67e"), 4)
	draw_line(at + Vector2(0, 10), at + Vector2(8, 10), Color("#ffd67e"), 3)
	draw_line(at + Vector2(0, 17), at + Vector2(6, 17), Color("#ffd67e"), 3)
