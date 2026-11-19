extends Node2D

# Desenho procedural e animado de Golias, o gigante filisteu de Gate.
# Couraça de escamas de bronze, grevas de bronze, capacete com penacho,
# dardo de bronze nas costas e uma lança enorme ("como o eixo do tecelão").
# Desenhado olhando para a direita; o nó pai espelha com scale.x.

const SKIN := Color(0.78, 0.56, 0.42)
const SKIN_DARK := Color(0.62, 0.42, 0.3)
const BRONZE := Color(0.8, 0.58, 0.25)
const BRONZE_DARK := Color(0.52, 0.35, 0.14)
const BRONZE_LIGHT := Color(0.98, 0.82, 0.45)
const CLOTH := Color(0.58, 0.16, 0.13)
const CLOTH_DARK := Color(0.4, 0.1, 0.08)
const LEATHER := Color(0.42, 0.28, 0.16)
const BEARD := Color(0.14, 0.09, 0.07)
const IRON := Color(0.55, 0.57, 0.6)
const IRON_DARK := Color(0.35, 0.36, 0.4)
const WOOD := Color(0.45, 0.3, 0.17)
const PLUME_A := Color(0.85, 0.2, 0.15)
const PLUME_B := Color(0.96, 0.9, 0.78)

var t: float = 0.0
var pose: String = "idle"
var walk_ratio: float = 0.0
var enraged: bool = false
var warning: bool = false
var has_spear: bool = true
var weak_glow: float = 0.35
var dead: bool = false

# Saídas usadas pelo script de lógica (coordenadas locais deste nó)
var head_pos: Vector2 = Vector2(10, -190)
var fist_pos: Vector2 = Vector2(60, -60)
var spear_tip_pos: Vector2 = Vector2(40, -260)
var body_pos: Vector2 = Vector2(0, -140)
var body_rot: float = 0.0

var _p := {
	"lean": 0.0, "crouch": 0.0, "arm_f": 0.2, "elb_f": 0.35, "arm_b": 0.25,
	"elb_b": 1.1, "leg_lift": 0.0, "tilt": 0.0, "spear_raise": 0.0, "mouth": 0.0,
}
var _walk_phase: float = 0.0

func _process(delta: float) -> void:
	t += delta
	_walk_phase += delta * 5.5 * walk_ratio
	var target := _pose_targets()
	var rate := minf(1.0, delta * (22.0 if pose in ["punch", "stomp", "throw"] else 7.0))
	for k in target.keys():
		_p[k] = lerpf(_p[k], target[k], rate)
	_compute_outputs()
	queue_redraw()

func _pose_targets() -> Dictionary:
	var breath := sin(t * 2.0) * 2.0
	var p := {
		"lean": 0.04, "crouch": breath, "arm_f": 0.2 + sin(t * 2.0) * 0.04, "elb_f": 0.35,
		"arm_b": 0.3, "elb_b": 1.15, "leg_lift": 0.0, "tilt": 0.0, "spear_raise": 0.0, "mouth": 0.0,
	}
	match pose:
		"walk":
			p.lean = 0.1
			p.crouch = absf(sin(_walk_phase)) * 5.0
			p.arm_f = 0.2 - sin(_walk_phase) * 0.35
		"punch_windup":
			p.lean = -0.2
			p.crouch = -4.0
			p.arm_f = 3.2 + sin(t * 30.0) * 0.04
			p.elb_f = 0.3
			p.tilt = -0.12
			p.mouth = 0.5
		"punch":
			p.lean = 0.6
			p.crouch = 42.0
			p.arm_f = -0.35
			p.elb_f = 0.0
			p.tilt = 0.3
			p.mouth = 1.0
		"recover":
			p.lean = 0.62
			p.crouch = 46.0 + sin(t * 6.0) * 2.0
			p.arm_f = -0.38
			p.elb_f = 0.05
			p.tilt = 0.38
			p.mouth = 0.4 + sin(t * 6.0) * 0.2
		"stomp_windup":
			p.lean = -0.1
			p.leg_lift = 1.0
			p.arm_f = 1.3
			p.elb_f = 0.2
			p.arm_b = -0.5
			p.tilt = -0.05
			p.mouth = 0.4
		"stomp":
			p.lean = 0.15
			p.crouch = 20.0
			p.arm_f = 0.7
			p.arm_b = -0.2
			p.mouth = 1.0
		"throw_windup":
			p.lean = -0.22
			p.arm_b = 3.7
			p.elb_b = -0.7
			p.spear_raise = 1.0
			p.arm_f = 1.35
			p.elb_f = 0.1
			p.mouth = 0.3
		"throw":
			p.lean = 0.32
			p.crouch = 10.0
			p.arm_b = 1.5
			p.elb_b = 0.15
			p.spear_raise = 1.0
			p.arm_f = -0.2
			p.mouth = 0.8
		"roar":
			p.lean = -0.25
			p.crouch = sin(t * 30.0) * 2.0
			p.arm_f = 2.5
			p.elb_f = 0.6
			p.arm_b = 2.4
			p.elb_b = 0.6
			p.tilt = -0.4
			p.mouth = 1.0
		"stunned", "dead":
			p.lean = 0.3
			p.crouch = 56.0
			p.arm_f = 0.05 + sin(t * 2.5) * 0.1
			p.elb_f = 0.2
			p.arm_b = -0.05
			p.elb_b = 0.3
			p.tilt = sin(t * 3.0) * 0.25 + 0.15
			p.mouth = 0.5
	return p

