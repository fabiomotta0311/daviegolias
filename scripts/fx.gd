extends RefCounted

# Efeitos de partículas reutilizáveis (poeira, faíscas, respingos, pedrinhas).

static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 14, speed: float = 180.0,
		lifetime: float = 0.6, size: float = 4.0, gravity: float = 500.0, spread: float = 180.0,
		direction: Vector2 = Vector2.UP, z: int = 6) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = lifetime
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.3
	p.damping_min = 20.0
	p.damping_max = 60.0
	var grad := Gradient.new()
	grad.set_color(0, color)
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = grad
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0.3))
	p.scale_amount_curve = curve
	p.z_index = z
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

static func dust(parent: Node, pos: Vector2, amount: int = 12, strength: float = 1.0) -> void:
	burst(parent, pos, Color(0.82, 0.72, 0.56, 0.85), amount, 140.0 * strength, 0.7, 7.0 * strength, -60.0, 70.0, Vector2.UP)

static func rocks(parent: Node, pos: Vector2, amount: int = 10) -> void:
	burst(parent, pos, Color(0.45, 0.34, 0.24, 1.0), amount, 320.0, 0.8, 4.5, 900.0, 50.0, Vector2.UP)

static func sparks(parent: Node, pos: Vector2, amount: int = 22) -> void:
	burst(parent, pos, Color(1.0, 0.92, 0.35, 1.0), amount, 380.0, 0.5, 3.5, 300.0, 180.0, Vector2.UP, 8)
	burst(parent, pos, Color(1.0, 1.0, 0.85, 0.9), 6, 90.0, 0.35, 10.0, 0.0, 180.0, Vector2.UP, 8)

static func splash(parent: Node, pos: Vector2, amount: int = 10) -> void:
	burst(parent, pos, Color(0.6, 0.85, 1.0, 0.9), amount, 200.0, 0.55, 3.5, 700.0, 35.0, Vector2.UP, 7)

static func hearts(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, Color(1.0, 0.35, 0.45, 1.0), 12, 160.0, 0.8, 5.0, -80.0, 180.0, Vector2.UP, 8)

static func hurt(parent: Node, pos: Vector2) -> void:
	burst(parent, pos, Color(1.0, 1.0, 1.0, 1.0), 10, 220.0, 0.4, 4.0, 200.0, 180.0, Vector2.UP, 8)
