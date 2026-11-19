extends Node2D

class_name SpeechBubble

@onready var label: Label = $Panel/Label
@onready var panel: Panel = $Panel

func show_speech(text: String, duration: float = 3.0, bg_color: Color = Color(0.1, 0.1, 0.1, 0.85)) -> void:
	label.text = text
	panel.self_modulate = bg_color
	
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
