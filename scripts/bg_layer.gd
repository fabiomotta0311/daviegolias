extends Node2D

# Camada do cenário: delega o desenho para o script background.gd.

var layer_id: int = 0
var painter: Node = null
var animated: bool = false

func _process(_delta: float) -> void:
	if animated:
		queue_redraw()

func _draw() -> void:
	if painter:
		painter.paint(self, layer_id)