# ------------------------------------------------------------------ Geometria
func _hip() -> Vector2:
	return Vector2(0, -92.0 + _p.crouch)

func _torso_xf() -> Transform2D:
	return Transform2D(_p.lean, _hip())

func _head_xf() -> Transform2D:
	return _torso_xf() * Transform2D(_p.tilt, Vector2(12, -120))

func _arm_points(sh: Vector2, ang: float, bend: float) -> Array:
	var elbow := sh + Vector2(sin(ang), cos(ang)) * 46.0
	var hand := elbow + Vector2(sin(ang + bend), cos(ang + bend)) * 42.0
	return [sh, elbow, hand]

func _spear_dir() -> Vector2:
	var a := lerpf(-PI * 0.5, -0.22, _p.spear_raise)
	return Vector2.from_angle(a)

func _compute_outputs() -> void:
	var hx := _head_xf()
	head_pos = hx * Vector2(13, -14)
	var tx := _torso_xf()
	body_pos = tx * Vector2(0, -48)
	body_rot = _p.lean
	var fa: Array = _arm_points(Vector2(28, -84), _p.arm_f, _p.elb_f)
	fist_pos = tx * (fa[2] as Vector2)
	var ba: Array = _arm_points(Vector2(-24, -84), _p.arm_b, _p.elb_b)
	spear_tip_pos = tx * ((ba[2] as Vector2) + _spear_dir() * 140.0)

func _ik(a: Vector2, b: Vector2, l1: float, l2: float) -> Vector2:
	var d := clampf(a.distance_to(b), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var ang := (b - a).angle()
	var cos_a := (l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d)
	var off := acos(clampf(cos_a, -1.0, 1.0))
	return a + Vector2.from_angle(ang - off) * l1

func _limb(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	draw_line(a, b, col, w)
	draw_circle(a, w * 0.5, col)
	draw_circle(b, w * 0.5, col)

# ------------------------------------------------------------------ Desenho
func _draw() -> void:
	var hip := _hip()
	# Sombra
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 70.0, Color(0, 0, 0, 0.28))
	draw_set_transform_matrix(Transform2D.IDENTITY)

	# Pés
	var s := sin(_walk_phase)
	var c := cos(_walk_phase)
	var foot_f := Vector2(22 + s * 26.0 * walk_ratio, -maxf(0.0, c) * 14.0 * walk_ratio)
	var foot_b := Vector2(-20 - s * 26.0 * walk_ratio, -maxf(0.0, -c) * 14.0 * walk_ratio)
	foot_f = foot_f.lerp(Vector2(52, -62), _p.leg_lift)
	if pose in ["stunned", "dead"]:
		foot_f = Vector2(30, 0)
		foot_b = Vector2(-48, 0)

	var hip_f := hip + Vector2(14, 0)
	var hip_b := hip + Vector2(-14, 0)
	_leg(hip_b, _ik(hip_b, foot_b, 50.0, 48.0), foot_b, true)

	var tx := _torso_xf()
	# Braço de trás (atrás do corpo)
	draw_set_transform_matrix(tx)
	var ba: Array = _arm_points(Vector2(-24, -84), _p.arm_b, _p.elb_b)
	_limb(ba[0], ba[1], 21.0, SKIN_DARK)
	_limb(ba[1], ba[2], 18.0, SKIN_DARK)
	_bracer(ba[1], ba[2], true)
	# Dardo de bronze nas costas
	draw_line(Vector2(-40, -104), Vector2(26, -14), WOOD.darkened(0.2), 6.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-40, -104), Vector2(-50, -122), Vector2(-34, -108)]), BRONZE)

	draw_set_transform_matrix(Transform2D.IDENTITY)
	_leg(hip_f, _ik(hip_f, foot_f, 50.0, 48.0), foot_f, false)

	draw_set_transform_matrix(tx)
	_torso()

	draw_set_transform_matrix(_head_xf())
	_head()

	draw_set_transform_matrix(tx)
	# Lança na mão de trás (passa na frente do corpo)
	if has_spear and not (pose in ["stunned", "dead"]):
		_spear(ba[2])
	draw_circle(ba[2], 12.0, SKIN_DARK)
	# Braço da frente
	var fa: Array = _arm_points(Vector2(28, -84), _p.arm_f, _p.elb_f)
	_limb(fa[0], fa[1], 23.0, SKIN)
	_limb(fa[1], fa[2], 20.0, SKIN)
	_bracer(fa[1], fa[2], false)
	draw_circle(fa[0], 17.0, BRONZE)
	draw_arc(fa[0], 17.0, PI * 1.1, PI * 1.9, 10, BRONZE_LIGHT, 3.0)
	_fist(fa[2])

	draw_set_transform_matrix(Transform2D.IDENTITY)
	if pose == "stunned":
		_stun_stars()
	if warning:
		_warning_icon()
	if enraged and not dead:
		_steam()

