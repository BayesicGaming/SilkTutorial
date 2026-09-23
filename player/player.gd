class_name Player
extends CharacterBody2D
## The body owns input/physics helpers; child states decide when to use them.
signal respawn_requested
@export var movement: MovementTuning
var facing: float = 1.0
var coyote_remaining: float = 0.0
var jump_buffer_remaining: float = 0.0
var damage_flash: float = 0.0
var axis: float = 0.0
var attacking: bool:
	get:
		return attack_phase in [&"Startup", &"Active", &"Recovery"]
var dead: bool:
	get:
		return motion_machine != null and motion_machine.current_name == &"Dead"
var attack_phase: StringName:
	get:
		return attack_machine.current_name if attack_machine != null else &""
@onready var health: HealthComponent = $Health
@onready var hitbox: HitboxComponent = $Hitbox
@onready var motion_machine: StateMachine = $Motion
@onready var attack_machine: StateMachine = $Attack

func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	attack_machine.initialize(self, &"Ready")
	motion_machine.initialize(self, &"Airborne")

func _physics_process(delta: float) -> void:
	damage_flash = maxf(0.0, damage_flash - delta)
	if dead:
		motion_machine.physics_update(delta)
		return
	read_input(delta)
	attack_machine.physics_update(delta)
	motion_machine.physics_update(delta)
	cut_released_jump()
	hitbox.position.x = facing * 34.0
	move_and_slide()
	motion_machine.after_move()
	if position.y > 1200.0:
		health.invulnerability_remaining = 0.0
		health.take_damage(health.max_health)

func read_input(delta: float) -> void:
	axis = Input.get_axis("move_left", "move_right")
	coyote_remaining = movement.coyote_time if is_on_floor() else maxf(0.0, coyote_remaining - delta)
	jump_buffer_remaining = maxf(0.0, jump_buffer_remaining - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_remaining = movement.jump_buffer_time

func steer(delta: float, grounded: bool) -> void:
	if not is_zero_approx(axis) and not attacking:
		facing = signf(axis)
	var speed := movement.max_speed * (movement.attack_move_multiplier if attacking else 1.0)
	var acceleration := movement.ground_acceleration if grounded else movement.air_acceleration
	if is_zero_approx(axis):
		acceleration = movement.ground_deceleration if grounded else movement.air_deceleration
	elif grounded and velocity.x * axis < 0.0:
		acceleration = movement.turn_acceleration
	velocity.x = move_toward(velocity.x, axis * speed, acceleration * delta)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity_scale := movement.fall_multiplier if velocity.y > 0.0 else 1.0
		velocity.y = minf(velocity.y + movement.gravity * gravity_scale * delta, movement.terminal_velocity)

func try_buffered_jump() -> bool:
	if jump_buffer_remaining <= 0.0 or coyote_remaining <= 0.0:
		return false
	launch_jump()
	return true

func launch_jump() -> void:
	velocity.y = movement.jump_velocity
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0

func cut_released_jump() -> void:
	# Also handles a buffered tap released before landing.
	if not Input.is_action_pressed("jump") and velocity.y < -movement.released_jump_speed:
		velocity.y = -movement.released_jump_speed

func resume_attacks() -> void:
	if attack_phase == &"Disabled" and health.current_health > 0:
		attack_machine.change_state(&"Ready")

func _on_damaged(_amount: int, impulse: Vector2) -> void:
	velocity = Vector2(signf(impulse.x) * movement.knockback_strength, -movement.knockback_lift)
	damage_flash = 0.16
	motion_machine.change_state(&"Hurt", true)

func _on_died() -> void:
	motion_machine.change_state(&"Dead")
