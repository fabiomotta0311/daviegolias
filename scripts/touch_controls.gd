extends Control

class_name TouchControls

# Controles virtuais na tela: Dois direcionais analógicos (Twin-Stick).
# Esquerda: Frente/Trás e Pulo (cima).
# Direita: Puxar mira a funda; ao soltar, dispara a pedra!

const BG_COLOR := Color(0.12, 0.08, 0.05, 0.5)
const BORDER_COLOR := Color(0.85, 0.7, 0.35, 0.75)
const STICK_COLOR := Color(0.28, 0.18, 0.1, 0.85)
const STICK_PRESSED_COLOR := Color(0.9, 0.7, 0.22, 0.9)
const ARROW_COLOR := Color(1.0, 0.95, 0.8, 0.85)
const TEXT_COLOR := Color(1.0, 0.95, 0.8, 0.9)

# Analógico Esquerdo (Movimento + Pulo)
var left_base_pos := Vector2(170, 560)
var left_radius := 75.0
var left_knob_pos := Vector2(170, 560)
var left_knob_radius := 36.0
var left_touch_id := -1
var left_stick_vec := Vector2.ZERO
var _left_is_jumping := false

# Analógico Direito (Mira + Disparo)
var right_base_pos := Vector2(1110, 560)
var right_radius := 85.0
var right_knob_pos := Vector2(1110, 560)
var right_knob_radius := 40.0
var right_touch_id := -1
var right_stick_vec := Vector2.ZERO
var is_aiming := false

# Botão Rolar / Esquiva
var dodge_btn_pos := Vector2(170, 420)
var dodge_btn_radius := 38.0
var dodge_touch_id := -1
var dodge_pressed := false

# Botão Pegar / Interagir
var pick_btn_pos := Vector2(1110, 420)
var pick_btn_radius := 34.0
var pick_touch_id := -1
var pick_pressed := false

var is_active: bool = false
var david_ref: Node = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

	_detect_touchscreen()

func _detect_touchscreen() -> void:
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	var is_web_mobile := OS.has_feature("web_android") or OS.has_feature("web_ios")
	var touch_available := DisplayServer.is_touchscreen_available()

	if is_mobile or is_web_mobile or touch_available:
		set_touch_enabled(true)
	else:
		set_touch_enabled(false)

func set_touch_enabled(enabled: bool) -> void:
	is_active = enabled
	visible = is_active
	if not is_active:
		_release_all()
	queue_redraw()

func toggle_touch() -> bool:
	set_touch_enabled(not is_active)
	return is_active

func _input(event: InputEvent) -> void:
	if not is_active or not visible:
		# Ativa se detectar toque na tela
		if event is InputEventScreenTouch and event.pressed:
			set_touch_enabled(true)
		else:
			return

	if event is InputEventScreenTouch:
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)

func _on_screen_touch(event: InputEventScreenTouch) -> void:
	var tid := event.index
	var pos := event.position

	if event.pressed:
		# 1. Analógico Esquerdo (Movimento + Pulo)
		if left_touch_id == -1 and pos.distance_to(left_base_pos) <= left_radius * 1.5:
			left_touch_id = tid
			_update_left_stick(pos)
			get_viewport().set_input_as_handled()
			return

		# 2. Analógico Direito (Mira + Disparo)
		if right_touch_id == -1 and pos.distance_to(right_base_pos) <= right_radius * 1.5:
			right_touch_id = tid
			is_aiming = true
			_update_right_stick(pos)
			Input.action_press("fire")
			get_viewport().set_input_as_handled()
			return

		# 3. Botão Esquiva
		if dodge_touch_id == -1 and pos.distance_to(dodge_btn_pos) <= dodge_btn_radius * 1.3:
			dodge_touch_id = tid
			dodge_pressed = true
			Input.action_press("dodge")
			queue_redraw()
			get_viewport().set_input_as_handled()
			return

		# 4. Botão Pegar
		if pick_touch_id == -1 and pos.distance_to(pick_btn_pos) <= pick_btn_radius * 1.3:
			pick_touch_id = tid
			pick_pressed = true
			Input.action_press("pick")
			queue_redraw()
			get_viewport().set_input_as_handled()
			return

	else:
		# Soltou toque
		if tid == left_touch_id:
			left_touch_id = -1
			left_stick_vec = Vector2.ZERO
			left_knob_pos = left_base_pos
			Input.action_release("move_left")
			Input.action_release("move_right")
			if _left_is_jumping:
				_left_is_jumping = false
				Input.action_release("jump")
			queue_redraw()
			get_viewport().set_input_as_handled()

		elif tid == right_touch_id:
			right_touch_id = -1
			is_aiming = false
			# Soltou o analógico da direita: dispara o tiro!
			Input.action_release("fire")
			right_stick_vec = Vector2.ZERO
			right_knob_pos = right_base_pos
			# Pequeno timer para limpar o aim_dir após o tiro ser emitido
			get_tree().create_timer(0.08, false).timeout.connect(func():
				if is_instance_valid(david_ref) and "virtual_aim_dir" in david_ref:
					david_ref.virtual_aim_dir = Vector2.ZERO
			)
			queue_redraw()
			get_viewport().set_input_as_handled()

		elif tid == dodge_touch_id:
			dodge_touch_id = -1
			dodge_pressed = false
			Input.action_release("dodge")
			queue_redraw()
			get_viewport().set_input_as_handled()

		elif tid == pick_touch_id:
			pick_touch_id = -1
			pick_pressed = false
			Input.action_release("pick")
			queue_redraw()
			get_viewport().set_input_as_handled()

