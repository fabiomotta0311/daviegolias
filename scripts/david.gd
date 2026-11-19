extends CharacterBody2D

class_name DavidPlayer

signal health_changed(new_health, max_health)
signal stones_changed(new_count, max_count)
signal sling_charge_updated(ratio)
signal died
signal hurt
signal stone_fired

const STONE_SCENE = preload("res://scenes/stone.tscn")
const SPEECH_BUBBLE_SCENE = preload("res://scenes/speech_bubble.tscn")
const AudioManager = preload("res://scripts/audio_manager.gd")
const FX = preload("res://scripts/fx.gd")

# Movimento
const MOVE_SPEED := 330.0
const ACCEL := 2600.0
const AIR_ACCEL := 1800.0
const FRICTION := 3000.0
const JUMP_VELOCITY := -590.0
const GRAVITY := 1400.0
const FALL_MULT := 1.5
const JUMP_CUT_MULT := 2.4
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12

# Funda
const MIN_SLING_SPEED := 430.0
const MAX_SLING_SPEED := 1000.0
const CHARGE_RATE := 1.3

# Esquiva
const DODGE_DURATION := 0.32
const DODGE_SPEED := 680.0
const DODGE_COOLDOWN := 0.55

var max_health: int = 3
var current_health: int = 3
var max_stones: int = 5
var current_stones: int = 5
var aim_assist: bool = false
var controls_enabled: bool = true
var can_fire: bool = true
const VISUAL_SCALE := 1.2

var is_charging_sling: bool = false
var sling_charge: float = 0.0
var virtual_aim_dir: Vector2 = Vector2.ZERO
var keyboard_aim: bool = false
var kb_aim_deg: float = 40.0
var _spin_sound_timer: float = 0.0

var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var air_dodge_used: bool = false
var facing: float = 1.0

var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0
var hurt_lock: float = 0.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var in_brook: bool = false
var _brook_pick_timer: float = 0.0

var _current_bubble: Node = null

@onready var visual: Node2D = $Visuals
@onready var trajectory: Node2D = $Trajectory

func _ready() -> void:
	health_changed.emit(current_health, max_health)
	stones_changed.emit(current_stones, max_stones)

func setup(hearts: int, stones: int, assist: bool) -> void:
	max_health = hearts
	current_health = hearts
	max_stones = stones
	current_stones = stones
	aim_assist = assist
	health_changed.emit(current_health, max_health)
	stones_changed.emit(current_stones, max_stones)

func say(text: String, duration: float = 3.0, bg_color: Color = Color(0.18, 0.32, 0.5)) -> void:
	if is_instance_valid(_current_bubble):
		_current_bubble.queue_free()
	var bubble = SPEECH_BUBBLE_SCENE.instantiate()
	get_parent().add_child(bubble)
	bubble.follow(self, -100.0)
	bubble.show_speech(text, duration, bg_color)
	_current_bubble = bubble

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		keyboard_aim = event is InputEventKey

