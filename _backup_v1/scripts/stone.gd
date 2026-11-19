extends Area2D

class_name SlingStone

const AudioManager = preload("res://scripts/audio_manager.gd")
const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")

signal hit_target(target, is_critical)

@export var stone_gravity: float = 980.0
var velocity: Vector2 = Vector2.ZERO
var damage_base: int = 10
var damage_critical: int = 35

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func launch(start_pos: Vector2, initial_velocity: Vector2) -> void:
	global_position = start_pos
	velocity = initial_velocity
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	velocity.y += stone_gravity * delta
	global_position += velocity * delta
	rotation = velocity.angle()
	
	# Destroi se cair muito abaixo da tela ou voar longe demais
	if global_position.y > 1000 or global_position.x < -200 or global_position.x > 1800:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Bateu no chão ou parede estática
	if body is StaticBody2D:
		_create_dust_effect()
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("goliath_head"):
		# Acerto crítico na testa de Golias!
		hit_target.emit(area.owner, true)
		if area.owner.has_method("take_damage"):
			area.owner.take_damage(damage_critical, true)
		_spawn_floating_text(area.global_position, "CRÍTICO! -35", Color(1.0, 0.9, 0.2), true)
		AudioManager.play_sound(get_parent(), "hit_critical")
		_create_critical_spark()
		queue_free()
	elif area.is_in_group("goliath_body"):
		# Acerto normal no corpo de Golias
		hit_target.emit(area.owner, false)
		if area.owner.has_method("take_damage"):
			area.owner.take_damage(damage_base, false)
		_spawn_floating_text(area.global_position, "-10", Color(1.0, 1.0, 1.0), false)
		AudioManager.play_sound(get_parent(), "hit_body")
		_create_dust_effect()
		queue_free()

func _spawn_floating_text(pos: Vector2, text: String, color: Color, is_critical: bool) -> void:
	var ftext = FLOATING_TEXT_SCENE.instantiate()
	ftext.position = pos
	get_parent().add_child(ftext)
	ftext.setup(text, color, is_critical)

func _create_dust_effect() -> void:
	# Placeholder visual de impacto
	pass

func _create_critical_spark() -> void:
	# Placeholder visual de crítico
	pass
