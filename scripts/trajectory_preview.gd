extends Node2D

# Pontinhos que mostram a trajetória prevista da pedra.

const SIM_GRAVITY := 980.0
var _points: PackedVector2Array = PackedVector2Array()
var _t: float = 0.0

func _ready() -> void:
	top_level = true
	z_index = 5
	visible = false

func show_path(origin: Vector2, vel: Vector2) -> void:
	visible = true
	_points.clear()
	for i in range(1, 18):
		var tt := i * 0.045
		var p := origin + vel * tt + Vector2(0, 0.5 * SIM_GRAVITY * tt * tt)
		if p.y > 595.0:
			break
		_points.append(p)
	queue_redraw()

func hide_path() -> void:
	visible = false

func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()

func _draw() -> void:
	var n := _points.size()
	for i in n:
		var k := float(i) / maxf(1.0, n)
		var pulse := 0.5 + 0.5 * sin(_t * 12.0 - i * 0.8)
		var r := lerpf(4.0, 2.0, k)
		draw_circle(_points[i], r + 1.5, Color(0.2, 0.1, 0.0, 0.35 * (1.0 - k)))
		draw_circle(_points[i], r, Color(1.0, 0.95, 0.55, (0.95 - k * 0.7) * (0.7 + 0.3 * pulse)))
