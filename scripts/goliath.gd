extends CharacterBody2D

class_name GoliathBoss

signal boss_health_changed(new_health, max_health)
signal boss_state_changed(state_name)
signal boss_defeated
signal camera_shake_requested(intensity, duration)
signal critical_hit
signal enraged_started

enum State {
	INTRO,
	IDLE,
	WALK,
	TELEGRAPH_PUNCH,
	ATTACK_PUNCH,
	PUNCH_RECOVERY,
	TELEGRAPH_STOMP,
	ATTACK_STOMP,
	TELEGRAPH_THROW,
	ATTACK_THROW,
	THROW_RECOVERY,
	ROAR,
	STUNNED,
	DEAD,
}

const SHOCKWAVE_SCENE = preload("res://scenes/shockwave.tscn")
const SPEAR_SCENE = preload("res://scenes/spear.tscn")
const SPEECH_BUBBLE_SCENE = preload("res://scenes/speech_bubble.tscn")
const AudioManager = preload("res://scripts/audio_manager.gd")
const FX = preload("res://scripts/fx.gd")

const ARENA_MIN_X := 170.0
const ARENA_MAX_X := 1130.0
const PUNCH_REACH := 85.0
const PUNCH_ZONE_BACK := -50.0
const PUNCH_ZONE_FRONT := 165.0
const STOMP_RADIUS := 95.0

const HIT_LINES := [
	"Isso é tudo, pastorzinho?",
	"Ha! Mal senti isso!",
	"Vem cá, e darei tua carne às aves do céu!",
]
const PLAYER_HURT_LINES := [
	"Ha ha ha! Volte para as suas ovelhas!",
	"Ninguém vence o campeão de Gate!",
	"Israel não tem ninguém melhor?",
]
const CRIT_LINES := [
	"Argh! Minha cabeça!",
	"Como ousa?!",
]

@export var max_health: int = 100
var current_health: int = 100
var base_walk_speed: float = 80.0
var walk_speed: float = 80.0
var telegraph_mult: float = 1.0
var gravity: float = 1200.0

var is_enraged: bool = false
var current_state: State = State.INTRO
var state_timer: float = 0.0
var facing: float = -1.0
var throw_cooldown: float = 2.0
var spear_target: Vector2 = Vector2.ZERO
var _last_line_time: float = -10.0
var _current_bubble: Node = null

var target_player: CharacterBody2D = null

@onready var visual: Node2D = $Visuals
@onready var telegraph: Node2D = $Telegraph
@onready var head_area: Area2D = $Visuals/HeadArea
@onready var head_shape: CollisionShape2D = $Visuals/HeadArea/CollisionShape2D
@onready var body_area: Area2D = $Visuals/BodyArea

func _ready() -> void:
	current_health = max_health
	head_area.add_to_group("goliath_head")
	body_area.add_to_group("goliath_body")
	add_to_group("boss")
	_enter_state(State.INTRO)

func setup(hp: int, tele_mult: float, speed_mult: float, head_radius: float) -> void:
	max_health = hp
	current_health = hp
	telegraph_mult = tele_mult
	walk_speed = base_walk_speed * speed_mult
	var c := CircleShape2D.new()
	c.radius = head_radius
	head_shape.shape = c
	boss_health_changed.emit(current_health, max_health)

func start_fight() -> void:
	if current_state == State.INTRO:
		_enter_state(State.IDLE)

func say(text: String, duration: float = 3.0, bg_color: Color = Color(0.45, 0.12, 0.1)) -> void:
	if is_instance_valid(_current_bubble):
		_current_bubble.queue_free()
	var bubble = SPEECH_BUBBLE_SCENE.instantiate()
	get_parent().add_child(bubble)
	bubble.follow(self, -262.0)
	bubble.show_speech(text, duration, bg_color)
	_current_bubble = bubble
	_last_line_time = Time.get_ticks_msec() / 1000.0

func _maybe_say(lines: Array, chance: float = 0.5) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_line_time < 6.0 or randf() > chance or current_health <= 0:
		return
	say(lines[randi() % lines.size()], 2.4)

