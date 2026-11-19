extends Area2D

class_name ShockwaveProjectile

# Onda de choque do pisão de Golias: pedras que brotam do chão. Pule por cima!

const FX = preload("res://scripts/fx.gd")

var speed: float = 400.0
var direction: float = -1.0
var lifetime: float = 2.6
var _t: float = 0.0
var _dust_timer: float = 0.0
var _hit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func launch(start_pos: Vector2, move_dir: float, move_speed: float = 400.0) -> void:
	global_position = start_pos
	direction = move_dir
	speed = move_speed

func _physics_process(delta: float) -> void:
	_t += delta
	global_position.x += direction * speed * delta
	lifetime -= delta
	modulate.a = clampf(lifetime * 2.0, 0.0, 1.0)
	_dust_timer -= delta
	if _dust_timer <= 0.0:
		_dust_timer = 0.07
		FX.burst(get_parent(), global_position, Color(0.75, 0.62, 0.45, 0.8), 3, 120.0, 0.5, 6.0, 100.0, 40.0, Vector2(-direction, -1.0).normalized(), 2)
	if lifetime <= 0.0 or global_position.x < -40.0 or global_position.x > 1320.0:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _hit or not (body is DavidPlayer):
		return
	if body.is_dodging or body.is_invulnerable:
		return
	_hit = true
	body.take_damage(1, global_position.x - direction * 40.0)

func _draw() -> void:
	# Espinhos de pedra que crescem e afundam
	var cols := [Color(0.5, 0.38, 0.26), Color(0.62, 0.48, 0.32), Color(0.42, 0.31, 0.2)]
	for i in 5:
		var off := -i * 13.0 * direction
		var phase := fmod(_t * 6.0 + i * 0.45, 1.0)
		var h := sin(phase * PI) * (40.0 - i * 6.0)
		if h <= 1.0:
			continue
		var w := 11.0 - i
		var spike := PackedVector2Array([Vector2(off - w, 2), Vector2(off - w * 0.3, -h), Vector2(off + w * 0.4, -h * 0.85), Vector2(off + w, 2)])
		draw_colored_polygon(spike, cols[i % 3])
		draw_line(Vector2(off - w * 0.3, -h), Vector2(off - w * 0.6, -h * 0.4), Color(0.8, 0.68, 0.5, 0.8), 2.0)
	# Rachadura no chão
	draw_line(Vector2(-70 * direction, 2), Vector2(10 * direction, 2), Color(0.2, 0.12, 0.06, 0.6), 3.0)
