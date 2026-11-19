extends Area2D

class_name SlingStone

# Pedra lisa lançada pela funda de Davi.

const AudioManager = preload("res://scripts/audio_manager.gd")
const FX = preload("res://scripts/fx.gd")
const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const PICKUP_PATH := "res://scenes/stone_pickup.tscn"

const GROUND_Y := 590.0

@export var stone_gravity: float = 980.0
var velocity: Vector2 = Vector2.ZERO
var damage_base: int = 10
var damage_critical: int = 35
var homing: bool = false
var _alive: bool = true
var _spin: float = 0.0
var _trail: Array[Vector2] = []

func _ready() -> void:
	z_index = 4
	body_entered.connect(_on_body_entered)

func launch(start_pos: Vector2, initial_velocity: Vector2, assist: bool = false) -> void:
	global_position = start_pos
	velocity = initial_velocity
	homing = assist

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if homing:
		_steer_to_head(delta)
	velocity.y += stone_gravity * delta
	global_position += velocity * delta
	_spin += delta * 18.0
	_trail.push_front(global_position)
	if _trail.size() > 9:
		_trail.pop_back()
	queue_redraw()

	# Verifica acertos (prioriza a testa)
	var head_hit: Area2D = null
	var body_hit: Area2D = null
	for a in get_overlapping_areas():
		if a.is_in_group("goliath_head"):
			head_hit = a
		elif a.is_in_group("goliath_body"):
			body_hit = a
	if head_hit:
		_hit_goliath(head_hit, true)
	elif body_hit:
		_hit_goliath(body_hit, false)
	elif global_position.y >= GROUND_Y:
		_land(Vector2(global_position.x, GROUND_Y))

func _steer_to_head(delta: float) -> void:
	var heads := get_tree().get_nodes_in_group("goliath_head")
	if heads.is_empty():
		return
	var head: Node2D = heads[0]
	var to := head.global_position - global_position
	if to.length() < 170.0 and velocity.dot(to) > 0.0:
		var diff := velocity.angle_to(to)
		velocity = velocity.rotated(clampf(diff, -3.0 * delta, 3.0 * delta))

func _on_body_entered(body: Node2D) -> void:
	if _alive and body is StaticBody2D:
		_land(global_position)

func _hit_goliath(area: Area2D, critical: bool) -> void:
	_alive = false
	var boss = area.owner
	if boss and boss.has_method("take_damage"):
		boss.take_damage(damage_critical if critical else damage_base, critical)
	if critical:
		_spawn_floating_text(area.global_position + Vector2(0, -20), "CRÍTICO! -%d" % damage_critical, Color(1.0, 0.88, 0.2), true)
		AudioManager.play_sound(get_parent(), "hit_critical")
		FX.sparks(get_parent(), global_position)
	else:
		_spawn_floating_text(global_position, "-%d" % damage_base, Color(1.0, 1.0, 1.0), false)
		AudioManager.play_sound(get_parent(), "hit_body")
		FX.burst(get_parent(), global_position, Color(0.9, 0.75, 0.4), 10, 200.0, 0.4, 3.0, 400.0)
	queue_free()

func _land(pos: Vector2) -> void:
	_alive = false
	FX.dust(get_parent(), Vector2(pos.x, minf(pos.y, GROUND_Y)), 6, 0.5)
	# A pedra fica no chão para Davi recolher de novo
	var pickup = load(PICKUP_PATH).instantiate()
	get_parent().call_deferred("add_child", pickup)
	pickup.position = Vector2(clampf(pos.x, 24.0, 1256.0), GROUND_Y)
	queue_free()

func _spawn_floating_text(pos: Vector2, text: String, color: Color, is_critical: bool) -> void:
	var ftext = FLOATING_TEXT_SCENE.instantiate()
	ftext.position = pos
	get_parent().add_child(ftext)
	ftext.setup(text, color, is_critical)

func _draw() -> void:
	for i in range(1, _trail.size()):
		var k := float(i) / _trail.size()
		draw_circle(to_local(_trail[i]), 5.0 * (1.0 - k), Color(1.0, 1.0, 0.9, 0.35 * (1.0 - k)))
	draw_set_transform(Vector2.ZERO, _spin, Vector2(1.0, 0.8))
	draw_circle(Vector2.ZERO, 7.0, Color(0.38, 0.36, 0.34))
	draw_circle(Vector2.ZERO, 6.0, Color(0.7, 0.69, 0.66))
	draw_circle(Vector2(-2, -2), 2.5, Color(0.92, 0.92, 0.9))
