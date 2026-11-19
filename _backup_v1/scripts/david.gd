extends CharacterBody2D

class_name DavidPlayer

signal health_changed(new_health, max_health)
signal stones_changed(new_count, max_count)
signal sling_charge_updated(ratio)
signal died

const STONE_SCENE = preload("res://scenes/stone.tscn")
const SPEECH_BUBBLE_SCENE = preload("res://scenes/speech_bubble.tscn")
const AudioManager = preload("res://scripts/audio_manager.gd")

@export var move_speed: float = 320.0
@export var jump_velocity: float = -520.0
@export var gravity: float = 1200.0

@export var max_health: int = 3
var current_health: int = 3

@export var max_stones: int = 5
var current_stones: int = 5

# Mecânica da Funda
var is_charging_sling: bool = false
var sling_charge: float = 0.0 # 0.0 a 1.0
const MIN_SLING_SPEED: float = 400.0
const MAX_SLING_SPEED: float = 950.0
const CHARGE_RATE: float = 1.4

# Esquiva / Dash
var is_dodging: bool = false
var dodge_timer: float = 0.0
const DODGE_DURATION: float = 0.3
const DODGE_SPEED: float = 650.0
var dodge_cooldown_timer: float = 0.0
const DODGE_COOLDOWN: float = 0.7
var dodge_direction: float = 1.0

# Invulnerabilidade pós-dano
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

@onready var visual_node: Node2D = $Visuals
@onready var sling_origin: Marker2D = $Visuals/SlingOrigin
@onready var trajectory_line: Line2D = $TrajectoryLine

func _ready() -> void:
	current_health = max_health
	current_stones = max_stones
	health_changed.emit(current_health, max_health)
	stones_changed.emit(current_stones, max_stones)
	if trajectory_line:
		trajectory_line.visible = false
		
	# Resposta biblica de Davi logo apos a fala de Golias
	get_tree().create_timer(3.8).timeout.connect(func():
		say("Tu vens contra mim com espada e lança, mas eu vou em nome do Senhor dos Exércitos!", 3.5, Color(0.18, 0.32, 0.5, 0.9))
	)

func say(text: String, duration: float = 3.0, bg_color: Color = Color(0.1, 0.1, 0.1, 0.85)) -> void:
	var bubble = SPEECH_BUBBLE_SCENE.instantiate()
	bubble.position = Vector2(0, -75)
	add_child(bubble)
	bubble.show_speech(text, duration, bg_color)

func _physics_process(delta: float) -> void:
	_handle_timers(delta)
	
	if current_health <= 0:
		return

	_handle_gravity(delta)
	_handle_dodge_input()
	_handle_movement(delta)
	_handle_sling_input(delta)
	
	move_and_slide()

func _handle_timers(delta: float) -> void:
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta
		
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			is_dodging = false
			modulate.a = 1.0
			
	if is_invulnerable and not is_dodging:
		invulnerable_timer -= delta
		# Efeito de piscar durante invulnerabilidade
		modulate.a = 0.4 if fmod(invulnerable_timer, 0.1) > 0.05 else 1.0
		if invulnerable_timer <= 0.0:
			is_invulnerable = false
			modulate.a = 1.0

func _handle_gravity(delta: float) -> void:
	if not is_on_floor() and not is_dodging:
		velocity.y += gravity * delta

func _handle_movement(_delta: float) -> void:
	if is_dodging:
		velocity.x = dodge_direction * DODGE_SPEED
		velocity.y = 0.0
		return

	# Pulo
	if is_on_floor() and (Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE)):
		if not is_charging_sling:
			velocity.y = jump_velocity

	# Direção horizontal
	var direction := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1.0

	var speed_multiplier := 0.55 if is_charging_sling else 1.0
	velocity.x = direction * move_speed * speed_multiplier

	# Virar visual para a direção em que anda ou mira
	if direction != 0.0 and not is_charging_sling:
		visual_node.scale.x = 1.0 if direction > 0 else -1.0
		dodge_direction = 1.0 if direction > 0 else -1.0
	elif is_charging_sling:
		# Mira acompanha a posição do mouse
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		visual_node.scale.x = 1.0 if mouse_dir.x >= 0 else -1.0
		dodge_direction = visual_node.scale.x

