extends Control

# Widgets desenhados do HUD: barra de vida de Golias e corações/pedras de Davi.

enum Kind { BOSS_BAR, DAVID_STATUS }

var kind: int = Kind.BOSS_BAR
var t: float = 0.0

# Barra de vida
var hp: float = 100.0
var hp_max: float = 100.0
var _trail: float = 100.0
var _shake: float = 0.0
var enraged: bool = false

# Davi
var hearts: int = 3
var hearts_max: int = 3
var stones: int = 5
var stones_max: int = 5
var _heart_pop: Array = []
var _stone_flash: float = 0.0

func _process(delta: float) -> void:
	t += delta
	_trail = move_toward(_trail, hp, delta * hp_max * 0.6) if _trail > hp else hp
	_shake = maxf(0.0, _shake - delta * 3.0)
	_stone_flash = maxf(0.0, _stone_flash - delta)
	for i in _heart_pop.size():
		_heart_pop[i] = maxf(0.0, _heart_pop[i] - delta * 2.5)
	queue_redraw()

func set_hp(v: float, m: float) -> void:
	if v < hp:
		_shake = 1.0
	hp = v
	hp_max = m

func set_hearts(v: int, m: int) -> void:
	if _heart_pop.size() != m:
		_heart_pop.resize(m)
		_heart_pop.fill(0.0)
	for i in m:
		if (i < v) != (i < hearts):
			_heart_pop[i] = 1.0
	hearts = v
	hearts_max = m

func set_stones(v: int, m: int) -> void:
	if v == 0 and stones > 0:
		_stone_flash = 2.0
	stones = v
	stones_max = m

func _draw() -> void:
	if kind == Kind.BOSS_BAR:
		_draw_boss_bar()
	else:
		_draw_status()

func _draw_boss_bar() -> void:
	var off := Vector2(randf_range(-3, 3), randf_range(-2, 2)) * _shake
	var r := Rect2(Vector2(0, 0) + off, size)
	var inner := r.grow(-4)
	draw_rect(r.grow(2), Color(0.12, 0.08, 0.05, 0.9))
	draw_rect(r, Color(0.75, 0.55, 0.25))
	draw_rect(inner, Color(0.18, 0.08, 0.06))
	var ratio := clampf(hp / maxf(1.0, hp_max), 0.0, 1.0)
	var trail_ratio := clampf(_trail / maxf(1.0, hp_max), 0.0, 1.0)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * trail_ratio, inner.size.y)), Color(1.0, 0.9, 0.7))
	var col := Color(0.82, 0.16, 0.12)
	if enraged:
		col = col.lerp(Color(1.0, 0.4, 0.1), 0.5 + 0.5 * sin(t * 8.0))
	var fill := Rect2(inner.position, Vector2(inner.size.x * ratio, inner.size.y))
	draw_rect(fill, col)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.35)), Color(1, 1, 1, 0.18))
	# Marca da fúria (40%)
	var mx := inner.position.x + inner.size.x * 0.4
	draw_line(Vector2(mx, inner.position.y - 4), Vector2(mx, inner.end.y + 4), Color(1.0, 0.85, 0.3), 2.0)
	# Rebites
	for p in [r.position + Vector2(8, size.y * 0.5), Vector2(r.end.x - 8, r.position.y + size.y * 0.5)]:
		draw_circle(p, 4.0, Color(0.95, 0.8, 0.45))

func _heart(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-5, -3) * s, 6.0 * s, col)
	draw_circle(c + Vector2(5, -3) * s, 6.0 * s, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-10.8, -1) * s, c + Vector2(10.8, -1) * s, c + Vector2(0, 11) * s]), col)

func _draw_status() -> void:
	var font := get_theme_default_font()
	# Corações
	for i in hearts_max:
		var pop: float = _heart_pop[i] if i < _heart_pop.size() else 0.0
		var s := 1.4 + pop * 0.6
		var c := Vector2(20 + i * 36, 22)
		_heart(c + Vector2(1.5, 2), s, Color(0, 0, 0, 0.35))
		if i < hearts:
			var beat := 1.0 + (sin(t * 6.0) * 0.06 if hearts == 1 else 0.0)
			_heart(c, s * beat, Color(0.9, 0.15, 0.2))
			draw_circle(c + Vector2(-5, -5) * s, 2.2 * s, Color(1, 0.7, 0.7, 0.8))
		else:
			_heart(c, s, Color(0.3, 0.25, 0.25, 0.8))
	# Pedras
	var y := 62.0
	for i in stones_max:
		var c2 := Vector2(18 + i * 26, y)
		draw_set_transform(c2, 0.0, Vector2(1.0, 0.8))
		if i < stones:
			draw_circle(Vector2.ZERO, 10.0, Color(0.25, 0.22, 0.2))
			draw_circle(Vector2.ZERO, 8.5, Color(0.74, 0.72, 0.68))
			draw_circle(Vector2(-3, -3), 3.0, Color(0.95, 0.95, 0.92))
		else:
			draw_arc(Vector2.ZERO, 8.5, 0.0, TAU, 16, Color(0.3, 0.25, 0.2, 0.6), 2.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	if stones == 0:
		var a := 0.6 + 0.4 * sin(t * 10.0)
		var txt := "Sem pedras! Vá ao ribeiro ou pegue as do chão"
		draw_string_outline(font, Vector2(4, y + 34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color(0, 0, 0, a))
		draw_string(font, Vector2(4, y + 34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.45, 0.35, a))
