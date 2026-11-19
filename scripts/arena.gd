extends Node2D

# Orquestra a partida: introdução, música, câmera, ribeiro, itens e fim de jogo.

const AudioManager = preload("res://scripts/audio_manager.gd")
const FX = preload("res://scripts/fx.gd")
const HEAL_SCENE = preload("res://scenes/heal_pickup.tscn")

const DAVID_CRIT_LINES := [
	"O Senhor me livrou do leão e do urso!",
	"A batalha é do Senhor!",
	"Em nome do Senhor dos Exércitos!",
]

@onready var david: DavidPlayer = $David
@onready var goliath: GoliathBoss = $Goliath
@onready var ui = $UI
@onready var camera: Camera2D = $Camera2D
@onready var background = $Background
@onready var brook_area: Area2D = $BrookArea
@onready var refill_hint: Label = $BrookArea/RefillHint

var settings: Dictionary = {}
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var shake_duration: float = 0.1
var match_time: float = 0.0
var match_running: bool = false
var match_over: bool = false
var heal_timer: float = 20.0
var _music_node: Node
var _music_timer: Timer
var _music_step: int = 0
var _last_david_line: float = -10.0

func _ready() -> void:
	Engine.time_scale = 1.0
	_debug_hooks()
	settings = GameState.get_settings()
	GameState.reset_stats()
	refill_hint.visible = false

	ui.arena = self
	goliath.set_target(david)
	goliath.boss_health_changed.connect(ui.update_goliath_health)
	goliath.boss_state_changed.connect(ui.update_goliath_state)
	goliath.camera_shake_requested.connect(trigger_camera_shake)
	goliath.boss_defeated.connect(_on_goliath_defeated)
	goliath.critical_hit.connect(_on_critical_hit)
	goliath.enraged_started.connect(_on_enraged)

	david.health_changed.connect(ui.update_david_health)
	david.stones_changed.connect(_on_stones_changed)
	david.died.connect(_on_david_died)
	david.hurt.connect(_on_david_hurt)

	david.setup(settings.david_hearts, settings.stones, settings.aim_assist)
	goliath.setup(settings.boss_hp, settings.telegraph_mult, settings.boss_speed_mult, settings.head_radius)
	goliath.visual.weak_glow = 1.0 if settings.aim_assist else 0.4
	heal_timer = settings.heal_interval

	brook_area.body_entered.connect(_on_brook_entered)
	brook_area.body_exited.connect(_on_brook_exited)

	_start_music()

	if GameState.skip_title:
		_start_match()
	else:
		david.controls_enabled = false
		ui.show_title()
		get_tree().paused = true

func _start_match() -> void:
	david.controls_enabled = true
	david.can_fire = false
	get_tree().create_timer(0.4, false).timeout.connect(_intro_goliath_line)
	get_tree().create_timer(2.4, false).timeout.connect(_intro_david_line)
	get_tree().create_timer(4.2, false).timeout.connect(_begin_fight)

func _intro_goliath_line() -> void:
	goliath.say("Sou eu algum cão, para vires a mim com paus e pedras?!", 2.2)

func _intro_david_line() -> void:
	david.say("Tu vens contra mim com espada e lança, mas eu vou em nome do Senhor dos Exércitos!", 2.6)

func _begin_fight() -> void:
	if match_over:
		return
	match_running = true
	david.can_fire = true
	goliath.start_fight()
	ui.show_banner("LUTE!", Color(1.0, 0.85, 0.3), 0.5)
	AudioManager.play_sound(_music_node, "drum_low", 0.0, 0.8)