func _handle_dodge_input() -> void:
	var wants_dodge := Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_C) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if wants_dodge and not is_dodging and dodge_cooldown_timer <= 0.0 and is_on_floor():
		is_dodging = true
		is_charging_sling = false
		sling_charge = 0.0
		sling_charge_updated.emit(0.0)
		if trajectory_line:
			trajectory_line.visible = false
		dodge_timer = DODGE_DURATION
		dodge_cooldown_timer = DODGE_COOLDOWN
		modulate.a = 0.6 # Visual semi-transparente no dash
		AudioManager.play_sound(self, "dodge")

func _handle_sling_input(delta: float) -> void:
	var shoot_pressed := (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or 
		Input.is_key_pressed(KEY_J) or 
		Input.is_key_pressed(KEY_F) or 
		Input.is_key_pressed(KEY_K) or
		Input.is_key_pressed(KEY_ENTER)
	)
	
	if shoot_pressed and not is_dodging:
		if not is_charging_sling:
			is_charging_sling = true
			sling_charge = 0.0
		
		sling_charge = min(sling_charge + delta * CHARGE_RATE, 1.0)
		sling_charge_updated.emit(sling_charge)
		_update_trajectory_preview()
	else:
		if is_charging_sling:
			# Soltou o botão: dispara a pedra!
			_fire_stone()
			is_charging_sling = false
			sling_charge = 0.0
			sling_charge_updated.emit(0.0)
			if trajectory_line:
				trajectory_line.visible = false

func _update_trajectory_preview() -> void:
	if not trajectory_line:
		return
	trajectory_line.visible = true
	trajectory_line.clear_points()
	
	var origin = sling_origin.global_position
	var aim_dir = (get_global_mouse_position() - origin).normalized()
	var launch_speed = lerp(MIN_SLING_SPEED, MAX_SLING_SPEED, sling_charge)
	var sim_vel = aim_dir * launch_speed
	var sim_pos = Vector2.ZERO
	var sim_gravity = 980.0
	
	# Simula os pontos da parábola
	for i in range(16):
		var t = i * 0.05
		var point = sim_vel * t + Vector2(0, 0.5 * sim_gravity * t * t)
		trajectory_line.add_point(point)

func _fire_stone() -> void:
	if current_stones <= 0:
		# Sem munição!
		_play_empty_click()
		return
	
	current_stones -= 1
	stones_changed.emit(current_stones, max_stones)
	
	var stone_instance = STONE_SCENE.instantiate()
	var spawn_pos = sling_origin.global_position
	var aim_dir = (get_global_mouse_position() - spawn_pos).normalized()
	var speed = lerp(MIN_SLING_SPEED, MAX_SLING_SPEED, sling_charge)
	
	get_parent().add_child(stone_instance)
	stone_instance.launch(spawn_pos, aim_dir * speed)
	AudioManager.play_sound(get_parent(), "stone_launch")

func refill_stones() -> void:
	if current_stones < max_stones:
		current_stones = max_stones
		stones_changed.emit(current_stones, max_stones)
		AudioManager.play_sound(self, "refill")

func take_damage(amount: int) -> void:
	if is_dodging or is_invulnerable or current_health <= 0:
		return
		
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	is_invulnerable = true
	invulnerable_timer = 1.0 # 1 segundo de imunidade pós dano
	
	# Recuo para trás (knockback)
	velocity.x = -dodge_direction * 280.0
	velocity.y = -200.0
	
	if current_health <= 0:
		died.emit()
		modulate = Color(0.7, 0.2, 0.2, 0.8)

func _play_empty_click() -> void:
	# Flash vermelho rápido no personagem indicando falta de pedras
	var tween = create_tween()
	tween.tween_property(visual_node, "modulate", Color(1.5, 0.4, 0.4), 0.1)
	tween.tween_property(visual_node, "modulate", Color(1, 1, 1), 0.1)
