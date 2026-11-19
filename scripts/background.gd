extends Node2D

# Cenário procedural do Vale de Elá (1 Samuel 17:1-3):
# Israel acampado num monte (esquerda), os filisteus no outro (direita),
# e o vale com o ribeiro no meio.

const BG_LAYER = preload("res://scripts/bg_layer.gd")

const W := 1280.0
const GROUND_Y := 590.0
const BROOK_X0 := 40.0
const BROOK_X1 := 245.0

enum L { SKY, CLOUDS, MOUNTAINS, CAMPS, VALLEY, GROUND, BROOK }

var t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _mountains := PackedVector2Array()
var _mountains2 := PackedVector2Array()
var _hill_l := PackedVector2Array()
var _hill_r := PackedVector2Array()
var _clouds: Array = []
var _birds: Array = []
var _tents: Array = []
var _soldiers: Array = []
var _banners: Array = []
var _trees: Array = []
var _bushes: Array = []
var _pebbles: Array = []
var _grass: Array = []
var _brook_stones: Array = []
var _reeds: Array = []
var cheer_israel: float = 0.0
var cheer_phil: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 1017
	_build()
	for id in [L.SKY, L.CLOUDS, L.MOUNTAINS, L.CAMPS, L.VALLEY, L.GROUND, L.BROOK]:
		var layer := BG_LAYER.new()
		layer.layer_id = id
		layer.painter = self
		layer.animated = id in [L.CLOUDS, L.CAMPS, L.BROOK, L.GROUND]
		if id == L.BROOK:
			layer.z_index = 3
		add_child(layer)

func _process(delta: float) -> void:
	t += delta
	cheer_israel = maxf(0.0, cheer_israel - delta)
	cheer_phil = maxf(0.0, cheer_phil - delta)
	for c in _clouds:
		c.x += c.speed * delta
		if c.x > W + 160.0:
			c.x = -160.0
	for b in _birds:
		b.x += b.speed * delta
		if b.x > W + 60.0:
			b.x = -60.0 - _rng.randf() * 400.0
			b.y = _rng.randf_range(90.0, 220.0)

func cheer(israel: bool, duration: float = 2.0) -> void:
	if israel:
		cheer_israel = duration
	else:
		cheer_phil = duration

func hill_left_y(x: float) -> float:
	return 395.0 + pow(absf(x - 170.0) / 330.0, 2.0) * 200.0

func hill_right_y(x: float) -> float:
	return 385.0 + pow(absf(x - 1110.0) / 330.0, 2.0) * 200.0

