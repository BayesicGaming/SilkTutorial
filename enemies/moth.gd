extends CharacterBody2D
## A flying enemy: hold position, mark a dive, commit, then return home.
enum State { HOVER, WINDUP, DIVE, RECOVERY, HURT, DEAD }
@export var detection_range: float = 330.0
@export var dive_speed: float = 300.0
@export var return_speed: float = 125.0
@export var dive_duration: float = 0.75
var state: State = State.HOVER
var state_remaining: float = 0.0
var facing: float = -1.0
var damage_flash: float = 0.0
var dead: bool = false
var home_position: Vector2
var dive_direction: Vector2
var elapsed: float = 0.0
@onready var health: HealthComponent = $Health
@onready var hitbox: HitboxComponent = $Hitbox

func _ready() -> void:
	home_position = position
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	elapsed += delta
	state_remaining -= delta
	damage_flash = maxf(0.0, damage_flash - delta)
	if dead:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	match state:
		State.HOVER:
			velocity = (home_position + Vector2(0, sin(elapsed * 2) * 12) - position) * 3.0
			if is_instance_valid(player) and not player.dead and global_position.distance_to(player.global_position) < detection_range:
				dive_direction = (player.global_position + Vector2(0, -18) - global_position).normalized()
				facing = -1.0 if dive_direction.x < 0.0 else 1.0
				state = State.WINDUP
				state_remaining = hitbox.attack.startup
		State.WINDUP:
			velocity = Vector2.ZERO
			if state_remaining <= 0.0:
				state = State.DIVE
				state_remaining = dive_duration
				hitbox.begin_swing()
		State.DIVE:
			velocity = dive_direction * dive_speed
			if state_remaining <= 0.0 or is_on_wall() or is_on_floor():
				hitbox.end_swing()
				state = State.RECOVERY
				state_remaining = hitbox.attack.recovery
		State.RECOVERY:
			velocity = position.direction_to(home_position) * return_speed
			if position.distance_to(home_position) < 8.0:
				velocity = Vector2.ZERO
				if state_remaining <= 0.0:
					state = State.HOVER
		State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, delta * 500)
			if state_remaining <= 0.0:
				state = State.RECOVERY
				state_remaining = hitbox.attack.recovery
	move_and_slide()

func _on_damaged(_amount: int, impulse: Vector2) -> void:
	velocity = impulse
	damage_flash = 0.15
	hitbox.end_swing()
	state = State.HURT
	state_remaining = 0.22

func _on_died() -> void:
	dead = true
	state = State.DEAD
	hitbox.end_swing()
	await get_tree().create_timer(0.22, false).timeout
	queue_free()