func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if current_health <= 0:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 1100.0)
		move_and_slide()
		_update_visual()
		return

	var on_floor := is_on_floor()
	if on_floor:
		coyote_timer = COYOTE_TIME
		air_dodge_used = false
	else:
		coyote_timer -= delta

	var dir := 0.0
	if controls_enabled and hurt_lock <= 0.0:
		dir = Input.get_axis("move_left", "move_right")

	if controls_enabled and Input.is_action_just_pressed("dodge"):
		_try_dodge(dir, on_floor)

	if is_dodging:
		velocity.x = facing * DODGE_SPEED
		velocity.y = 0.0
	else:
		var g := GRAVITY
		if velocity.y > 0.0:
			g *= FALL_MULT
		elif not Input.is_action_pressed("jump"):
			g *= JUMP_CUT_MULT
		if not on_floor:
			velocity.y = minf(velocity.y + g * delta, 1100.0)

		if controls_enabled and not is_charging_sling and Input.is_action_just_pressed("jump"):
			jump_buffer_timer = JUMP_BUFFER
		jump_buffer_timer -= delta
		if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			AudioManager.play_sound(self, "jump", -8.0)
			FX.dust(get_parent(), global_position, 6, 0.6)

		var target_speed := dir * MOVE_SPEED * (0.5 if is_charging_sling else 1.0)
		var acc := ACCEL if on_floor else AIR_ACCEL
		if dir == 0.0:
			acc = FRICTION if on_floor else AIR_ACCEL * 0.5
		if hurt_lock > 0.0:
			acc = 600.0
		velocity.x = move_toward(velocity.x, target_speed, acc * delta)
		if dir != 0.0 and not is_charging_sling:
			facing = signf(dir)

	_handle_sling(delta)
	_handle_brook(delta)

	var was_air := not on_floor
	var vy_before := velocity.y
	move_and_slide()
	if was_air and is_on_floor() and vy_before > 350.0:
		visual.land_squash()
		FX.dust(get_parent(), global_position, 8, 0.7)

	_update_visual()

func _tick_timers(delta: float) -> void:
	dodge_cooldown_timer = maxf(0.0, dodge_cooldown_timer - delta)
	hurt_lock = maxf(0.0, hurt_lock - delta)
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			is_dodging = false
	if is_invulnerable:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false

func _try_dodge(dir: float, on_floor: bool) -> void:
	if is_dodging or dodge_cooldown_timer > 0.0:
		return
	if not on_floor:
		if air_dodge_used:
			return
		air_dodge_used = true
	if dir != 0.0:
		facing = signf(dir)
	is_dodging = true
	dodge_timer = DODGE_DURATION
	dodge_cooldown_timer = DODGE_COOLDOWN
	_cancel_charge()
	AudioManager.play_sound(self, "dodge", -4.0)
	FX.dust(get_parent(), global_position, 8, 0.8)

func _cancel_charge() -> void:
	is_charging_sling = false
	sling_charge = 0.0
	sling_charge_updated.emit(0.0)
	trajectory.hide_path()

# ------------------------------------------------------------------ Funda
func get_sling_origin() -> Vector2:
	return global_position + Vector2(facing * 7.0, -77.0)

func get_aim_dir() -> Vector2:
	if virtual_aim_dir != Vector2.ZERO:
		return virtual_aim_dir.normalized()
	if keyboard_aim:
		var a := deg_to_rad(kb_aim_deg)
		return Vector2(cos(a) * facing, -sin(a))
	var d := get_global_mouse_position() - get_sling_origin()
	if d.length() < 1.0:
		return Vector2(facing, -0.5).normalized()
	return d.normalized()

func get_launch_speed() -> float:
	return lerpf(MIN_SLING_SPEED, MAX_SLING_SPEED, sling_charge)

func _handle_sling(delta: float) -> void:
	var pressing := controls_enabled and can_fire and Input.is_action_pressed("fire") and not is_dodging and hurt_lock <= 0.0
	if pressing:
		if not is_charging_sling:
			is_charging_sling = true
			sling_charge = 0.0
			_spin_sound_timer = 0.0
		sling_charge = minf(sling_charge + delta * CHARGE_RATE, 1.0)
		if virtual_aim_dir != Vector2.ZERO:
			if absf(virtual_aim_dir.x) > 0.05:
				facing = signf(virtual_aim_dir.x)
		elif keyboard_aim:
			var a := Input.get_axis("aim_down", "aim_up")
			kb_aim_deg = clampf(kb_aim_deg + a * 80.0 * delta, -10.0, 80.0)
			var d := Input.get_axis("move_left", "move_right")
			if d != 0.0:
				facing = signf(d)
		else:
			var md := get_global_mouse_position().x - global_position.x
			if absf(md) > 4.0:
				facing = signf(md)
		_spin_sound_timer -= delta
		if _spin_sound_timer <= 0.0:
			AudioManager.play_sound(self, "sling_spin", -10.0, 0.8 + sling_charge * 0.7)
			_spin_sound_timer = lerpf(0.32, 0.13, sling_charge)
		sling_charge_updated.emit(sling_charge)
		trajectory.show_path(get_sling_origin(), get_aim_dir() * get_launch_speed())
	elif is_charging_sling:
		_fire_stone()
		_cancel_charge()

