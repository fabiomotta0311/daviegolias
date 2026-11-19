extends Node2D

class_name FloatingText

@onready var label: Label = $Label

func setup(text: String, color: Color, is_critical: bool) -> void:
	label.text = text
	label.modulate = color
	
	if is_critical:
		label.add_theme_font_size_override("font_size", 22)
		scale = Vector2(1.3, 1.3)
	else:
		label.add_theme_font_size_override("font_size", 16)
		
	var tween = create_tween()
	# Sobe e flutua para os lados suavemente
	var target_pos = position + Vector2(randf_range(-30, 30), -65.0)
	tween.parallel().tween_property(self, "position", target_pos, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.75).set_delay(0.3)
	tween.tween_callback(queue_free)
