extends CharacterBody2D

class_name GoliathBoss

signal boss_health_changed(new_health, max_health)
signal boss_state_changed(state_name)
signal boss_defeated
signal camera_shake_requested(intensity, duration)

enum State {
	IDLE,
	WALK,
	TELEGRAPH_PUNCH,
	ATTACK_PUNCH,
	PUNCH_RECOVERY,
	TELEGRAPH_STOMP,
	ATTACK_STOMP,
	STUNNED,
	DEAD
}

const SHOCKWAVE_SCENE = preload("res://scenes/shockwave.tscn")
const SPEECH_BUBBLE_SCENE = preload("res://scenes/speech_bubble.tscn")
const AudioManager = preload("res://scripts/audio_manager.gd")

@export var max_health: int = 100
var current_health: int = 100

@export var walk_speed: float = 75.0
@export var gravity: float = 1200.0

var is_enraged: bool = false

var current_state: State = State.IDLE
var state_timer: float = 0.0
var facing_direction: float = -1.0 # -1 para a esquerda (olhando para Davi)

var target_player: CharacterBody2D = null

@onready var visuals: Node2D = $Visuals
@onready var telegraph_marker: ColorRect = $TelegraphMarker
@onready var punch_hitbox: Area2D = $Visuals/PunchHitbox
@onready var shockwave_spawn: Marker2D = $Visuals/ShockwaveSpawn
@onready var head_area: Area2D = $Visuals/HeadArea
@onready var body_area: Area2D = $Visuals/BodyArea
@onready var stun_indicator: Node2D = $Visuals/StunIndicator

func _ready() -> void:
	current_health = max_health
	boss_health_changed.emit(current_health, max_health)
	telegraph_marker.visible = false
	punch_hitbox.monitoring = false
	
	# Grupos de colisão para as pedras identificarem
	head_area.add_to_group("goliath_head")
	body_area.add_to_group("goliath_body")
	
	_enter_state(State.IDLE)
	
	# Provocacao biblica de abertura
	get_tree().create_timer(0.6).timeout.connect(func():
		say("Sou eu algum cão, para vir a mim com paus e pedras?!", 3.2, Color(0.35, 0.15, 0.15, 0.9))
	)

func say(text: String, duration: float = 3.0, bg_color: Color = Color(0.1, 0.1, 0.1, 0.85)) -> void:
	var bubble = SPEECH_BUBBLE_SCENE.instantiate()
	bubble.position = Vector2(0, -225)
	add_child(bubble)
	bubble.show_speech(text, duration, bg_color)

func set_target(player: CharacterBody2D) -> void:
	target_player = player

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	state_timer -= delta
	
	match current_state:
		State.IDLE:
			velocity.x = 0.0
			_look_at_player()
			if state_timer <= 0.0:
				_choose_next_action()
				
		State.WALK:
			_look_at_player()
			velocity.x = facing_direction * walk_speed
			
			if target_player:
				var dist = abs(global_position.x - target_player.global_position.x)
				# Se estiver perto o bastante, prepara o soco
				if dist < 170.0:
					_enter_state(State.TELEGRAPH_PUNCH)
				elif state_timer <= 0.0:
					# Alterna para pisão ou continua
					if randf() > 0.4:
						_enter_state(State.TELEGRAPH_STOMP)
					else:
						state_timer = 2.0
						
		State.TELEGRAPH_PUNCH:
			velocity.x = 0.0
			# Mostra marcador onde o soco vai cair
			if telegraph_marker:
				telegraph_marker.visible = true
				telegraph_marker.modulate.a = 0.5 + sin(Time.get_ticks_msec() * 0.02) * 0.4
			if state_timer <= 0.0:
				_enter_state(State.ATTACK_PUNCH)
				
		State.ATTACK_PUNCH:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.PUNCH_RECOVERY)
				
		State.PUNCH_RECOVERY:
			velocity.x = 0.0
			# Punho preso no chão dando janela para Davi acertar a cabeça!
			if state_timer <= 0.0:
				_enter_state(State.IDLE)
				
		State.TELEGRAPH_STOMP:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.ATTACK_STOMP)
				
		State.ATTACK_STOMP:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.IDLE)
				
		State.STUNNED:
			velocity.x = 0.0
			visuals.modulate = Color(1.3, 1.3, 0.4) if fmod(state_timer, 0.2) > 0.1 else Color(1, 1, 1)
			if stun_indicator:
				stun_indicator.position.x = sin(Time.get_ticks_msec() * 0.008) * 12.0
			if state_timer <= 0.0:
				visuals.modulate = Color(1, 1, 1)
				if stun_indicator:
					stun_indicator.visible = false
				_enter_state(State.IDLE)
				
		State.DEAD:
			velocity.x = 0.0

	move_and_slide()