func taunt_player_hurt() -> void:
	_maybe_say(PLAYER_HURT_LINES, 0.7)

func set_target(player: CharacterBody2D) -> void:
	target_player = player

func _player_alive() -> bool:
	return target_player != null and target_player.has_method("is_alive") and target_player.is_alive()

func _dist_to_player() -> float:
	if not target_player:
		return 9999.0
	return absf(global_position.x - target_player.global_position.x)

# ------------------------------------------------------------------ Loop
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	state_timer -= delta
	throw_cooldown -= delta

	match current_state:
		State.INTRO:
			velocity.x = 0.0
			_look_at_player()
		State.IDLE:
			velocity.x = 0.0
			_look_at_player()
			if state_timer <= 0.0 and _player_alive():
				_choose_next_action()
		State.WALK:
			_look_at_player()
			velocity.x = facing * walk_speed
			if _dist_to_player() < 130.0:
				_enter_state(State.TELEGRAPH_PUNCH)
			elif state_timer <= 0.0:
				_choose_ranged_action()
		State.TELEGRAPH_PUNCH:
			velocity.x = 0.0
			telegraph.show_ground(Vector2(global_position.x + facing * (PUNCH_ZONE_BACK + PUNCH_ZONE_FRONT) * 0.5, global_position.y), PUNCH_ZONE_FRONT - PUNCH_ZONE_BACK, 1.0 - state_timer / _tele(1.1))
			if state_timer <= 0.0:
				_enter_state(State.ATTACK_PUNCH)
		State.ATTACK_PUNCH:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.PUNCH_RECOVERY)
		State.PUNCH_RECOVERY:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.IDLE)
		State.TELEGRAPH_STOMP:
			velocity.x = 0.0
			var prog := 1.0 - state_timer / _tele(0.95)
			telegraph.show_wave(Vector2(global_position.x + facing * 60.0, global_position.y), facing, is_enraged, prog)
			if state_timer <= 0.0:
				_enter_state(State.ATTACK_STOMP)
		State.ATTACK_STOMP:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.IDLE)
		State.TELEGRAPH_THROW:
			velocity.x = 0.0
			# Mira acompanha Davi até o último instante (e então trava)
			if state_timer > 0.35 and target_player:
				_look_at_player()
				spear_target = target_player.global_position + Vector2(0, -28)
			telegraph.show_line(_spear_origin(), spear_target, 1.0 - state_timer / _tele(1.05))
			if state_timer <= 0.0:
				_enter_state(State.ATTACK_THROW)
		State.ATTACK_THROW:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.THROW_RECOVERY)
		State.THROW_RECOVERY:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.IDLE)
		State.ROAR:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.IDLE)
		State.STUNNED:
			velocity.x = 0.0
			if state_timer <= 0.0:
				_enter_state(State.IDLE)
		State.DEAD:
			velocity.x = 0.0

	move_and_slide()
	global_position.x = clampf(global_position.x, ARENA_MIN_X, ARENA_MAX_X)
	_sync_visual()

func _tele(base: float) -> float:
	var t := base * telegraph_mult
	if is_enraged:
		t *= 0.75
	return t

