extends Area2D

# Item coletável: pedra caída no chão ou queijo que recupera vida.
# "Leva estes dez queijos..." (1 Samuel 17:18)

const FX = preload("res://scripts/fx.gd")
const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")

const GROUND_Y := 590.0

@export_enum("stone", "cheese") var kind: String = "stone"
var lifetime: float = 14.0
var velocity: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _landed: bool = true

func _ready() -> void:
	z_index = 3
	collision_layer = 0
	collision_mask = 2
	if kind == "cheese":
		lifetime = 12.0

func drop_from_sky() -> void:
	_landed = false
	velocity = Vector2(0, 0)

func _physics_process(delta: float) -> void:
	_t += delta
	lifetime -= delta
	if not _landed:
		velocity.y += 900.0 * delta
		position += velocity * delta
		if position.y >= GROUND_Y:
			position.y = GROUND_Y
			if velocity.y > 200.0:
				velocity.y = -velocity.y * 0.35
				FX.dust(get_parent(), global_position, 5, 0.5)
			else:
				_landed = true
	if lifetime <= 3.0:
		visible = fmod(lifetime, 0.25) > 0.1
	if lifetime <= 0.0:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body is DavidPlayer:
			_try_collect(body)
			break
	queue_redraw()

func _try_collect(david: DavidPlayer) -> void:
	var ok := false
	if kind == "stone":
		ok = david.add_stone(1)
	else:
		ok = david.heal(1)
		if ok:
			var ft = FLOATING_TEXT_SCENE.instantiate()
			ft.position = global_position + Vector2(0, -40)
			get_parent().add_child(ft)
			ft.setup("+1 vida!", Color(1.0, 0.5, 0.55), true)
	if ok:
		FX.burst(get_parent(), global_position + Vector2(0, -8), Color(1, 1, 0.8), 8, 120.0, 0.4, 3.0, 0.0)
		queue_free()

func _draw() -> void:
	var bob := sin(_t * 4.0) * 2.0 if _landed else 0.0
	# Brilho para chamar atenção
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, -8 + bob), 0.0, Vector2.ONE)
	if kind == "stone":
		draw_circle(Vector2.ZERO, 12.0, Color(1, 1, 0.7, 0.18 * glow))
		draw_set_transform(Vector2(0, -6 + bob), 0.0, Vector2(1.0, 0.75))
		draw_circle(Vector2.ZERO, 7.0, Color(0.38, 0.36, 0.34))
		draw_circle(Vector2.ZERO, 6.0, Color(0.72, 0.71, 0.68))
		draw_circle(Vector2(-2, -2), 2.4, Color(0.95, 0.95, 0.92))
	else:
		draw_circle(Vector2(0, -2), 18.0, Color(1, 0.95, 0.4, 0.22 * glow))
		var wedge := PackedVector2Array([Vector2(-13, 6), Vector2(13, 6), Vector2(13, -4), Vector2(-9, -10)])
		draw_colored_polygon(wedge, Color(0.98, 0.82, 0.3))
		draw_colored_polygon(PackedVector2Array([Vector2(-13, 6), Vector2(-9, -10), Vector2(-13, -2)]), Color(0.85, 0.65, 0.2))
		draw_line(Vector2(-9, -10), Vector2(13, -4), Color(1, 0.95, 0.6), 2.0)
		for h in [Vector2(-3, 0), Vector2(5, -2), Vector2(8, 3), Vector2(-7, 3)]:
			draw_circle(h, 2.0, Color(0.85, 0.62, 0.15))
		# Setinha "+"
		var py := -26.0 + sin(_t * 4.0) * 3.0
		draw_rect(Rect2(Vector2(-2, py - 6), Vector2(4, 12)), Color(1, 0.35, 0.4))
		draw_rect(Rect2(Vector2(-6, py - 2), Vector2(12, 4)), Color(1, 0.35, 0.4))
