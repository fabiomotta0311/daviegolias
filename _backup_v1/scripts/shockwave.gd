extends Area2D

class_name ShockwaveProjectile

@export var speed: float = 380.0
var direction: float = -1.0
var lifetime: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func launch(start_pos: Vector2, move_dir: float) -> void:
	global_position = start_pos
	direction = move_dir
	scale.x = 1.0 if direction > 0 else -1.0

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	lifetime -= delta
	
	# Efeito de pulsar de poeira
	modulate.a = clamp(lifetime, 0.0, 1.0)
	
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# A onda de choque nao atinge o proprio Golias
	if body.name == "Goliath" or body.is_in_group("boss"):
		return
	if body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