func _process(delta: float) -> void:
	if match_running and not match_over:
		match_time += delta
		ui.set_time(match_time)
		_tick_heal_spawn(delta)

	# Tremor de câmera
	if shake_timer > 0.0:
		shake_timer -= delta
		var k := clampf(shake_timer / shake_duration, 0.0, 1.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity * k
	else:
		camera.offset = Vector2.ZERO

	# Dica do ribeiro
	if david.in_brook:
		refill_hint.visible = true
		refill_hint.text = "Pegando pedras lisas do ribeiro..." if david.current_stones < david.max_stones else "Alforje cheio!"

func trigger_camera_shake(intensity: float, duration: float) -> void:
	if intensity >= shake_intensity * (shake_timer / maxf(0.01, shake_duration)):
		shake_intensity = intensity
		shake_duration = duration
		shake_timer = duration

func _zoom_punch(amount: float = 0.05) -> void:
	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2.ONE * (1.0 + amount), 0.06)
	tw.tween_property(camera, "zoom", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _hitstop(duration: float, scale: float = 0.05) -> void:
	Engine.time_scale = scale
	get_tree().create_timer(duration, true, false, true).timeout.connect(_end_hitstop)

func _end_hitstop() -> void:
	if not match_over:
		Engine.time_scale = 1.0

# ------------------------------------------------------------------ Eventos
func _on_stones_changed(count: int, max_count: int) -> void:
	ui.update_stones(count, max_count)

func _on_critical_hit() -> void:
	_hitstop(0.09)
	_zoom_punch(0.06)
	trigger_camera_shake(9.0, 0.3)
	background.cheer(true, 2.0)
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_david_line > 8.0 and goliath.current_health > 0:
		_last_david_line = now
		david.say(DAVID_CRIT_LINES[randi() % DAVID_CRIT_LINES.size()], 1.8)

func _on_enraged() -> void:
	ui.show_banner("FÚRIA!", Color(1.0, 0.3, 0.2), 0.6)
	_music_timer.wait_time = 0.15

func _on_david_hurt() -> void:
	trigger_camera_shake(10.0, 0.3)
	background.cheer(false, 1.5)
	if david.current_health > 0:
		goliath.taunt_player_hurt()

func _on_goliath_defeated() -> void:
	match_over = true
	match_running = false
	david.controls_enabled = false
	Engine.time_scale = 0.3
	_zoom_punch(0.1)
	background.cheer(true, 8.0)
	get_tree().create_timer(1.3, true, false, true).timeout.connect(_finish_victory)

func _finish_victory() -> void:
	Engine.time_scale = 1.0
	_music_timer.stop()
	AudioManager.play_sound(_music_node, "victory")
	david.say("A batalha é do Senhor!", 3.0)
	var record := GameState.register_time(match_time)
	get_tree().create_timer(1.6, false).timeout.connect(ui.show_victory.bind(match_time, record))

func _on_david_died() -> void:
	match_over = true
	match_running = false
	background.cheer(false, 6.0)
	_music_timer.stop()
	AudioManager.play_sound(_music_node, "defeat")
	get_tree().create_timer(0.8, false).timeout.connect(_defeat_line)
	get_tree().create_timer(2.2, false).timeout.connect(ui.show_game_over)

func _defeat_line() -> void:
	goliath.say("Ha ha ha! Quem mais quer lutar?", 2.0)

# ------------------------------------------------------------------ Ribeiro e itens
func _on_brook_entered(body: Node2D) -> void:
	if body == david:
		david.in_brook = true

func _on_brook_exited(body: Node2D) -> void:
	if body == david:
		david.in_brook = false
		refill_hint.visible = false

func _tick_heal_spawn(delta: float) -> void:
	if david.current_health >= david.max_health or david.current_health <= 0:
		return
	heal_timer -= delta
	if heal_timer > 0.0:
		return
	heal_timer = settings.heal_interval
	var x := randf_range(300.0, 1080.0)
	for i in 6:
		if absf(x - goliath.global_position.x) > 180.0:
			break
		x = randf_range(300.0, 1080.0)
	var heal = HEAL_SCENE.instantiate()
	heal.position = Vector2(x, -30)
	add_child(heal)
	heal.drop_from_sky()

# ------------------------------------------------------------------ Depuração
func _debug_hooks() -> void:
	# Argumentos opcionais (após "--"): --autoplay  --diff=0|1|2  --shots=f1,f2,...  --title
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--diff="):
			GameState.difficulty = int(a.get_slice("=", 1))
		elif a == "--autoplay":
			GameState.skip_title = true
			GameState.no_save = true
			var bot = load("res://scripts/debug_bot.gd").new()
			bot.arena = self
			bot.david = david
			bot.goliath = goliath
			bot.passive = "--passive" in args
			bot.idle = "--idle" in args
			add_child(bot)
		elif a == "--title":
			GameState.skip_title = false
		elif a.begins_with("--shots="):
			for f in a.get_slice("=", 1).split(","):
				_shot_frames.append(int(f))
	if not _shot_frames.is_empty():
		var st := ShotTaker.new()
		st.arena = self
		st.frames = _shot_frames
		st.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(st)

var _shot_frames: Array = []

class ShotTaker extends Node:
	var arena: Node
	var frames: Array = []
	var frame: int = 0
	func _physics_process(_delta: float) -> void:
		frame += 1
		if frame in frames:
			var img := get_viewport().get_texture().get_image()
			var dir := OS.get_environment("SHOT_DIR")
			if dir == "":
				dir = "user://"
			img.save_png("%s/shot_%05d.png" % [dir, frame])
			var g = arena.goliath
			var d = arena.david
			print("shot ", frame, " state=", g.State.keys()[g.current_state], " boss=", g.current_health, " david=", d.current_health, " stones=", d.current_stones, " dx=", int(d.global_position.x), " gx=", int(g.global_position.x))

# ------------------------------------------------------------------ Música
func _start_music() -> void:
	_music_node = Node.new()
	_music_node.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_node)
	_music_timer = Timer.new()
	_music_timer.wait_time = 0.2
	_music_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_timer.autostart = true
	_music_timer.ignore_time_scale = true
	_music_timer.timeout.connect(_music_tick)
	_music_node.add_child(_music_timer)

func _music_tick() -> void:
	# Tambores de guerra em 16 passos
	var low := [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0]
	var high := [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1]
	var step := _music_step % 16
	var vol := -14.0 if get_tree().paused else -9.0
	if low[step] == 1:
		AudioManager.play_sound(_music_node, "drum_low", vol)
	if high[step] == 1:
		AudioManager.play_sound(_music_node, "drum_high", vol - 4.0, 1.0 + (0.1 if step == 15 else 0.0))
	_music_step += 1