# ------------------------------------------------------------------ Construção
func _build() -> void:
	# Montanhas distantes
	_mountains.append(Vector2(-10, GROUND_Y))
	var x := -10.0
	while x <= W + 40.0:
		_mountains.append(Vector2(x, 300.0 + _rng.randf_range(-35, 35) + sin(x * 0.006) * 40.0))
		x += _rng.randf_range(40, 90)
	_mountains.append(Vector2(W + 40.0, GROUND_Y))
	_mountains2.append(Vector2(-10, GROUND_Y))
	x = -10.0
	while x <= W + 40.0:
		_mountains2.append(Vector2(x, 370.0 + _rng.randf_range(-20, 20) + cos(x * 0.009) * 25.0))
		x += _rng.randf_range(50, 100)
	_mountains2.append(Vector2(W + 40.0, GROUND_Y))
	# Colinas dos acampamentos
	_hill_l.append(Vector2(-20, GROUND_Y))
	x = -20.0
	while x <= 560.0:
		_hill_l.append(Vector2(x, minf(GROUND_Y, hill_left_y(x))))
		x += 20.0
	_hill_l.append(Vector2(560, GROUND_Y))
	_hill_r.append(Vector2(720, GROUND_Y))
	x = 720.0
	while x <= W + 20.0:
		_hill_r.append(Vector2(x, minf(GROUND_Y, hill_right_y(x))))
		x += 20.0
	_hill_r.append(Vector2(W + 20.0, GROUND_Y))
	# Nuvens e pássaros
	for i in 6:
		_clouds.append({"x": _rng.randf_range(0, W), "y": _rng.randf_range(60, 230), "s": _rng.randf_range(0.7, 1.4), "speed": _rng.randf_range(6, 16)})
	for i in 4:
		_birds.append({"x": _rng.randf_range(0, W), "y": _rng.randf_range(90, 220), "speed": _rng.randf_range(40, 70), "ph": _rng.randf() * TAU})
	# Tendas
	for tx in [40.0, 110.0, 250.0, 320.0]:
		_tents.append({"x": tx, "y": hill_left_y(tx), "s": _rng.randf_range(0.8, 1.1), "israel": true})
	for tx in [960.0, 1030.0, 1180.0, 1250.0]:
		_tents.append({"x": tx, "y": hill_right_y(tx), "s": _rng.randf_range(0.8, 1.1), "israel": false})
	# Soldados nos cumes
	for i in 16:
		var sx := 60.0 + i * 20.0 + _rng.randf_range(-6, 6)
		_soldiers.append({"x": sx, "y": hill_left_y(sx), "israel": true, "ph": _rng.randf() * TAU})
	for i in 16:
		var sx2 := 960.0 + i * 20.0 + _rng.randf_range(-6, 6)
		_soldiers.append({"x": sx2, "y": hill_right_y(sx2), "israel": false, "ph": _rng.randf() * TAU})
	_banners = [
		{"x": 180.0, "y": hill_left_y(180.0), "col": Color(0.2, 0.35, 0.7), "col2": Color(0.95, 0.85, 0.4)},
		{"x": 1100.0, "y": hill_right_y(1100.0), "col": Color(0.65, 0.12, 0.1), "col2": Color(0.1, 0.1, 0.1)},
	]
	# Oliveiras e arbustos do vale
	for tx in [470.0, 610.0, 820.0, 690.0]:
		_trees.append({"x": tx, "y": GROUND_Y - 2.0, "s": _rng.randf_range(0.8, 1.2)})
	for i in 14:
		_bushes.append({"x": _rng.randf_range(260, 1260), "y": GROUND_Y - _rng.randf_range(0, 3), "r": _rng.randf_range(6, 14)})
	# Chão
	for i in 70:
		_pebbles.append({"x": _rng.randf_range(0, W), "y": _rng.randf_range(GROUND_Y + 14, 715), "r": _rng.randf_range(2, 6), "c": _rng.randf_range(0.0, 1.0)})
	x = 0.0
	while x < W:
		if x < BROOK_X0 - 6.0 or x > BROOK_X1 + 6.0:
			_grass.append({"x": x, "h": _rng.randf_range(5, 14), "ph": _rng.randf() * TAU})
		x += _rng.randf_range(6, 16)
	for i in 9:
		_brook_stones.append({"x": _rng.randf_range(BROOK_X0 + 18, BROOK_X1 - 18), "y": _rng.randf_range(GROUND_Y + 6, GROUND_Y + 18), "r": _rng.randf_range(4, 7)})
	for rx in [BROOK_X0 + 2.0, BROOK_X0 + 10.0, BROOK_X1 - 8.0, BROOK_X1 + 2.0, BROOK_X1 - 2.0]:
		_reeds.append({"x": rx, "h": _rng.randf_range(26, 42), "ph": _rng.randf() * TAU})

# ------------------------------------------------------------------ Pintura
func paint(c: CanvasItem, id: int) -> void:
	match id:
		L.SKY: _paint_sky(c)
		L.CLOUDS: _paint_clouds(c)
		L.MOUNTAINS: _paint_mountains(c)
		L.CAMPS: _paint_camps(c)
		L.VALLEY: _paint_valley(c)
		L.GROUND: _paint_ground(c)
		L.BROOK: _paint_brook(c)

func _paint_sky(c: CanvasItem) -> void:
	var top := Color(0.38, 0.6, 0.86)
	var mid := Color(0.72, 0.82, 0.9)
	var hor := Color(0.99, 0.87, 0.64)
	c.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 260), Vector2(0, 260)]), PackedColorArray([top, top, mid, mid]))
	c.draw_polygon(PackedVector2Array([Vector2(0, 260), Vector2(W, 260), Vector2(W, GROUND_Y), Vector2(0, GROUND_Y)]), PackedColorArray([mid, mid, hor, hor]))
	# Sol
	var sun := Vector2(1050, 115)
	for i in 6:
		c.draw_circle(sun, 120.0 - i * 18.0, Color(1.0, 0.95, 0.7, 0.06 + i * 0.02))
	c.draw_circle(sun, 40.0, Color(1.0, 0.97, 0.82))

func _paint_clouds(c: CanvasItem) -> void:
	for cl in _clouds:
		var p := Vector2(cl.x, cl.y)
		var s: float = cl.s
		var col := Color(1, 1, 1, 0.85)
		var sh := Color(0.85, 0.85, 0.92, 0.85)
		c.draw_circle(p + Vector2(-30, 8) * s, 22 * s, sh)
		c.draw_circle(p + Vector2(30, 8) * s, 24 * s, sh)
		c.draw_circle(p + Vector2(0, 0) * s, 32 * s, col)
		c.draw_circle(p + Vector2(-34, 4) * s, 20 * s, col)
		c.draw_circle(p + Vector2(34, 2) * s, 22 * s, col)
		c.draw_circle(p + Vector2(10, -16) * s, 22 * s, col)
	for b in _birds:
		var bp := Vector2(b.x, b.y + sin(t * 2.0 + b.ph) * 6.0)
		var flap := sin(t * 10.0 + b.ph) * 5.0
		c.draw_polyline(PackedVector2Array([bp + Vector2(-8, -flap), bp, bp + Vector2(8, -flap)]), Color(0.2, 0.18, 0.2, 0.8), 2.0)

