class_name HurtboxComponent
extends Area2D
## An area that routes a hit into its sibling HealthComponent.
@export_node_path("HealthComponent") var health_path: NodePath = ^"../Health"
@onready var health: HealthComponent = get_node(health_path)

func receive_hit(amount: int, impulse: Vector2) -> bool:
	return health.take_damage(amount, impulse)
