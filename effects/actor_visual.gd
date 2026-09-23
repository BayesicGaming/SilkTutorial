extends Node2D
## Read-only presentation. Replace this child without changing combat/movement.
@export_enum("player", "guard", "moth", "boss") var kind: String = "player"
var time: float = 0.0
var death_time: float = 0.0
@onready var actor = get_parent()

func _process(delta: float) -> void:
	time += delta
	if actor.dead:
		death_time += delta
	modulate.a = maxf(0.0, 1.0 - death_time * 3.5)
	if not actor.dead and actor.health.invulnerability_remaining > 0.0:
		modulate.a = 0.5 if int(time * 20) % 2 == 0 else 1.0
	queue_redraw()

func ink(color: String) -> Color:
	return Color.WHITE if actor.damage_flash > 0.0 else Color(color)

func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var moving: bool = absf(actor.velocity.x) > 15.0
	var bob := sin(time * (20.0 if moving else 4.0)) * (2.0 if moving else 1.2)
	var shrink := maxf(0.1, 1.0 - death_time * 3.0)
	draw_set_transform(Vector2(0, bob), death_time * 2, Vector2(actor.facing, shrink))
	match kind:
		"player": draw_player(moving)
		"guard": draw_guard(moving)
		"moth": draw_moth()
		"boss": draw_boss()
	draw_set_transform(Vector2.ZERO)
	if kind in ["guard", "moth"] and actor.health.current_health < actor.health.max_health:
		draw_rect(Rect2(-18, -60, 36, 3), Color("#253546"))
		draw_rect(Rect2(-18, -60, 36.0 * actor.health.current_health / actor.health.max_health, 3), Color("#efbd7b"))
	draw_attack_area()
	if kind == "boss" and not actor.dead:
		draw_boss_warning()

func draw_player(moving: bool) -> void:
	var airborne: bool = not actor.is_on_floor()
	var rising: bool = actor.velocity.y < 0
	var stride := sin(time * 20.0) * 5.0 if moving else 0.0
	var cloak_bottom := -12.0 if airborne and rising else -5.0
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -30), Vector2(8, -30), Vector2(15, cloak_bottom), Vector2(-15, cloak_bottom)]), ink("#56ddce"))
	draw_line(Vector2(-6, -8), Vector2(-7 - stride, -8 if airborne else -1), ink("#a5d7cf"), 5)
	draw_line(Vector2(6, -8), Vector2(7 + stride, -14 if airborne and rising else -1), ink("#a5d7cf"), 5)
	draw_circle(Vector2(0, -34), 10, ink("#f1ead7"))
	draw_line(Vector2(3, -35), Vector2(12, -35), ink("#122131"), 3)
	draw_line(Vector2(-8, -27), Vector2(-23 - absf(actor.velocity.x) * 0.025, -28 + sin(time * 10) * 3), ink("#f3ba6f"), 4)
	var tip := Vector2(24, -30)
	if actor.attack_phase == &"Startup":
		tip = Vector2(-10, -50)
	elif actor.attack_phase == &"Active":
		tip = Vector2(45, -14)
	elif actor.attack_phase == &"Recovery":
		tip = Vector2(28, -9)
	draw_line(Vector2(10, -18), tip, ink("#ffe5a0"), 3)
	if actor.attack_phase == &"Active":
		draw_arc(Vector2(8, -23), 43, -0.9, 0.8, 16, Color("#fff3c5"), 4)

func draw_guard(moving: bool) -> void:
	var warning: bool = actor.state == actor.State.WINDUP
	var crouch := 4.0 if warning else 0.0
	draw_colored_polygon(PackedVector2Array([Vector2(-21, -31 + crouch), Vector2(13, -35 + crouch), Vector2(22, -8), Vector2(-24, -8)]), ink("#c36c59"))
	draw_rect(Rect2(-15, -40 + crouch, 30, 20), ink("#df9b74"))
	draw_line(Vector2(3, -30 + crouch), Vector2(16, -30 + crouch), ink("#301c2c"), 4)
	var stride := sin(time * 15) * 4 if moving else 0.0
	draw_line(Vector2(-12, -10), Vector2(-13 - stride, -1), ink("#83565a"), 8)
	draw_line(Vector2(12, -10), Vector2(13 + stride, -1), ink("#83565a"), 8)
	draw_line(Vector2(20, -18), Vector2(22 if warning else 34, -52 if warning else -10), ink("#f1c98c"), 7)
	if warning:
		draw_circle(Vector2(0, -56), 5 + sin(time * 25), Color("#ffe3a0"))