func _on_screen_drag(event: InputEventScreenDrag) -> void:
	var tid := event.index
	var pos := event.position

	if tid == left_touch_id:
		_update_left_stick(pos)
		get_viewport().set_input_as_handled()
	elif tid == right_touch_id:
		_update_right_stick(pos)
		get_viewport().set_input_as_handled()

func _update_left_stick(pos: Vector2) -> void:
	var offset := pos - left_base_pos
	if offset.length() > left_radius:
		offset = offset.normalized() * left_radius
	left_knob_pos = left_base_pos + offset
	left_stick_vec = offset / left_radius

	# Movimento horizontal
	if left_stick_vec.x < -0.22:
		Input.action_press("move_left")
		Input.action_release("move_right")
	elif left_stick_vec.x > 0.22:
		Input.action_press("move_right")
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

	# Pulo (cima)
	if left_stick_vec.y < -0.42:
		if not _left_is_jumping:
			_left_is_jumping = true
			Input.action_press("jump")
	elif left_stick_vec.y >= -0.25:
		if _left_is_jumping:
			_left_is_jumping = false
			Input.action_release("jump")

	queue_redraw()

func _update_right_stick(pos: Vector2) -> void:
	var offset := pos - right_base_pos
	if offset.length() > right_radius:
		offset = offset.normalized() * right_radius
	right_knob_pos = right_base_pos + offset
	right_stick_vec = offset / right_radius

	if offset.length() > 8.0:
		var aim := offset.normalized()
		if is_instance_valid(david_ref) and "virtual_aim_dir" in david_ref:
			david_ref.virtual_aim_dir = aim

	queue_redraw()

func _release_all() -> void:
	left_touch_id = -1
	right_touch_id = -1
	dodge_touch_id = -1
	pick_touch_id = -1
	left_knob_pos = left_base_pos
	right_knob_pos = right_base_pos
	left_stick_vec = Vector2.ZERO
	right_stick_vec = Vector2.ZERO
	is_aiming = false
	dodge_pressed = false
	pick_pressed = false
	_left_is_jumping = false

	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("fire")
	Input.action_release("dodge")
	Input.action_release("pick")

	if is_instance_valid(david_ref) and "virtual_aim_dir" in david_ref:
		david_ref.virtual_aim_dir = Vector2.ZERO

	queue_redraw()

