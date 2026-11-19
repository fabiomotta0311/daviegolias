extends Node

# Estado global do jogo (autoload "GameState"):
# dificuldade escolhida, recordes salvos, estatísticas da partida e mapa de controles.

enum Difficulty { EASY, NORMAL, HARD }

const SAVE_PATH := "user://davi_golias.cfg"

var difficulty: int = Difficulty.NORMAL
var skip_title: bool = false
var no_save: bool = false # usado pelo robô de testes
var best_times: Dictionary = {0: 0.0, 1: 0.0, 2: 0.0}

# Estatísticas da partida atual
var shots: int = 0
var hits: int = 0
var crits: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	_load()

func get_settings() -> Dictionary:
	match difficulty:
		Difficulty.EASY:
			return {
				"name": "Fácil", "david_hearts": 5, "stones": 7, "boss_hp": 90,
				"telegraph_mult": 1.45, "boss_speed_mult": 0.8, "head_radius": 34.0,
				"aim_assist": true, "heal_interval": 14.0,
			}
		Difficulty.HARD:
			return {
				"name": "Difícil", "david_hearts": 3, "stones": 5, "boss_hp": 140,
				"telegraph_mult": 0.8, "boss_speed_mult": 1.25, "head_radius": 22.0,
				"aim_assist": false, "heal_interval": 30.0,
			}
		_:
			return {
				"name": "Normal", "david_hearts": 4, "stones": 5, "boss_hp": 110,
				"telegraph_mult": 1.0, "boss_speed_mult": 1.0, "head_radius": 27.0,
				"aim_assist": false, "heal_interval": 20.0,
			}

func reset_stats() -> void:
	shots = 0
	hits = 0
	crits = 0

func register_time(t: float) -> bool:
	var prev: float = best_times.get(difficulty, 0.0)
	if prev <= 0.0 or t < prev:
		best_times[difficulty] = t
		_save()
		return true
	return false

func _save() -> void:
	if no_save:
		return
	var cfg := ConfigFile.new()
	for k in best_times.keys():
		cfg.set_value("best_times", str(k), best_times[k])
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.save(SAVE_PATH)

func save_settings() -> void:
	_save()

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for k in [0, 1, 2]:
		best_times[k] = float(cfg.get_value("best_times", str(k), 0.0))
	difficulty = int(cfg.get_value("settings", "difficulty", Difficulty.NORMAL))

static func format_time(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	var cs := int((t - floor(t)) * 10.0)
	return "%d:%02d.%d" % [m, s, cs]

# ------------------------------------------------------------------ Controles
func _register_inputs() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_W, KEY_UP, KEY_SPACE])
	_add_keys("aim_up", [KEY_W, KEY_UP])
	_add_keys("aim_down", [KEY_S, KEY_DOWN])
	_add_keys("dodge", [KEY_SHIFT, KEY_C, KEY_L])
	_add_mouse("dodge", MOUSE_BUTTON_RIGHT)
	_add_keys("fire", [KEY_F, KEY_J, KEY_K])
	_add_mouse("fire", MOUSE_BUTTON_LEFT)
	_add_keys("pick", [KEY_E])
	_add_keys("pause", [KEY_P, KEY_ESCAPE])
	_add_keys("restart", [KEY_R])
	_add_keys("mute", [KEY_M])

func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _add_mouse(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
