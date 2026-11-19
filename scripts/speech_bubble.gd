extends Node2D

class_name SpeechBubble

# Balão de fala estilo pergaminho que segue o personagem e não sai da tela.

@onready var label: Label = $Panel/Label
@onready var panel: Panel = $Panel

var _target: Node2D = null
var _offset_y: float = -80.0
var _border: Color = Color(0.3, 0.2, 0.1)

func _ready() -> void:
	top_level = true
	z_as_relative = false
	z_index = 20

func follow(target: Node2D, offset_y: float) -> void:
	_target = target
	_offset_y = offset_y
	_update_position()

func show_speech(text: String, duration: float = 3.0, border_color: Color = Color(0.3, 0.2, 0.1)) -> void:
	_border = border_color
	label.text = text
	label.add_theme_color_override("font_color", Color(0.2, 0.12, 0.06))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.96, 0.87, 0.97)
	sb.border_color = border_color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(2, 3)
	panel.add_theme_stylebox_override("panel", sb)
	modulate.a = 0.0
	scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	_update_position()
	queue_redraw()

func _update_position() -> void:
	if is_instance_valid(_target):
		var p := _target.global_position + Vector2(0, _offset_y)
		p.x = clampf(p.x, 165.0, 1115.0)
		p.y = maxf(p.y, 140.0)
		global_position = p

func _draw() -> void:
	# Rabinho do balão apontando para quem fala
	var tx := 0.0
	if is_instance_valid(_target):
		tx = clampf(_target.global_position.x - global_position.x, -120.0, 120.0)
	var tail := PackedVector2Array([Vector2(tx - 10, -3), Vector2(tx + 10, -3), Vector2(tx * 1.1, 14)])
	draw_colored_polygon(tail, Color(0.99, 0.96, 0.87, 0.97))
	draw_polyline(PackedVector2Array([Vector2(tx - 10, -1), Vector2(tx * 1.1, 14), Vector2(tx + 10, -1)]), _border, 3.0)