func _draw() -> void:
	if not is_active or not visible:
		return

	# ===================== ANALÓGICO ESQUERDO (Movimento + Pulo) =====================
	# Base
	draw_circle(left_base_pos + Vector2(2, 4), left_radius, Color(0, 0, 0, 0.4))
	draw_circle(left_base_pos, left_radius, BG_COLOR)
	draw_arc(left_base_pos, left_radius, 0.0, TAU, 36, BORDER_COLOR, 3.0, true)

	# Marcações direcionais de seta
	draw_string(ThemeDB.fallback_font, left_base_pos + Vector2(-60, 6), "◀", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, ARROW_COLOR)
	draw_string(ThemeDB.fallback_font, left_base_pos + Vector2(44, 6), "▶", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, ARROW_COLOR)
	draw_string(ThemeDB.fallback_font, left_base_pos + Vector2(-8, -46), "▲", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, ARROW_COLOR)
	draw_string(ThemeDB.fallback_font, left_base_pos + Vector2(-16, -60), "PULO", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1, 0.9, 0.5, 0.9))

	# Manípulo
	var left_knob_col := STICK_PRESSED_COLOR if left_touch_id != -1 else STICK_COLOR
	draw_circle(left_knob_pos + Vector2(1, 2), left_knob_radius, Color(0, 0, 0, 0.5))
	draw_circle(left_knob_pos, left_knob_radius, left_knob_col)
	draw_arc(left_knob_pos, left_knob_radius, 0.0, TAU, 28, Color.WHITE if left_touch_id != -1 else BORDER_COLOR, 2.5, true)
	draw_circle(left_knob_pos, 8.0, Color(1, 1, 1, 0.8) if left_touch_id != -1 else Color(0.8, 0.6, 0.2, 0.8))

	# ===================== ANALÓGICO DIREITO (Mira + Atirar) =====================
	# Base
	draw_circle(right_base_pos + Vector2(2, 4), right_radius, Color(0, 0, 0, 0.4))
	draw_circle(right_base_pos, right_radius, BG_COLOR)
	var right_border := Color(1.0, 0.85, 0.3) if is_aiming else BORDER_COLOR
	draw_arc(right_base_pos, right_radius, 0.0, TAU, 40, right_border, 3.5 if is_aiming else 3.0, true)

	# Linha / Seta de mira saindo do analógico quando puxado
	if is_aiming and right_stick_vec.length() > 0.15:
		var aim_target := right_base_pos + right_stick_vec.normalized() * (right_radius + 28.0)
		draw_line(right_knob_pos, aim_target, Color(1.0, 0.9, 0.3, 0.95), 4.0, true)
		draw_circle(aim_target, 6.0, Color(1.0, 0.95, 0.5))

	# Manípulo
	var right_knob_col := Color(0.95, 0.75, 0.25, 0.95) if is_aiming else STICK_COLOR
	draw_circle(right_knob_pos + Vector2(1, 2), right_knob_radius, Color(0, 0, 0, 0.5))
	draw_circle(right_knob_pos, right_knob_radius, right_knob_col)
	draw_arc(right_knob_pos, right_knob_radius, 0.0, TAU, 32, Color.WHITE if is_aiming else BORDER_COLOR, 3.0 if is_aiming else 2.5, true)

	# Ícone central
	var aim_icon := "🎯"
	var font := ThemeDB.fallback_font
	var isz := font.get_string_size(aim_icon, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	draw_string(font, right_knob_pos + Vector2(-isz.x * 0.5, isz.y * 0.35), aim_icon, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)

	# Legenda orientadora
	var hint := "Puxe para Mirar  •  Solte para Atirar" if is_aiming else "🎯 MIRA / ATIRAR"
	var hsz := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	draw_string(font, right_base_pos + Vector2(-hsz.x * 0.5, right_radius + 22), hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 0.92, 0.65, 0.9))

	# ===================== BOTÃO ESQUIVA (Acima da Esquerda) =====================
	_draw_action_button(dodge_btn_pos, dodge_btn_radius, dodge_pressed, "💨", "ROLAR")

	# ===================== BOTÃO PEGAR (Acima da Direita) =====================
	_draw_action_button(pick_btn_pos, pick_btn_radius, pick_pressed, "✋", "PEGAR")

func _draw_action_button(pos: Vector2, radius: float, pressed: bool, icon: String, label: String) -> void:
	var col := STICK_PRESSED_COLOR if pressed else BG_COLOR
	var border := Color.WHITE if pressed else BORDER_COLOR
	draw_circle(pos + Vector2(1, 2), radius, Color(0, 0, 0, 0.35))
	draw_circle(pos, radius, col)
	draw_arc(pos, radius, 0.0, TAU, 28, border, 2.8, true)

	var font := ThemeDB.fallback_font
	var isz := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_CENTER, -1, int(radius * 0.65))
	draw_string(font, pos + Vector2(-isz.x * 0.5, -2), icon, HORIZONTAL_ALIGNMENT_CENTER, -1, int(radius * 0.65), Color.WHITE)
	var lsz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
	draw_string(font, pos + Vector2(-lsz.x * 0.5, radius * 0.65), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, TEXT_COLOR)