func _enter_state(new_state: State) -> void:
	current_state = new_state
	boss_state_changed.emit(State.keys()[new_state])
	telegraph.clear()

	match new_state:
		State.INTRO:
			state_timer = 999.0
		State.IDLE:
			state_timer = randf_range(0.6, 1.2) * (0.7 if is_enraged else 1.0)
			visual.has_spear = true
		State.WALK:
			state_timer = randf_range(1.6, 2.8)
		State.TELEGRAPH_PUNCH:
			state_timer = _tele(1.1)
			AudioManager.play_sound(self, "drum_high", -6.0, 0.6)
		State.ATTACK_PUNCH:
			state_timer = 0.28
			_do_punch_impact()
		State.PUNCH_RECOVERY:
			state_timer = 1.15 if is_enraged else 1.6
		State.TELEGRAPH_STOMP:
			state_timer = _tele(0.95)
			AudioManager.play_sound(self, "drum_high", -6.0, 0.5)
		State.ATTACK_STOMP:
			state_timer = 0.5
			_do_stomp()
		State.TELEGRAPH_THROW:
			state_timer = _tele(1.05)
			if target_player:
				spear_target = target_player.global_position + Vector2(0, -28)
		State.ATTACK_THROW:
			state_timer = 0.3
			_throw_spear()
		State.THROW_RECOVERY:
			state_timer = 0.9
			throw_cooldown = randf_range(4.0, 6.0) * (0.7 if is_enraged else 1.0)
		State.ROAR:
			state_timer = 1.5
			AudioManager.play_sound(self, "roar", 2.0)
			camera_shake_requested.emit(10.0, 1.2)
			say("MALDITO SEJA PELOS MEUS DEUSES! VOU TE ESMAGAR!", 2.8, Color(0.6, 0.08, 0.06))
			enraged_started.emit()
		State.STUNNED:
			state_timer = 2.6
		State.DEAD:
			_die()

func _look_at_player() -> void:
	if not target_player:
		return
	var dir := signf(target_player.global_position.x - global_position.x)
	if dir != 0.0:
		facing = dir

func _choose_next_action() -> void:
	var dist := _dist_to_player()
	var r := randf()
	if dist < 150.0:
		if r < 0.7:
			_enter_state(State.TELEGRAPH_PUNCH)
		else:
			_enter_state(State.TELEGRAPH_STOMP)
	elif dist < 230.0:
		_enter_state(State.WALK if r < 0.6 else State.TELEGRAPH_STOMP)
	elif dist < 460.0:
		if r < 0.45:
			_enter_state(State.WALK)
		elif r < 0.75 or throw_cooldown > 0.0:
			_enter_state(State.TELEGRAPH_STOMP)
		else:
			_enter_state(State.TELEGRAPH_THROW)
	else:
		if throw_cooldown <= 0.0 and r < 0.6:
			_enter_state(State.TELEGRAPH_THROW)
		elif r < 0.8:
			_enter_state(State.WALK)
		else:
			_enter_state(State.TELEGRAPH_STOMP)

func _choose_ranged_action() -> void:
	if throw_cooldown <= 0.0 and randf() < 0.5:
		_enter_state(State.TELEGRAPH_THROW)
	elif randf() < 0.6:
		_enter_state(State.TELEGRAPH_STOMP)
	else:
		state_timer = 1.5

# ------------------------------------------------------------------ Ataques
func _do_punch_impact() -> void:
	var impact := Vector2(global_position.x + facing * PUNCH_REACH, global_position.y)
	camera_shake_requested.emit(13.0, 0.4)
	AudioManager.play_sound(self, "goliath_punch")
	FX.dust(get_parent(), impact, 18, 1.4)
	FX.rocks(get_parent(), impact, 12)
	if target_player and target_player.has_method("take_damage"):
		var rel := (target_player.global_position.x - global_position.x) * facing
		var high := target_player.global_position.y < global_position.y - 95.0
		if rel > PUNCH_ZONE_BACK and rel < PUNCH_ZONE_FRONT and not high:
			target_player.take_damage(1, global_position.x)

func _do_stomp() -> void:
	camera_shake_requested.emit(15.0, 0.5)
	AudioManager.play_sound(self, "stomp")
	var foot := Vector2(global_position.x + facing * 50.0, global_position.y)
	FX.dust(get_parent(), foot, 20, 1.5)
	_spawn_shockwave(facing)
	# Quem estiver colado nos pés do gigante também sente o pisão
	if target_player and target_player.has_method("take_damage"):
		var near := absf(target_player.global_position.x - global_position.x) < STOMP_RADIUS
		if near and target_player.global_position.y > global_position.y - 60.0:
			target_player.take_damage(1, global_position.x)
	if is_enraged:
		_spawn_shockwave(-facing)

