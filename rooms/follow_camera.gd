extends Camera2D
@export var shake_amount: float = 2.5
var target: Node2D
var shake_remaining: float = 0.0

func _ready() -> void:
	get_node("/root/Feedback").impact_created.connect(_on_impact)

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position + Vector2(0, -110)
	shake_remaining = maxf(0.0, shake_remaining - delta)
	offset = Vector2(sin(shake_remaining * 160), cos(shake_remaining * 130)) * shake_amount if shake_remaining > 0.0 else Vector2.ZERO

func _on_impact(_at: Vector2) -> void:
	shake_remaining = 0.12