func _fire_stone() -> void:
	if current_stones <= 0:
		AudioManager.play_sound(self, "empty")
		return
	current_stones -= 1
	stones_changed.emit(current_stones, max_stones)
	GameState.shots += 1
	var stone = STONE_SCENE.instantiate()
	get_parent().add_child(stone)
	stone.launch(get_sling_origin(), get_aim_dir() * get_launch_speed(), aim_assist)
	visual.throw_anim()
	AudioManager.play_sound(self, "stone_launch")
	stone_fired.emit()

# ------------------------------------------------------------------ Pedras
func _handle_brook(delta: float) -> void:
	if not in_brook or current_stones >= max_stones or current_health <= 0:
		return
	_brook_pick_timer -= delta * (3.0 if Input.is_action_pressed("pick") else 1.0)
	if _brook_pick_timer <= 0.0:
		_brook_pick_timer = 0.25
		add_stone(1)
		FX.splash(get_parent(), global_position + Vector2(0, -2), 8)

func add_stone(amount: int = 1) -> bool:
	if current_stones >= max_stones:
		return false
	current_stones = mini(max_stones, current_stones + amount)
	stones_changed.emit(current_stones, max_stones)
	AudioManager.play_sound(self, "refill", -3.0, randf_range(0.95, 1.15))
	return true

func refill_stones() -> void:
	add_stone(max_stones)

func heal(amount: int = 1) -> bool:
	if current_health >= max_health or current_health <= 0:
		return false
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	AudioManager.play_sound(self, "heal")
	FX.hearts(get_parent(), global_position + Vector2(0, -40))
	return true

# ------------------------------------------------------------------ Dano
func take_damage(amount: int, source_x: float = NAN) -> void:
	if is_dodging or is_invulnerable or current_health <= 0:
		return
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	is_invulnerable = true
	invulnerable_timer = 1.3
	hurt_lock = 0.25
	_cancel_charge()
	var away := -facing
	if not is_nan(source_x):
		away = signf(global_position.x - source_x)
		if away == 0.0:
			away = -facing
	velocity = Vector2(away * 380.0, -330.0)
	AudioManager.play_sound(self, "hurt")
	FX.hurt(get_parent(), global_position + Vector2(0, -30))
	hurt.emit()
	if current_health <= 0:
		visual.dead = true
		died.emit()

func is_alive() -> bool:
	return current_health > 0

func _update_visual() -> void:
	visual.scale = Vector2(facing * VISUAL_SCALE, VISUAL_SCALE)
	visual.speed_ratio = clampf(absf(velocity.x) / MOVE_SPEED, 0.0, 1.0) if is_on_floor() else 0.0
	visual.on_floor = is_on_floor()
	visual.vel_y = velocity.y
	visual.charging = is_charging_sling
	visual.charge = sling_charge
	visual.has_stones = current_stones > 0
	var aim := get_aim_dir()
	visual.aim_angle = Vector2(aim.x * facing, aim.y).angle()
	visual.dodging = is_dodging
	visual.dodge_progress = 1.0 - dodge_timer / DODGE_DURATION
	if is_dodging:
		visual.modulate = Color(1, 1, 1, 0.75)
	elif is_invulnerable and current_health > 0:
		var on := fmod(invulnerable_timer, 0.14) > 0.07
		visual.modulate = Color(1.6, 0.7, 0.7, 0.5) if on else Color(1, 1, 1, 1)
	else:
		visual.modulate = Color(1, 1, 1, 1)
