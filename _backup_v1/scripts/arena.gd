extends Node2D

const AudioManager = preload("res://scripts/audio_manager.gd")

@onready var david = $David
@onready var goliath = $Goliath
@onready var ui = $UI
@onready var camera: Camera2D = $Camera2D
@onready var brook_area: Area2D = $BrookArea
@onready var refill_hint: Label = $BrookArea/RefillHint

var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var player_in_brook: bool = false
var war_drums_timer: Timer = null
var is_muted: bool = false

func _ready() -> void:
	refill_hint.visible = false
	
	# Conexão de Golias
	goliath.set_target(david)
	goliath.boss_health_changed.connect(ui.update_goliath_health)
	goliath.boss_state_changed.connect(ui.update_goliath_state)
	goliath.camera_shake_requested.connect(trigger_camera_shake)
	goliath.boss_defeated.connect(_on_goliath_defeated)
	
	# Conexão de Davi
	david.health_changed.connect(ui.update_david_health)
	david.stones_changed.connect(ui.update_stones)
	david.sling_charge_updated.connect(ui.update_charge)
	david.died.connect(_on_david_died)
	
	# Inicialização de valores na UI
	ui.update_david_health(david.current_health, david.max_health)
	ui.update_stones(david.current_stones, david.max_stones)
	ui.update_goliath_health(goliath.current_health, goliath.max_health)
	
	# Zona do riacho
	brook_area.body_entered.connect(_on_brook_entered)
	brook_area.body_exited.connect(_on_brook_exited)
	
	# Percussão ambiente de guerra
	war_drums_timer = AudioManager.start_war_drums(self)

func _process(delta: float) -> void:
	# Mutar/Desmutar som geral com M
	if Input.is_action_just_pressed("ui_cancel") or Input.is_key_pressed(KEY_M):
		if not is_muted:
			is_muted = true
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
		else:
			is_muted = false
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)

	# Reiniciar partida
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		
	# Ação de recolher pedras no riacho
	if player_in_brook:
		if Input.is_key_pressed(KEY_E) or david.current_stones == 0:
			david.refill_stones()
			refill_hint.text = "Pedras recolhidas no ribeiro!"
			
	# Processamento do Screen Shake
	if shake_timer > 0.0:
		shake_timer -= delta
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO

func trigger_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _on_brook_entered(body: Node2D) -> void:
	if body == david:
		player_in_brook = true
		refill_hint.text = "Ribeiro: Pressione [ E ] para pegar pedras lisas"
		refill_hint.visible = true

func _on_brook_exited(body: Node2D) -> void:
	if body == david:
		player_in_brook = false
		refill_hint.visible = false

func _on_goliath_defeated() -> void:
	ui.show_victory()

func _on_david_died() -> void:
	ui.show_game_over()
