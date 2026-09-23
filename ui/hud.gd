extends CanvasLayer
var message_remaining: float = 0.0
@onready var game_state: Node = get_node("/root/GameState")

func _ready() -> void:
	game_state.changed.connect(_update_key)
	game_state.message_requested.connect(show_message)
	_update_key()

func _process(delta: float) -> void:
	message_remaining = maxf(0.0, message_remaining - delta)
	$Message.visible = message_remaining > 0.0

func bind_player(health: HealthComponent) -> void:
	health.health_changed.connect(_on_player_health)
	_on_player_health(health.current_health, health.max_health)
	$Victory.visible = false
	$Boss.visible = false

func _on_player_health(current: int, maximum: int) -> void:
	$Health.text = "VITALITY  " + "● ".repeat(current) + "○ ".repeat(maximum - current)

func _update_key() -> void:
	$Key.text = "EMBER KEY  /  FOUND" if game_state.has_key else "EMBER KEY  /  —"

func show_room(title: String, hint: String) -> void:
	$RoomTitle.text = title
	$Hint.text = hint

func show_message(message: String) -> void:
	$Message.text = message
	message_remaining = 3.5

func set_paused(value: bool) -> void:
	$Pause.visible = value

func bind_boss(health: HealthComponent) -> void:
	$Boss.visible = true
	health.health_changed.connect(_on_boss_health)
	_on_boss_health(health.current_health, health.max_health)

func _on_boss_health(current: int, maximum: int) -> void:
	$Boss/Bar.max_value = maximum
	$Boss/Bar.value = current

func show_victory() -> void:
	$Boss.visible = false
	$Victory.visible = true