func _leg(hip_pt: Vector2, knee: Vector2, foot: Vector2, back: bool) -> void:
	var sk := SKIN_DARK if back else SKIN
	var br := BRONZE_DARK if back else BRONZE
	_limb(hip_pt, knee, 27.0, sk)
	# Greva de bronze na canela
	_limb(knee, foot + Vector2(0, -8), 22.0, br)
	draw_line(knee.lerp(foot, 0.25), knee.lerp(foot, 0.85), BRONZE_LIGHT if not back else BRONZE, 3.0)
	draw_circle(knee, 13.0, br.lightened(0.1))
	draw_circle(knee, 6.0, BRONZE_LIGHT if not back else BRONZE)
	# Sandália
	var sole := PackedVector2Array([foot + Vector2(-14, -10), foot + Vector2(20, -8), foot + Vector2(26, 0), foot + Vector2(-14, 0)])
	draw_colored_polygon(sole, LEATHER.darkened(0.2 if back else 0.0))

func _bracer(elbow: Vector2, hand: Vector2, back: bool) -> void:
	var a := elbow.lerp(hand, 0.35)
	var b := elbow.lerp(hand, 0.85)
	draw_line(a, b, BRONZE_DARK if back else BRONZE, 21.0)
	draw_line(a, b, BRONZE if back else BRONZE_LIGHT, 3.0)

func _fist(p: Vector2) -> void:
	draw_circle(p, 14.0, SKIN)
	draw_arc(p, 14.0, -0.3, 1.6, 8, SKIN_DARK, 2.5)
	for i in 3:
		draw_line(p + Vector2(4 + i * 0.0, -7 + i * 5), p + Vector2(11, -7 + i * 5), SKIN_DARK, 1.5)

func _torso() -> void:
	# Saiote de tiras (couro e pano)
	for i in 8:
		var x := -34.0 + i * 8.6
		var sway := sin(t * 3.0 + i * 0.7) * 1.5
		var strip := PackedVector2Array([Vector2(x, -8), Vector2(x + 8, -8), Vector2(x + 8 + sway, 34), Vector2(x + sway, 34)])
		draw_colored_polygon(strip, CLOTH if i % 2 == 0 else LEATHER)
		draw_circle(Vector2(x + 4 + sway, 30), 2.0, BRONZE)
	# Couraça de escamas
	var armor := PackedVector2Array([Vector2(-34, -8), Vector2(34, -8), Vector2(44, -66), Vector2(38, -94), Vector2(-38, -94), Vector2(-44, -66)])
	draw_colored_polygon(armor, BRONZE)
	var row := 0
	var y := -86.0
	while y < -14.0:
		var k := (y + 8.0) / -58.0
		var half := lerpf(30.0, 40.0, clampf(k, 0.0, 1.0)) - 4.0
		var off := 5.0 if row % 2 == 1 else 0.0
		var x2 := -half + off
		while x2 <= half:
			draw_arc(Vector2(x2, y), 5.5, 0.15, PI - 0.15, 6, BRONZE_DARK, 2.0)
			draw_arc(Vector2(x2, y - 1.2), 4.0, PI * 0.6, PI * 0.9, 3, BRONZE_LIGHT, 1.2)
			x2 += 10.0
		y += 8.0
		row += 1
	draw_polyline(PackedVector2Array([Vector2(-38, -94), Vector2(-44, -66), Vector2(-34, -8)]), BRONZE_DARK, 3.0)
	draw_polyline(PackedVector2Array([Vector2(38, -94), Vector2(44, -66), Vector2(34, -8)]), BRONZE_DARK, 3.0)
	# Gola
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -96), Vector2(30, -96), Vector2(24, -86), Vector2(-20, -86)]), BRONZE_DARK)
	# Cinturão
	draw_rect(Rect2(Vector2(-37, -16), Vector2(74, 12)), LEATHER)
	draw_rect(Rect2(Vector2(-37, -16), Vector2(74, 2)), LEATHER.lightened(0.15))
	draw_circle(Vector2(16, -10), 8.0, BRONZE)
	draw_circle(Vector2(16, -10), 4.0, BRONZE_LIGHT)
	# Pescoço
	draw_rect(Rect2(Vector2(-2, -110), Vector2(26, 18)), SKIN_DARK)

