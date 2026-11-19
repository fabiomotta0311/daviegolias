extends Node2D

# Desenho procedural e animado de Davi (pastor com funda).
# Desenhado olhando para a direita; o nó pai espelha com scale.x.

const SKIN := Color(0.93, 0.74, 0.58)
const SKIN_DARK := Color(0.8, 0.58, 0.44)
const HAIR := Color(0.62, 0.27, 0.12)
const HAIR_LIGHT := Color(0.78, 0.4, 0.18)
const TUNIC := Color(0.86, 0.76, 0.56)
const TUNIC_DARK := Color(0.7, 0.6, 0.42)
const FLEECE := Color(0.97, 0.95, 0.88)
const FLEECE_SHADE := Color(0.84, 0.8, 0.72)
const BELT := Color(0.45, 0.26, 0.14)
const LEATHER := Color(0.52, 0.33, 0.18)
const SANDAL := Color(0.4, 0.24, 0.12)
const CORD := Color(0.55, 0.42, 0.28)
const OUTLINE := Color(0.18, 0.11, 0.07, 0.9)

var t: float = 0.0
var speed_ratio: float = 0.0
var on_floor: bool = true
var vel_y: float = 0.0
var charging: bool = false
var charge: float = 0.0
var aim_angle: float = -0.6 # ângulo local (olhando para a direita)
var dodging: bool = false
var dodge_progress: float = 0.0
var dead: bool = false
var throw_timer: float = 0.0
var squash: float = 0.0
var has_stones: bool = true

var _run_phase: float = 0.0
var _fall: float = 0.0
var _lean: float = 0.0

func _process(delta: float) -> void:
	t += delta
	_run_phase += delta * (4.0 + 12.0 * speed_ratio)
	throw_timer = maxf(0.0, throw_timer - delta)
	squash = move_toward(squash, 0.0, delta * 4.0)
	_fall = move_toward(_fall, 1.0 if dead else 0.0, delta * 2.5)
	_lean = lerpf(_lean, 0.14 * speed_ratio if on_floor else 0.05, minf(1.0, delta * 10.0))
	queue_redraw()

func throw_anim() -> void:
	throw_timer = 0.18

func land_squash() -> void:
	squash = 1.0

# ------------------------------------------------------------------ Desenho
func _draw() -> void:
	# Sombra
	var shadow_w := 16.0 + 4.0 * (1.0 - clampf(-vel_y / 600.0, 0.0, 1.0))
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, shadow_w, Color(0, 0, 0, 0.25))

	var base := Transform2D.IDENTITY
	if dodging:
		var pivot := Vector2(0, -26)
		var roll := dodge_progress * TAU
		base = Transform2D(roll, Vector2(0.85, 0.85), 0.0, pivot) * Transform2D(0.0, -pivot)
	elif _fall > 0.0:
		base = Transform2D(-PI * 0.5 * _fall, Vector2(0, 0))
	if squash > 0.0:
		var s := Vector2(1.0 + squash * 0.15, 1.0 - squash * 0.15)
		base = base * Transform2D(0.0, s, 0.0, Vector2.ZERO)

	var bob := 0.0
	if on_floor and not dodging:
		bob = absf(sin(_run_phase)) * -2.0 * speed_ratio + sin(t * 2.2) * 0.6 * (1.0 - speed_ratio)
	var hip := Vector2(0, -28 + bob)

	# Pernas (pé de trás primeiro)
	var feet := _feet()
	var knee_b := _ik(hip + Vector2(-3, 0), feet[1], 14.0, 14.0)
	var knee_f := _ik(hip + Vector2(3, 0), feet[0], 14.0, 14.0)
	draw_set_transform_matrix(base)
	_leg(hip + Vector2(-3, 0), knee_b, feet[1], SKIN_DARK)

	var torso := base * Transform2D(_lean, hip)
	# Braço de trás
	draw_set_transform_matrix(torso)
	var back_sh := Vector2(-3, -19)
	var back_ang := 0.35 - sin(_run_phase) * 0.8 * speed_ratio
	if charging:
		back_ang = aim_angle + PI * 0.5 - _lean
	_arm(back_sh, back_ang, 0.3 if not charging else 0.0, SKIN_DARK, TUNIC_DARK)

	# Bolsa de pastor (alforje)
	draw_set_transform_matrix(base)
	_leg(hip + Vector2(3, 0), knee_f, feet[0], SKIN)

	draw_set_transform_matrix(torso)
	_body()

	# Cabeça
	var head_xf := torso * Transform2D(-_lean * 0.6 + (sin(t * 1.7) * 0.03), Vector2(2, -31))
	draw_set_transform_matrix(head_xf)
	_head()

	# Braço da frente com a funda
	draw_set_transform_matrix(torso)
	_front_arm_and_sling()

	draw_set_transform_matrix(Transform2D.IDENTITY)
	if charging:
		_charge_ring()

