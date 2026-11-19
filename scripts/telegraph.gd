extends Node2D

# Avisos visuais dos ataques de Golias (área do soco, onda de choque, mira da lança).

enum Mode { NONE, GROUND, WAVE, LINE }

var mode: int = Mode.NONE
var _center: Vector2
var _width: float = 140.0
var _dir: float = 1.0
var _both: bool = false
var _from: Vector2
var _to: Vector2
var _progress: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	top_level = true
	z_index = 1

func clear() -> void:
	mode = Mode.NONE
	queue_redraw()

func show_ground(center: Vector2, width: float, progress: float) -> void:
	mode = Mode.GROUND
	_center = center
	_width = width
	_progress = clampf(progress, 0.0, 1.0)

func show_wave(origin: Vector2, dir: float, both: bool, progress: float) -> void:
	mode = Mode.WAVE
	_center = origin
	_dir = dir
	_both = both
	_progress = clampf(progress, 0.0, 1.0)

func show_line(from: Vector2, to: Vector2, progress: float) -> void:
	mode = Mode.LINE
	_from = from
	_to = to
	_progress = clampf(progress, 0.0, 1.0)

func _process(delta: float) -> void:
	_t += delta
	if mode != Mode.NONE:
		queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * (10.0 + _progress * 20.0))
	match mode:
		Mode.GROUND:
			var a := 0.25 + 0.35 * pulse
			draw_set_transform(_center, 0.0, Vector2(1.0, 0.22))
			draw_circle(Vector2.ZERO, _width * 0.5, Color(0.95, 0.1, 0.05, a))
			draw_circle(Vector2.ZERO, _width * 0.5 * _progress, Color(1.0, 0.3, 0.1, 0.45))
			draw_arc(Vector2.ZERO, _width * 0.5, 0.0, TAU, 40, Color(1, 0.85, 0.3, 0.9), 4.0, true)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		Mode.WAVE:
			_draw_wave_arrow(_dir, pulse)
			if _both:
				_draw_wave_arrow(-_dir, pulse)
		Mode.LINE:
			var d := (_to - _from)
			var len := d.length()
			if len < 1.0:
				return
			var n := d / len
			var step := 22.0
			var s := fmod(_t * 160.0, step)
			var col := Color(1.0, 0.15, 0.1, 0.35 + 0.5 * pulse)
			while s < len:
				var e := minf(s + 12.0, len)
				draw_line(_from + n * s, _from + n * e, col, 3.0 + _progress * 2.0)
				s += step
			# Alvo
			var r := lerpf(40.0, 18.0, _progress)
			draw_arc(_to, r, 0.0, TAU, 32, Color(1, 0.2, 0.1, 0.9), 3.0, true)
			draw_line(_to + Vector2(-r - 6, 0), _to + Vector2(-r + 8, 0), Color(1, 0.2, 0.1), 3.0)
			draw_line(_to + Vector2(r - 8, 0), _to + Vector2(r + 6, 0), Color(1, 0.2, 0.1), 3.0)
			draw_line(_to + Vector2(0, -r - 6), _to + Vector2(0, -r + 8), Color(1, 0.2, 0.1), 3.0)
			draw_line(_to + Vector2(0, r - 8), _to + Vector2(0, r + 6), Color(1, 0.2, 0.1), 3.0)

func _draw_wave_arrow(dir: float, pulse: float) -> void:
	# Rachaduras no chão apontando para onde a onda vai
	var base := _center + Vector2(0, -2)
	var col := Color(1.0, 0.2, 0.1, 0.35 + 0.45 * pulse)
	for i in 4:
		var x0 := base.x + dir * (20.0 + i * 55.0) * (0.4 + _progress * 0.6)
		var tri := PackedVector2Array([
			Vector2(x0, base.y - 10), Vector2(x0 + dir * 26.0, base.y - 2), Vector2(x0, base.y + 6)])
		draw_colored_polygon(tri, col)
