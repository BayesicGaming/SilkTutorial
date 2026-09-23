extends Node2D
var elapsed: float = 0.0
const DURATION: float = 0.25

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := elapsed / DURATION
	var color := Color(1.0, 0.88, 0.57, 1.0 - progress)
	for index in range(9):
		var direction := Vector2.RIGHT.rotated(index * TAU / 9.0)
		draw_line(direction * (5 + 24 * progress), direction * (14 + 30 * progress), color, 2.0)