func _paint_mountains(c: CanvasItem) -> void:
	c.draw_colored_polygon(_mountains, Color(0.7, 0.66, 0.72))
	c.draw_colored_polygon(_mountains2, Color(0.66, 0.58, 0.52))
	# Névoa
	c.draw_polygon(PackedVector2Array([Vector2(0, 420), Vector2(W, 420), Vector2(W, GROUND_Y), Vector2(0, GROUND_Y)]),
		PackedColorArray([Color(1, 0.9, 0.75, 0.0), Color(1, 0.9, 0.75, 0.0), Color(1, 0.9, 0.75, 0.45), Color(1, 0.9, 0.75, 0.45)]))
	c.draw_colored_polygon(_hill_l, Color(0.6, 0.6, 0.38))
	c.draw_colored_polygon(_hill_r, Color(0.64, 0.55, 0.36))
	c.draw_polyline(_slice(_hill_l), Color(0.7, 0.7, 0.45), 3.0)
	c.draw_polyline(_slice(_hill_r), Color(0.74, 0.64, 0.42), 3.0)

func _slice(poly: PackedVector2Array) -> PackedVector2Array:
	return poly.slice(1, poly.size() - 1)

func _paint_camps(c: CanvasItem) -> void:
	for tent in _tents:
		var p := Vector2(tent.x, tent.y + 4.0)
		var s: float = tent.s
		var col := Color(0.92, 0.86, 0.72) if tent.israel else Color(0.75, 0.32, 0.25)
		var dark := col.darkened(0.25)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-26, 0) * s, p + Vector2(0, -30) * s, p + Vector2(26, 0) * s]), col)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0) * s, p + Vector2(0, -24) * s, p + Vector2(5, 0) * s]), dark)
		c.draw_line(p + Vector2(0, -30) * s, p + Vector2(0, -38) * s, Color(0.35, 0.25, 0.15), 2.0)
	for sd in _soldiers:
		var hop := 0.0
		var cheering: float = cheer_israel if sd.israel else cheer_phil
		if cheering > 0.0:
			hop = absf(sin(t * 12.0 + sd.ph)) * 6.0
		var p := Vector2(sd.x, sd.y - 2.0 - hop)
		var body := Color(0.32, 0.36, 0.55) if sd.israel else Color(0.5, 0.22, 0.18)
		c.draw_rect(Rect2(p + Vector2(-3, -12), Vector2(6, 12)), body)
		c.draw_circle(p + Vector2(0, -15), 3.2, Color(0.75, 0.55, 0.42))
		if not sd.israel:
			c.draw_line(p + Vector2(-3, -18), p + Vector2(3, -18), Color(0.9, 0.3, 0.2), 2.0)
		var arm_up := -10.0 if cheering > 0.0 else 0.0
		c.draw_line(p + Vector2(4, -10), p + Vector2(5, -30 + arm_up), Color(0.4, 0.3, 0.2), 1.5)
		c.draw_line(p + Vector2(5, -30 + arm_up), p + Vector2(5, -34 + arm_up), Color(0.7, 0.7, 0.75), 2.0)
	for bn in _banners:
		var base := Vector2(bn.x, bn.y)
		var top := base + Vector2(0, -70)
		c.draw_line(base, top, Color(0.35, 0.25, 0.15), 3.0)
		var pts := PackedVector2Array()
		var pts2 := PackedVector2Array()
		for i in 7:
			var fx := float(i) * 7.0
			var wave := sin(t * 4.0 - i * 0.7) * (i * 0.9)
			pts.append(top + Vector2(fx, wave))
		for i in range(6, -1, -1):
			var fx2 := float(i) * 7.0
			var wave2 := sin(t * 4.0 - i * 0.7) * (i * 0.9)
			pts.append(top + Vector2(fx2, 26 + wave2))
		c.draw_colored_polygon(pts, bn.col)
		for i in 7:
			var fx3 := float(i) * 7.0
			var wave3 := sin(t * 4.0 - i * 0.7) * (i * 0.9)
			pts2.append(top + Vector2(fx3, 11 + wave3))
		c.draw_polyline(pts2, bn.col2, 4.0)

