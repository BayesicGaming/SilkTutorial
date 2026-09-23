extends Node
## Real-time freeze expiry keeps hit-stop independent of pause and time scaling.
signal impact_created(position: Vector2)
var freeze_remaining: float = 0.0
const BURST = preload("res://effects/impact_burst.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if freeze_remaining > 0.0:
		freeze_remaining -= delta / Engine.time_scale
		if freeze_remaining <= 0.0:
			Engine.time_scale = 1.0

func impact(at: Vector2, duration: float) -> void:
	freeze_remaining = maxf(freeze_remaining, duration)
	if freeze_remaining > 0.0:
		Engine.time_scale = 0.08
	var burst := Node2D.new()
	burst.set_script(BURST)
	burst.position = at
	add_child(burst)
	impact_created.emit(at)

func clear() -> void:
	freeze_remaining = 0.0
	Engine.time_scale = 1.0
	for child in get_children():
		child.queue_free()