func _spawn_shockwave(dir: float) -> void:
	var sw = SHOCKWAVE_SCENE.instantiate()
	get_parent().add_child(sw)
	sw.launch(Vector2(global_position.x + dir * 60.0, global_position.y), dir, 470.0 if is_enraged else 400.0)

func _spear_origin() -> Vector2:
	return visual.to_global(visual.spear_tip_pos)

func _throw_spear() -> void:
	var origin := _spear_origin()
	var spear = SPEAR_SCENE.instantiate()
	get_parent().add_child(spear)
	var speed := 820.0 if is_enraged else 740.0
	var to := spear_target - origin
	var tt := maxf(0.15, to.length() / speed)
	var g: float = spear.GRAVITY
	var vel := to / tt + Vector2(0, -0.5 * g * tt)
	spear.launch(origin, vel)
	visual.has_spear = false
	AudioManager.play_sound(self, "spear_throw")

# ------------------------------------------------------------------ Dano
func take_damage(amount: int, is_critical: bool = false) -> void:
	if current_health <= 0 or current_state == State.INTRO:
		return
	current_health = maxi(0, current_health - amount)
	boss_health_changed.emit(current_health, max_health)
	GameState.hits += 1
	if is_critical:
		GameState.crits += 1
		critical_hit.emit()

	var tween := create_tween()
	var flash := Color(2.0, 1.8, 0.4) if is_critical else Color(1.8, 0.5, 0.4)
	tween.tween_property(visual, "modulate", flash, 0.06)
	tween.tween_property(visual, "modulate", _base_modulate(), 0.14)

	if current_health <= 0:
		_enter_state(State.DEAD)
		return
	if not is_enraged and current_health <= int(max_health * 0.4):
		is_enraged = true
		walk_speed *= 1.5
		visual.enraged = true
		_enter_state(State.ROAR)
		return
	if is_critical and current_state != State.STUNNED and current_state != State.ROAR:
		_maybe_say(CRIT_LINES, 0.5)
		_enter_state(State.STUNNED)
	elif not is_critical:
		_maybe_say(HIT_LINES, 0.35)

func _base_modulate() -> Color:
	return Color(1.15, 0.85, 0.85) if is_enraged else Color(1, 1, 1)

func _die() -> void:
	telegraph.clear()
	visual.dead = true
	visual.warning = false
	boss_defeated.emit()
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(visual, "rotation", -1.45 * facing, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_fall_impact)

func _on_fall_impact() -> void:
	camera_shake_requested.emit(22.0, 0.8)
	AudioManager.play_sound(self, "stomp", 3.0, 0.7)
	var side := -1.0 if facing > 0 else 1.0
	FX.dust(get_parent(), global_position + Vector2(side * 120.0, 0), 30, 2.0)
	FX.dust(get_parent(), global_position + Vector2(side * 40.0, 0), 20, 1.6)

func _sync_visual() -> void:
	visual.scale.x = facing
	var pose := "idle"
	match current_state:
		State.WALK: pose = "walk"
		State.TELEGRAPH_PUNCH: pose = "punch_windup"
		State.ATTACK_PUNCH: pose = "punch"
		State.PUNCH_RECOVERY: pose = "recover"
		State.TELEGRAPH_STOMP: pose = "stomp_windup"
		State.ATTACK_STOMP: pose = "stomp"
		State.TELEGRAPH_THROW: pose = "throw_windup"
		State.ATTACK_THROW, State.THROW_RECOVERY: pose = "throw"
		State.ROAR: pose = "roar"
		State.STUNNED: pose = "stunned"
		State.DEAD: pose = "dead"
	if current_state == State.THROW_RECOVERY and state_timer < 0.5:
		pose = "idle"
	visual.pose = pose
	visual.walk_ratio = 1.0 if current_state == State.WALK else 0.0
	visual.warning = current_state in [State.TELEGRAPH_PUNCH, State.TELEGRAPH_STOMP, State.TELEGRAPH_THROW]
	head_area.position = visual.head_pos
	body_area.position = visual.body_pos
	body_area.rotation = visual.body_rot
