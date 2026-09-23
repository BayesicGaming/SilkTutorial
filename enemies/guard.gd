extends CharacterBody2D
## A local enum is enough for this enemy: no inherited AI framework.
enum State { PATROL, CHASE, WINDUP, ACTIVE, RECOVERY, HURT, DEAD }
@export var patrol_speed: float = 35.0
@export var chase_speed: float = 105.0
@export var detection_range: float = 270.0
@export var attack_range: float = 53.0
@export var gravity: float = 1450.0
@export var patrol_radius: float = 90.0
var state: State = State.PATROL
var state_remaining: float = 0.0
var facing: float = -1.0
var damage_flash: float = 0.0
var dead: bool = false
var home_x: float
@onready var health: HealthComponent = $Health
@onready var hitbox: HitboxComponent = $Hitbox
@onready var edge_probe: RayCast2D = $EdgeProbe

func _ready() -> void:
	home_x = position.x
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	damage_flash = maxf(0.0, damage_flash - delta)
	if dead:
		return
	state_remaining -= delta
	velocity.y = minf(velocity.y + gravity * delta, 800.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	var offset := player.global_position - global_position if is_instance_valid(player) else Vector2(9999, 9999)
	match state:
		State.PATROL, State.CHASE:
			var detected := offset.length() < detection_range and not player.dead if is_instance_valid(player) else false
			state = State.CHASE if detected else State.PATROL
			if detected:
				facing = -1.0 if offset.x < 0.0 else 1.0
			elif absf(position.x - home_x) > patrol_radius:
				facing = signf(home_x - position.x)
			edge_probe.position.x = facing * 23.0
			edge_probe.force_raycast_update()
			velocity.x = facing * (chase_speed if detected else patrol_speed)
			if is_on_floor() and (not edge_probe.is_colliding() or is_on_wall()):
				velocity.x = 0.0
				if not detected:
					facing *= -1.0
			if detected and absf(offset.x) < attack_range and absf(offset.y) < 45.0:
				enter_state(State.WINDUP, hitbox.attack.startup)
		State.WINDUP:
			velocity.x = 0.0
			if state_remaining <= 0.0:
				enter_state(State.ACTIVE, hitbox.attack.active_time)
				hitbox.begin_swing()
		State.ACTIVE:
			if state_remaining <= 0.0:
				hitbox.end_swing()
				enter_state(State.RECOVERY, hitbox.attack.recovery)
		State.RECOVERY, State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if state_remaining <= 0.0:
				enter_state(State.PATROL)
	hitbox.position.x = facing * 32.0
	move_and_slide()

func enter_state(next: State, duration: float = 0.0) -> void:
	state = next
	state_remaining = duration

func _on_damaged(_amount: int, impulse: Vector2) -> void:
	velocity = impulse
	damage_flash = 0.15
	hitbox.end_swing()
	enter_state(State.HURT, 0.28)

func _on_died() -> void:
	dead = true
	state = State.DEAD
	hitbox.end_swing()
	await get_tree().create_timer(0.22, false).timeout
	queue_free()