func _feet() -> Array:
	if dodging:
		return [Vector2(6, -10), Vector2(-6, -10)]
	if not on_floor:
		if vel_y < 0.0:
			return [Vector2(7, -8), Vector2(-5, -3)]
		return [Vector2(5, -2), Vector2(-6, -6)]
	if speed_ratio > 0.05:
		var s := sin(_run_phase)
		var c := cos(_run_phase)
		var amp := 12.0 * speed_ratio
		return [
			Vector2(s * amp + 2.0, -maxf(0.0, c) * 7.0 * speed_ratio),
			Vector2(-s * amp - 2.0, -maxf(0.0, -c) * 7.0 * speed_ratio),
		]
	if charging:
		return [Vector2(8, 0), Vector2(-7, 0)]
	return [Vector2(5, 0), Vector2(-5, 0)]

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

func _leg(hip_pt: Vector2, knee: Vector2, foot: Vector2, skin: Color) -> void:
	_limb(hip_pt, knee, 6.5, skin)
	_limb(knee, foot + Vector2(0, -2), 5.5, skin)
	# Tiras da sandália
	draw_line(foot + Vector2(-2, -6), foot + Vector2(2, -3), SANDAL, 1.6)
	draw_line(foot + Vector2(-2, -3), foot + Vector2(2, -6), SANDAL, 1.6)
	var sole := PackedVector2Array([foot + Vector2(-4, -3), foot + Vector2(6, -2), foot + Vector2(7, 0), foot + Vector2(-4, 0)])
	draw_colored_polygon(sole, SANDAL)

func _arm(sh: Vector2, ang: float, bend: float, skin: Color, sleeve: Color) -> Vector2:
	var d1 := Vector2(sin(ang), cos(ang))
	var elbow := sh + d1 * 10.0
	var d2 := Vector2(sin(ang + bend), cos(ang + bend))
	var hand := elbow + d2 * 10.0
	_limb(sh, elbow, 5.5, skin)
	draw_circle(sh, 4.0, sleeve)
	_limb(elbow, hand, 4.8, skin)
	draw_circle(hand, 3.0, skin)
	return hand

func _body() -> void:
	# Saia da túnica
	var skirt := PackedVector2Array([Vector2(-9, -3), Vector2(9, -3), Vector2(12, 11), Vector2(4, 12), Vector2(-4, 11), Vector2(-12, 11)])
	draw_colored_polygon(skirt, TUNIC)
	draw_polyline(PackedVector2Array([Vector2(-12, 11), Vector2(-4, 11), Vector2(4, 12), Vector2(12, 11)]), TUNIC_DARK, 1.5)
	# Tronco
	var chest := PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(9, -17), Vector2(7, -22), Vector2(-7, -22), Vector2(-9, -17)])
	draw_colored_polygon(chest, TUNIC)
	draw_line(Vector2(2, -21), Vector2(4, -6), TUNIC_DARK, 1.2)
	# Pele de carneiro sobre o ombro
	var fleece := PackedVector2Array([Vector2(-8, -22), Vector2(5, -22), Vector2(1, -12), Vector2(-5, -6), Vector2(-9, -9)])
	draw_colored_polygon(fleece, FLEECE)
	for p in [Vector2(-6, -19), Vector2(-2, -20), Vector2(2, -19), Vector2(-5, -14), Vector2(-1, -15), Vector2(-7, -9), Vector2(-3, -10)]:
		draw_arc(p, 2.0, 0.0, TAU, 8, FLEECE_SHADE, 1.0)
	# Cinto
	draw_rect(Rect2(Vector2(-9, -5), Vector2(18, 3.5)), BELT)
	draw_rect(Rect2(Vector2(2, -5), Vector2(3, 3.5)), Color(0.75, 0.6, 0.3))
	# Correia e alforje (bolsa de pastor)
	draw_line(Vector2(6, -21), Vector2(-8, -3), LEATHER, 2.0)
	var bag := Rect2(Vector2(-15, -7), Vector2(9, 10))
	draw_rect(bag, LEATHER)
	draw_rect(Rect2(Vector2(-15, -7), Vector2(9, 4)), LEATHER.darkened(0.2))
	if has_stones:
		draw_circle(Vector2(-12, -8), 2.0, Color(0.72, 0.72, 0.7))
		draw_circle(Vector2(-9, -8.5), 1.8, Color(0.62, 0.62, 0.6))
	# Pescoço
	draw_rect(Rect2(Vector2(-1, -26), Vector2(5, 5)), SKIN_DARK)

