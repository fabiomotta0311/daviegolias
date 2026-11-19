extends Area2D

# Lança arremessada por Golias. Crava no chão e some depois de um tempo.

const AudioManager = preload("res://scripts/audio_manager.gd")
const FX = preload("res://scripts/fx.gd")

const GRAVITY := 260.0
const GROUND_Y := 590.0

var velocity: Vector2 = Vector2.ZERO
var _stuck: bool = false
var _stuck_timer: float = 0.0

func _ready() -> void:
	z_index = 3
	body_entered.connect(_on_body_entered)

func launch(start_pos: Vector2, vel: Vector2) -> void:
	global_position = start_pos
	velocity = vel
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	if _stuck:
		_stuck_timer -= delta
		if _stuck_timer < 0.6:
			modulate.a = maxf(0.0, _stuck_timer / 0.6)
		if _stuck_timer <= 0.0:
			queue_free()
		return
	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	rotation = velocity.angle()
	var tip := global_position + Vector2.from_angle(rotation) * 55.0
	if tip.y >= GROUND_Y + 6.0 or global_position.x < -100.0 or global_position.x > 1380.0:
		_stick()

func _on_body_entered(body: Node2D) -> void:
	if _stuck:
		return
	if body is DavidPlayer:
		if body.is_dodging or body.is_invulnerable:
			return
		body.take_damage(1, global_position.x - velocity.x)
		FX.burst(get_parent(), body.global_position + Vector2(0, -30), Color(1, 1, 1), 10, 200.0, 0.4, 3.0, 300.0)
		queue_free()
	elif body is StaticBody2D:
		_stick()

func _stick() -> void:
	_stuck = true
	_stuck_timer = 1.8
	set_deferred("monitoring", false)
	AudioManager.play_sound(get_parent(), "spear_land", -2.0)
	var tip := global_position + Vector2.from_angle(rotation) * 55.0
	FX.dust(get_parent(), Vector2(tip.x, GROUND_Y), 10, 0.9)
	FX.rocks(get_parent(), Vector2(tip.x, GROUND_Y), 6)

func _draw() -> void:
	# Haste de madeira
	draw_line(Vector2(-150, 0), Vector2(40, 0), Color(0.3, 0.2, 0.1), 9.0)
	draw_line(Vector2(-150, -1), Vector2(40, -1), Color(0.5, 0.34, 0.19), 5.0)
	# Anéis de bronze
	draw_line(Vector2(34, 0), Vector2(42, 0), Color(0.8, 0.58, 0.25), 11.0)
	draw_line(Vector2(-150, 0), Vector2(-140, 0), Color(0.8, 0.58, 0.25), 10.0)
	# Ponta de ferro
	var head := PackedVector2Array([Vector2(40, -4), Vector2(50, -10), Vector2(72, 0), Vector2(50, 10), Vector2(40, 4)])
	draw_colored_polygon(head, Color(0.58, 0.6, 0.64))
	draw_line(Vector2(42, 0), Vector2(72, 0), Color(0.36, 0.37, 0.4), 2.0)
	if not _stuck:
		for i in 3:
			var x := -160.0 - i * 26.0
			draw_line(Vector2(x, -6 + i * 6), Vector2(x - 30, -6 + i * 6), Color(1, 1, 1, 0.3 - i * 0.08), 2.0)
