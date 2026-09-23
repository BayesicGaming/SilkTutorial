class_name KilnBoss
extends CharacterBody2D
## Body/data orchestration only. States under States own the attack behavior.
signal defeated
enum Attack { SWEEP, SLAM, CHARGE }
@export var sweep_attack: AttackData = preload("res://resources/boss_sweep.tres")
@export var slam_attack: AttackData = preload("res://resources/boss_slam.tres")
@export var charge_attack: AttackData = preload("res://resources/boss_charge.tres")
@export var charge_speed: float = 430.0
@export var jump_speed: float = 700.0
@export var slam_fall_speed: float = 850.0
@export var move_speed: float = 100.0
@export var gravity: float = 1500.0
@export var idle_duration: float = 0.9
var attack_states: Array[StringName] = [&"Sweep", &"Leap", &"Charge"]
var facing: float = -1.0
var damage_flash: float = 0.0
var push_velocity: float = 0.0
var current_attack: Attack = Attack.SWEEP
var next_attack: Attack = Attack.SWEEP
var target_x: float = 0.0
var landing_y: float = 0.0
var state: StringName:
	get:
		return state_machine.current_name if state_machine != null else &""
var state_remaining: float:
	get:
		return state_machine.current.remaining if state_machine.current != null else 0.0
var dead: bool:
	get:
		return state == &"Dead"
var active: bool:
	get:
		return state != &"" and not dead
@onready var health: HealthComponent = $Health
@onready var hitbox: HitboxComponent = $Hitbox
@onready var state_machine: StateMachine = $States

func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	# No initial state: Game activates the encounter after binding the HUD.
	state_machine.initialize(self)

func activate() -> void:
	if not active and not dead:
		state_machine.change_state(&"Idle")

func find_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player

func choose_attack() -> void:
	if not active:
		return
	current_attack = next_attack
	next_attack = (next_attack + 1) % Attack.size() as Attack
	var player := find_player()
	if is_instance_valid(player):
		facing = -1.0 if player.global_position.x < global_position.x else 1.0
	# This selection configures data/targets; child states execute the behavior.
	if current_attack == Attack.SWEEP:
		hitbox.attack = sweep_attack
		configure_hitbox(Vector2(110, 50), Vector2(facing * 78.0, -25))
	elif current_attack == Attack.SLAM:
		hitbox.attack = slam_attack
		target_x = clampf(player.global_position.x, global_position.x - 220.0, global_position.x + 220.0) if is_instance_valid(player) else global_position.x
		target_x = clampf(target_x, 90.0, 1350.0)
		landing_y = global_position.y
		configure_hitbox(Vector2(370, 32), Vector2(0, -16))
	else:
		hitbox.attack = charge_attack
		configure_hitbox(Vector2(86, 65), Vector2(0, -32))
	state_machine.change_state(&"Windup", true)

func configure_hitbox(size: Vector2, at: Vector2) -> void:
	hitbox.position = at
	var shape := hitbox.get_node("Shape").shape as RectangleShape2D
	shape.size = size

func _physics_process(delta: float) -> void:
	damage_flash = maxf(0.0, damage_flash - delta)
	if not active:
		return
	velocity.x = 0.0
	velocity.y = minf(velocity.y + gravity * delta, 950.0)
	state_machine.physics_update(delta)
	push_velocity = move_toward(push_velocity, 0.0, 400.0 * delta)
	velocity.x += push_velocity
	move_and_slide()

func _on_damaged(_amount: int, impulse: Vector2) -> void:
	damage_flash = 0.15
	# Heavy enough to finish telegraphs; tiny horizontal knockback still registers.
	push_velocity = impulse.x * 0.15

func _on_died() -> void:
	state_machine.change_state(&"Dead")
