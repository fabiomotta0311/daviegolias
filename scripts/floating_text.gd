extends Node2D

class_name FloatingText

@onready var label: Label = $Label

func _ready() -> void:
	z_as_relative = false
	z_index = 15

func setup(text: String, color: Color, is_critical: bool) -> void:
	label.text = text
	label.modulate = color
	label.add_theme_constant_override("outline_size", 6)
	if is_critical:
		label.add_theme_font_size_override("font_size", 30)
		scale = Vector2(0.4, 0.4)
		var pop := create_tween()
		pop.tween_property(self, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		label.add_theme_font_size_override("font_size", 20)

	var tween := create_tween()
	var target_pos := position + Vector2(randf_range(-30, 30), -80.0)
	tween.parallel().tween_property(self, "position", target_pos, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tween.tween_callback(queue_free)