func _enter_state(new_state: State) -> void:
	current_state = new_state
	boss_state_changed.emit(State.keys()[new_state])
	
	match new_state:
		State.IDLE:
			state_timer = randf_range(0.8, 1.5)
			telegraph_marker.visible = false
			punch_hitbox.monitoring = false
			
		State.WALK:
			state_timer = randf_range(2.0, 3.5)
			telegraph_marker.visible = false
			
		State.TELEGRAPH_PUNCH:
			state_timer = 0.75 if is_enraged else 1.1 # Mais rapido se enfurecido!
			telegraph_marker.visible = true
			# Posiciona o marcador na frente de Golias
			telegraph_marker.position.x = 70.0 * facing_direction - telegraph_marker.size.x * 0.5
			
		State.ATTACK_PUNCH:
			state_timer = 0.3
			telegraph_marker.visible = false
			punch_hitbox.monitoring = true
			camera_shake_requested.emit(12.0, 0.4)
			AudioManager.play_sound(get_parent(), "goliath_punch")
			_check_punch_hit()
			
		State.PUNCH_RECOVERY:
			state_timer = 1.6 # 1.6s vulnerável com o braço no chão
			punch_hitbox.monitoring = false
			
		State.TELEGRAPH_STOMP:
			state_timer = 0.9
			
		State.ATTACK_STOMP:
			state_timer = 0.4
			camera_shake_requested.emit(15.0, 0.5)
			_spawn_shockwave()
			
		State.STUNNED:
			state_timer = 2.5
			telegraph_marker.visible = false
			punch_hitbox.monitoring = false
			if stun_indicator:
				stun_indicator.visible = true
			
		State.DEAD:
			telegraph_marker.visible = false
			punch_hitbox.monitoring = false
			boss_defeated.emit()
			# Deita Golias no chão
			var tween = create_tween()
			tween.tween_property(visuals, "rotation_degrees", -85.0 * facing_direction, 1.2)

func _look_at_player() -> void:
	if not target_player:
		return
	var dir = sign(target_player.global_position.x - global_position.x)
	if dir != 0.0 and dir != facing_direction:
		facing_direction = dir
		visuals.scale.x = abs(visuals.scale.x) * (1.0 if facing_direction > 0 else -1.0)

func _choose_next_action() -> void:
	if not target_player:
		_enter_state(State.IDLE)
		return
	var dist = abs(global_position.x - target_player.global_position.x)
	if dist < 180.0:
		_enter_state(State.TELEGRAPH_PUNCH)
	else:
		_enter_state(State.WALK)

func _check_punch_hit() -> void:
	if not target_player:
		return
	# Verifica se Davi está na zona do soco
	var punch_center = global_position + Vector2(facing_direction * 80.0, 0.0)
	var dist = punch_center.distance_to(target_player.global_position)
	if dist < 85.0:
		target_player.take_damage(1)

func _spawn_shockwave() -> void:
	var shockwave = SHOCKWAVE_SCENE.instantiate()
	var spawn_pos = shockwave_spawn.global_position
	# Desce o spawn para o nivel do chao
	spawn_pos.y = global_position.y
	get_parent().add_child(shockwave)
	shockwave.launch(spawn_pos, facing_direction)

func take_damage(amount: int, is_critical: bool = false) -> void:
	if current_health <= 0:
		return
		
	current_health = max(0, current_health - amount)
	boss_health_changed.emit(current_health, max_health)
	
	# Verifica se entrou em estado de furia (< 40% de vida)
	if current_health <= 40 and not is_enraged:
		is_enraged = true
		walk_speed = 120.0
		say("MALDITO SEJA PELOS MEUS DEUSES! VOU TE ESMAGAR!", 3.0, Color(0.5, 0.1, 0.1, 0.95))
		# Alerta visual de furia
		var rage_tween = create_tween()
		rage_tween.tween_property(visuals, "modulate", Color(1.8, 0.4, 0.4), 0.3)
		rage_tween.tween_property(visuals, "modulate", Color(1.2, 0.8, 0.8), 0.3)
	
	# Efeito visual de dano
	var tween = create_tween()
	var flash_color = Color(2.0, 1.8, 0.3) if is_critical else Color(1.8, 0.3, 0.3)
	tween.tween_property(visuals, "modulate", flash_color, 0.08)
	var normal_color = Color(1.2, 0.8, 0.8) if is_enraged else Color(1, 1, 1)
	tween.tween_property(visuals, "modulate", normal_color, 0.12)
	
	if is_critical and current_state != State.DEAD:
		# Acerto na testa atordoa imediatamente Golias!
		_enter_state(State.STUNNED)
		
	if current_health <= 0:
		_enter_state(State.DEAD)