func _head() -> void:
	# Cabelo de trás
	var hair := PackedVector2Array([Vector2(-14, -10), Vector2(-30, -6), Vector2(-34, 16), Vector2(-24, 28), Vector2(-10, 20)])
	draw_colored_polygon(hair, BEARD)
	# Rosto
	var face_col := SKIN.lerp(Color(0.9, 0.4, 0.3), 0.3) if enraged else SKIN
	draw_circle(Vector2(0, 0), 25.0, face_col)
	draw_circle(Vector2(8, 10), 20.0, face_col)
	# Orelha
	draw_circle(Vector2(-8, 2), 6.0, SKIN_DARK)
	# Nariz grande
	draw_colored_polygon(PackedVector2Array([Vector2(22, -8), Vector2(33, 6), Vector2(30, 10), Vector2(22, 9)]), SKIN_DARK)
	# Barba trançada
	var beard := PackedVector2Array([Vector2(-12, 8), Vector2(4, 12), Vector2(28, 12), Vector2(26, 24), Vector2(16, 40), Vector2(2, 44), Vector2(-8, 34), Vector2(-14, 20)])
	draw_colored_polygon(beard, BEARD)
	for i in 4:
		var bx := -4.0 + i * 7.0
		draw_line(Vector2(bx, 22), Vector2(bx + 2, 40), Color(0.3, 0.2, 0.14), 1.6)
	# Boca
	if _p.mouth > 0.15:
		draw_set_transform_matrix(_head_xf() * Transform2D(0.0, Vector2(1.0, 0.4 + _p.mouth * 0.6), 0.0, Vector2(20, 16)))
		draw_circle(Vector2.ZERO, 8.0, Color(0.25, 0.05, 0.05))
		draw_rect(Rect2(Vector2(-6, -8), Vector2(12, 3)), Color(0.95, 0.92, 0.8))
		draw_set_transform_matrix(_head_xf())
	else:
		draw_line(Vector2(14, 16), Vector2(27, 15), Color(0.3, 0.08, 0.06), 2.5)
	# Bigode
	draw_colored_polygon(PackedVector2Array([Vector2(12, 10), Vector2(30, 9), Vector2(28, 14), Vector2(18, 15), Vector2(10, 14)]), BEARD)
	# Olho
	if dead:
		draw_line(Vector2(10, -8), Vector2(20, 2), BEARD, 2.5)
		draw_line(Vector2(10, 2), Vector2(20, -8), BEARD, 2.5)
	elif pose == "stunned":
		for i in 3:
			draw_arc(Vector2(15, -3), 2.0 + i * 2.2, t * 8.0 + i, t * 8.0 + i + 4.0, 8, BEARD, 1.4)
	else:
		draw_set_transform_matrix(_head_xf() * Transform2D(0.0, Vector2(1.3, 0.8), 0.0, Vector2(15, -3)))
		draw_circle(Vector2.ZERO, 5.5, Color(0.98, 0.95, 0.9))
		draw_set_transform_matrix(_head_xf())
		var pupil := Color(0.9, 0.1, 0.05) if enraged else Color(0.12, 0.08, 0.05)
		draw_circle(Vector2(17, -3), 2.8, pupil)
		if enraged:
			draw_circle(Vector2(17, -3), 5.0, Color(1.0, 0.2, 0.1, 0.3))
	# Sobrancelha zangada
	var slant := 6.0 if enraged else 3.0
	draw_line(Vector2(6, -10 - slant), Vector2(24, -7), BEARD, 4.0)
	# Testa: o ponto fraco (brilho sutil)
	var glow := weak_glow * (0.55 + 0.45 * sin(t * 4.0))
	if glow > 0.02 and not dead:
		draw_circle(Vector2(13, -16), 10.0, Color(1.0, 0.9, 0.4, 0.25 * glow))
		draw_circle(Vector2(13, -16), 5.0, Color(1.0, 0.95, 0.6, 0.35 * glow))
	# Capacete de bronze
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		dome.append(Vector2(0, -21) + Vector2(cos(a), sin(a)) * 29.0)
	draw_colored_polygon(dome, BRONZE)
	draw_arc(Vector2(0, -21), 24.0, PI * 1.15, PI * 1.55, 10, BRONZE_LIGHT, 3.0)
	# Proteção da nuca
	draw_colored_polygon(PackedVector2Array([Vector2(-29, -21), Vector2(-14, -21), Vector2(-18, 12), Vector2(-31, 8)]), BRONZE_DARK)
	# Aro do capacete
	draw_colored_polygon(PackedVector2Array([Vector2(-31, -26), Vector2(31, -28), Vector2(31, -21), Vector2(-31, -19)]), BRONZE_DARK)
	for i in 6:
		draw_circle(Vector2(-24 + i * 10, -23.5), 1.8, BRONZE_LIGHT)
	# Penacho de penas (coroa filisteia)
	for i in 9:
		var a2 := PI * 1.12 + PI * 0.76 * float(i) / 8.0
		var dir := Vector2(cos(a2), sin(a2))
		var base := Vector2(0, -21) + dir * 27.0
		var sway := sin(t * 2.5 + i * 0.6) * 0.12
		var fdir := dir.rotated(sway) + Vector2(0, -0.6)
		fdir = fdir.normalized()
		var perp := Vector2(-fdir.y, fdir.x)
		var tip := base + fdir * 24.0
		var feather := PackedVector2Array([base - perp * 3.0, base + fdir * 12.0 - perp * 5.0, tip, base + fdir * 12.0 + perp * 5.0, base + perp * 3.0])
		draw_colored_polygon(feather, PLUME_A if i % 2 == 0 else PLUME_B)
		draw_line(base, tip, Color(0, 0, 0, 0.2), 1.0)