func draw_moth() -> void:
	var spread := 25.0 + sin(time * 22) * 10.0
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -20), Vector2(-spread, -44), Vector2(-32, -10), Vector2(-8, -7)]), ink("#b699dc"))
	draw_colored_polygon(PackedVector2Array([Vector2(4, -20), Vector2(spread, -44), Vector2(32, -10), Vector2(8, -7)]), ink("#d1ade4"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(10, -18), Vector2(0, 0), Vector2(-10, -18)]), ink("#645085"))
	draw_circle(Vector2(3, -22), 4, ink("#ffe1a0"))
	if actor.state == actor.State.WINDUP:
		draw_arc(Vector2(0, -18), 34 + sin(time * 20) * 3, 0, TAU, 30, Color("#ffcf84"), 2)
	if actor.state == actor.State.DIVE:
		draw_line(Vector2(-18, -18), Vector2(-46, -26), Color("#e6bef5"), 3)

func draw_boss() -> void:
	var warning: bool = actor.state == &"Windup"
	var crouch := 9.0 if warning else 0.0
	draw_colored_polygon(PackedVector2Array([Vector2(-38, -65 + crouch), Vector2(35, -65 + crouch), Vector2(29, -11), Vector2(-32, -11)]), ink("#a9704d"))
	draw_circle(Vector2(-37, -57 + crouch), 21, ink("#c48d5c"))
	draw_circle(Vector2(37, -57 + crouch), 21, ink("#c48d5c"))
	draw_rect(Rect2(-23, -89 + crouch, 46, 34), ink("#e8b878"))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -88 + crouch), Vector2(-29, -109 + crouch), Vector2(-7, -92 + crouch), Vector2(3, -106 + crouch), Vector2(14, -91 + crouch), Vector2(30, -100 + crouch), Vector2(23, -86 + crouch)]), ink("#edd5a2"))
	draw_line(Vector2(0, -73 + crouch), Vector2(22, -73 + crouch), ink("#3a2431"), 6)
	draw_circle(Vector2(0, -38), 13, ink("#f7bc71"))
	draw_circle(Vector2(0, -38), 6, ink("#613948"))
	draw_line(Vector2(-20, -14), Vector2(-23, -2), ink("#d6a774"), 14)
	draw_line(Vector2(20, -14), Vector2(23, -2), ink("#d6a774"), 14)
	var weapon_end := Vector2(66, -90) if warning else Vector2(67, -20)
	draw_line(Vector2(40, -45), weapon_end, ink("#845543"), 10)
	draw_rect(Rect2(weapon_end - Vector2(19, 8), Vector2(38, 18)), ink("#ead4a8"))
	if actor.state == &"Charge":
		draw_line(Vector2(-50, -30), Vector2(-100, -38), Color("#f6b363"), 5)

func draw_attack_area() -> void:
	if not actor.hitbox.enabled or actor.dead:
		return
	var shape := actor.hitbox.get_node("Shape").shape as RectangleShape2D
	var area := Rect2(actor.hitbox.position - shape.size / 2, shape.size)
	draw_rect(area, Color(1, 0.74, 0.37, 0.16))
	draw_rect(area, Color(1, 0.83, 0.54, 0.8), false, 2)

func draw_boss_warning() -> void:
	if actor.state not in [&"Windup", &"Leap", &"Fall"]:
		return
	var titles := ["SWEEP / JUMP", "SLAM / MOVE", "CHARGE / JUMP"]
	draw_string(ThemeDB.fallback_font, Vector2(-78, -132), titles[actor.current_attack], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffe3a0"))
	if actor.current_attack == actor.Attack.SLAM:
		var ground := Vector2(actor.target_x - actor.global_position.x, actor.landing_y - actor.global_position.y)
		draw_rect(Rect2(ground + Vector2(-185, -5), Vector2(370, 5)), Color(1, 0.57, 0.34, 0.7))
		draw_line(ground + Vector2(0, -20), ground, Color("#ffe3a0"), 3)
	elif actor.state == &"Windup":
		draw_arc(Vector2(0, -45), 70 + sin(time * 20) * 3, 0, TAU, 40, Color("#e6ac60"), 2)