func _head() -> void:
	# Cabelo de trás (cachos ruivos)
	for p in [Vector2(-6, -2), Vector2(-7, 3), Vector2(-4, -7), Vector2(-3, 5)]:
		draw_circle(p, 5.0, HAIR)
	# Rosto
	draw_circle(Vector2(0, 0), 8.5, SKIN)
	draw_circle(Vector2(1, 4), 7.0, SKIN)
	# Orelha
	draw_circle(Vector2(-2, 1), 2.4, SKIN_DARK)
	# Bochecha corada ("ruivo e de belo semblante")
	draw_circle(Vector2(5, 3), 2.4, Color(1.0, 0.5, 0.45, 0.45))
	# Nariz
	draw_colored_polygon(PackedVector2Array([Vector2(7, -1), Vector2(10.5, 2.5), Vector2(7, 3)]), SKIN_DARK)
	# Olho
	if dead:
		draw_line(Vector2(3, -3), Vector2(6, 0), OUTLINE, 1.2)
		draw_line(Vector2(3, 0), Vector2(6, -3), OUTLINE, 1.2)
	else:
		var blink := fmod(t, 3.7) < 0.12
		if blink:
			draw_line(Vector2(3, -1.5), Vector2(6.5, -1.5), OUTLINE, 1.2)
		else:
			draw_circle(Vector2(4.8, -1.5), 1.9, Color.WHITE)
			draw_circle(Vector2(5.4, -1.4), 1.2, Color(0.15, 0.2, 0.35))
	# Sobrancelha (determinada quando carrega a funda)
	var brow_tilt := 1.2 if charging else 0.0
	draw_line(Vector2(2.5, -5 - brow_tilt * 0.3), Vector2(7, -4.5 + brow_tilt), HAIR, 1.4)
	# Boca
	if charging:
		draw_line(Vector2(4, 5.5), Vector2(7, 5.5), Color(0.5, 0.2, 0.15), 1.2)
	else:
		draw_arc(Vector2(5, 4), 2.2, 0.3, 2.2, 6, Color(0.5, 0.2, 0.15), 1.1)
	# Cabelo da frente
	for p in [Vector2(-3, -7), Vector2(2, -8), Vector2(6, -6.5), Vector2(-7, -4)]:
		draw_circle(p, 4.2, HAIR)
	for p in [Vector2(0, -9), Vector2(5, -8.5), Vector2(-5, -6.5)]:
		draw_arc(p, 2.0, PI, TAU, 6, HAIR_LIGHT, 1.0)

func _front_arm_and_sling() -> void:
	var sh := Vector2(3, -19)
	var hand: Vector2
	if charging:
		# Braço levantado girando a funda sobre a cabeça
		hand = _arm(sh, PI - 0.25 + sin(t * 30.0) * 0.05, 0.25, SKIN, TUNIC)
		var spin := t * (9.0 + charge * 24.0)
		var r := 15.0
		var pouch := hand + Vector2(cos(spin), sin(spin) * 0.45) * r
		var trail_a := Color(1.0, 1.0, 1.0, 0.15 + charge * 0.35)
		for k in range(1, 6):
			var sa := spin - k * 0.25
			var tp := hand + Vector2(cos(sa), sin(sa) * 0.45) * r
			draw_circle(tp, 2.6 - k * 0.35, Color(trail_a.r, trail_a.g, trail_a.b, trail_a.a * (1.0 - k / 6.0)))
		draw_line(hand, pouch, CORD, 1.3)
		draw_circle(pouch, 3.4, LEATHER)
		draw_circle(pouch, 2.2, Color(0.75, 0.75, 0.72))
	elif throw_timer > 0.0:
		# Braço estendido para frente após o arremesso
		var a := aim_angle + PI * 0.5 - _lean
		hand = _arm(sh, a, 0.0, SKIN, TUNIC)
		var tail := hand + Vector2(-sin(a), -cos(a)) * -14.0 + Vector2(-6, 4)
		draw_line(hand, tail, CORD, 1.3)
		draw_circle(tail, 2.6, LEATHER)
	else:
		var swing := 0.2 + sin(_run_phase) * 0.8 * speed_ratio
		if not on_floor:
			swing = 1.6
		hand = _arm(sh, swing, 0.5, SKIN, TUNIC)
		# Funda pendurada
		var sway := sin(t * 3.0) * 2.0
		var p1 := hand + Vector2(-1 + sway * 0.3, 8)
		var p2 := hand + Vector2(sway, 14)
		draw_line(hand, p1, CORD, 1.2)
		draw_line(p1, p2, CORD, 1.2)
		draw_circle(p2, 2.6, LEATHER)

func _charge_ring() -> void:
	var c := Vector2(0, -34)
	var col := Color(0.4, 1.0, 0.4).lerp(Color(1.0, 0.85, 0.2), charge)
	if charge >= 1.0:
		col = Color(1.0, 0.95, 0.5) if fmod(t, 0.2) < 0.1 else Color(1.0, 0.6, 0.2)
	draw_arc(c, 34.0, 0.0, TAU, 48, Color(0, 0, 0, 0.25), 5.0, true)
	draw_arc(c, 34.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 48, col, 4.0, true)