func _spear(hand: Vector2) -> void:
	var d := _spear_dir()
	var butt := hand - d * 100.0
	var neck := hand + d * 118.0
	var tip := hand + d * 150.0
	draw_line(butt, neck, WOOD.darkened(0.25), 10.0)
	draw_line(butt, neck, WOOD, 6.0)
	# Ponta de ferro (600 siclos!)
	var perp := Vector2(-d.y, d.x)
	var head := PackedVector2Array([neck - perp * 4.0, neck + d * 6.0 - perp * 9.0, tip, neck + d * 6.0 + perp * 9.0, neck + perp * 4.0])
	draw_colored_polygon(head, IRON)
	draw_line(neck, tip, IRON_DARK, 2.0)
	draw_line(neck - d * 4.0, neck + d * 2.0, BRONZE, 8.0)

func _star(center: Vector2, r: float, col: Color, rot: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		var a := rot + PI * float(i) / 5.0 - PI * 0.5
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)

func _stun_stars() -> void:
	var c := head_pos + Vector2(0, -42)
	for i in 3:
		var a := t * 4.0 + TAU * float(i) / 3.0
		var p := c + Vector2(cos(a) * 34.0, sin(a) * 9.0)
		_star(p, 9.0, Color(1.0, 0.9, 0.2), t * 3.0)
		_star(p, 4.0, Color(1.0, 1.0, 0.8), t * 3.0)

func _warning_icon() -> void:
	var c := head_pos + Vector2(0, -75)
	var pulse := 1.0 + sin(t * 18.0) * 0.12
	draw_circle(c, 17.0 * pulse, Color(1, 1, 1))
	draw_circle(c, 14.0 * pulse, Color(0.9, 0.12, 0.1))
	draw_rect(Rect2(c + Vector2(-2.5, -9) * pulse, Vector2(5, 11) * pulse), Color.WHITE)
	draw_circle(c + Vector2(0, 6.5) * pulse, 2.8 * pulse, Color.WHITE)

func _steam() -> void:
	for i in 4:
		var k := fmod(t * 0.9 + i * 0.25, 1.0)
		var p := head_pos + Vector2(-20 + i * 12 + sin(t * 3.0 + i) * 4.0, -40 - k * 50.0)
		draw_circle(p, 5.0 + k * 9.0, Color(0.95, 0.95, 0.95, 0.35 * (1.0 - k)))
