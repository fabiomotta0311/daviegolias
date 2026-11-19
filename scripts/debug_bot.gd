extends Node

# Robô de teste: joga sozinho quando o jogo é iniciado com "-- --autoplay".
# Útil para testar o equilíbrio e capturar imagens. Não afeta o jogo normal.

var arena: Node
var david
var goliath
var _charge_target: float = 1.0
var _cool: float = 0.0
var passive: bool = false
var idle: bool = false

func _physics_process(delta: float) -> void:
	if david == null or goliath == null or not david.is_alive():
		_release_all()
		return
	_cool -= delta
	var dx: float = goliath.global_position.x - david.global_position.x
	var dist := absf(dx)
	_release_all_moves()

	# Desvia de lanças e ondas
	if not passive:
		_evade()

	if idle:
		return
	if passive:
		if fmod(Time.get_ticks_msec() / 1000.0, 4.0) < 2.0:
			Input.action_press("move_right" if dx > 0 else "move_left")
		return

	# Pedras acabaram: vai ao ribeiro
	if david.current_stones == 0:
		Input.action_release("fire")
		if david.global_position.x > 140.0:
			Input.action_press("move_left")
		return

	# Mantém distância
	if dist < 260.0:
		Input.action_press("move_left" if dx > 0 else "move_right")
	elif dist > 520.0:
		Input.action_press("move_right" if dx > 0 else "move_left")

	# Atira
	if not Input.is_action_pressed("fire"):
		Input.action_press("fire")
		_charge_target = randf_range(0.75, 1.0)
	david.keyboard_aim = true
	var head: Vector2 = goliath.head_area.global_position
	var origin: Vector2 = david.get_sling_origin()
	var v: float = david.get_launch_speed()
	var ang := _solve_angle(head - origin, v)
	david.kb_aim_deg = rad_to_deg(ang)
	if david.sling_charge >= _charge_target:
		Input.action_release("fire")

func _solve_angle(d: Vector2, v: float) -> float:
	var g := 980.0
	var x := absf(d.x)
	var y := -d.y
	var disc := v * v * v * v - g * (g * x * x + 2.0 * y * v * v)
	if disc < 0.0:
		return deg_to_rad(45.0)
	return atan((v * v - sqrt(disc)) / (g * maxf(1.0, x)))

func _release_all_moves() -> void:
	for a in ["move_left", "move_right", "jump", "dodge"]:
		Input.action_release(a)

func _release_all() -> void:
	_release_all_moves()
	Input.action_release("fire")

func _evade() -> void:
	for n in arena.get_children():
		if n.get_script() and n.get_script().resource_path.ends_with("spear.gd") and not n._stuck:
			if n.global_position.distance_to(david.global_position) < 260.0 and _cool <= 0.0:
				Input.action_press("dodge")
				_cool = 0.6
		if n is ShockwaveProjectile:
			var sdx: float = n.global_position.x - david.global_position.x
			if signf(sdx) == -signf(n.direction) and absf(sdx) < 90.0 and david.is_on_floor():
				Input.action_press("jump")