func _paint_valley(c: CanvasItem) -> void:
	for b in _bushes:
		var p := Vector2(b.x, b.y)
		c.draw_circle(p, b.r, Color(0.42, 0.48, 0.25))
		c.draw_circle(p + Vector2(b.r * 0.6, 2), b.r * 0.7, Color(0.36, 0.42, 0.21))
	for tr in _trees:
		var p := Vector2(tr.x, tr.y)
		var s: float = tr.s
		c.draw_line(p, p + Vector2(-4, -36) * s, Color(0.4, 0.3, 0.2), 7.0 * s)
		c.draw_line(p + Vector2(-2, -20) * s, p + Vector2(12, -38) * s, Color(0.4, 0.3, 0.2), 4.0 * s)
		for off in [Vector2(-18, -44), Vector2(4, -54), Vector2(20, -42), Vector2(-4, -38), Vector2(-26, -36), Vector2(14, -60)]:
			c.draw_circle(p + off * s, 15.0 * s, Color(0.45, 0.52, 0.34))
		for off in [Vector2(-12, -50), Vector2(10, -56), Vector2(18, -46)]:
			c.draw_circle(p + off * s, 8.0 * s, Color(0.56, 0.62, 0.42))

func _paint_ground(c: CanvasItem) -> void:
	var g_top := Color(0.66, 0.6, 0.34)
	var soil := Color(0.58, 0.44, 0.29)
	var deep := Color(0.36, 0.26, 0.17)
	c.draw_polygon(PackedVector2Array([Vector2(0, GROUND_Y), Vector2(W, GROUND_Y), Vector2(W, 720), Vector2(0, 720)]), PackedColorArray([soil, soil, deep, deep]))
	c.draw_rect(Rect2(0, GROUND_Y - 2, W, 10), g_top)
	c.draw_rect(Rect2(0, GROUND_Y + 8, W, 3), Color(0.5, 0.4, 0.25))
	for pb in _pebbles:
		var col := Color(0.5, 0.42, 0.33).lerp(Color(0.68, 0.6, 0.5), pb.c)
		c.draw_circle(Vector2(pb.x, pb.y), pb.r, col.darkened(0.25))
		c.draw_circle(Vector2(pb.x - 1, pb.y - 1), pb.r * 0.7, col)
	for gr in _grass:
		var base := Vector2(gr.x, GROUND_Y + 1)
		var sway := sin(t * 1.8 + gr.ph) * 2.5
		var h: float = gr.h
		c.draw_line(base, base + Vector2(-3 + sway, -h), Color(0.5, 0.56, 0.25), 2.0)
		c.draw_line(base, base + Vector2(2 + sway, -h * 0.8), Color(0.62, 0.66, 0.3), 2.0)

func _paint_brook(c: CanvasItem) -> void:
	# Margem úmida
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(BROOK_X0 - 14, GROUND_Y - 1), Vector2(BROOK_X1 + 14, GROUND_Y - 1),
		Vector2(BROOK_X1 + 4, GROUND_Y + 24), Vector2(BROOK_X0 - 4, GROUND_Y + 24)]), Color(0.4, 0.33, 0.22))
	# Água
	var top := PackedVector2Array()
	var x := BROOK_X0
	while x <= BROOK_X1:
		top.append(Vector2(x, GROUND_Y + 1 + sin(t * 3.0 + x * 0.08) * 1.5))
		x += 8.0
	var poly := top.duplicate()
	poly.append(Vector2(BROOK_X1 - 6, GROUND_Y + 20))
	poly.append(Vector2(BROOK_X0 + 6, GROUND_Y + 20))
	c.draw_colored_polygon(poly, Color(0.28, 0.55, 0.78, 0.92))
	for st in _brook_stones:
		var p := Vector2(st.x, st.y)
		c.draw_circle(p, st.r, Color(0.55, 0.57, 0.6))
		c.draw_circle(p + Vector2(-1.5, -1.5), st.r * 0.5, Color(0.78, 0.8, 0.82))
	c.draw_polyline(top, Color(0.75, 0.9, 1.0, 0.9), 2.0)
	for i in 6:
		var sx := BROOK_X0 + fmod(t * 30.0 + i * 37.0, BROOK_X1 - BROOK_X0 - 20.0) + 10.0
		var sy := GROUND_Y + 6.0 + (i % 3) * 4.0
		c.draw_line(Vector2(sx, sy), Vector2(sx + 10, sy), Color(1, 1, 1, 0.5), 1.5)
	for rd in _reeds:
		var base := Vector2(rd.x, GROUND_Y + 4)
		var sway := sin(t * 1.6 + rd.ph) * 3.0
		var tip := base + Vector2(sway, -rd.h)
		c.draw_line(base, tip, Color(0.4, 0.5, 0.22), 2.0)
		c.draw_line(tip + Vector2(0, 4), tip + Vector2(0, 14), Color(0.45, 0.3, 0.18), 4.0)
