extends CanvasLayer

class_name GameUI

# HUD e telas (título, pausa, vitória e derrota), montados em código.

const HUD_WIDGETS = preload("res://scripts/hud_widgets.gd")
const TOUCH_CONTROLS_SCENE = preload("res://scripts/touch_controls.gd")

const INK := Color(0.22, 0.13, 0.06)
const PARCHMENT := Color(0.97, 0.91, 0.76)
const GOLD := Color(1.0, 0.82, 0.3)

const HINTS := {
	"TELEGRAPH_PUNCH": "Golias vai socar o chão! Afaste-se!",
	"ATTACK_PUNCH": "Golias vai socar o chão! Afaste-se!",
	"PUNCH_RECOVERY": "Ele está curvado! Mire na TESTA!",
	"TELEGRAPH_STOMP": "Pisão! PULE a onda de pedras!",
	"ATTACK_STOMP": "Pisão! PULE a onda de pedras!",
	"TELEGRAPH_THROW": "Lança! Esquive com SHIFT ou pule!",
	"ATTACK_THROW": "Lança! Esquive com SHIFT ou pule!",
	"STUNNED": "Golias está tonto! Acerte a testa de novo!",
	"ROAR": "Golias está FURIOSO! Cuidado!",
}

var arena: Node = null

var boss_bar: Control
var boss_name: Label
var hint_label: Label
var status: Control
var timer_label: Label
var mute_label: Label
var banner: Label

var title_panel: Control
var pause_panel: Control
var end_panel: Control
var end_title: Label
var end_desc: Label
var end_stats: Label
var diff_buttons: Array = []
var best_label: Label

var touch_controls: Control = null
var touch_toggle_btn: Button = null
var rotate_overlay: Control = null

var _hint_key: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_controls = TOUCH_CONTROLS_SCENE.new()
	add_child(touch_controls)
	_build_hud()
	_build_title()
	_build_pause()
	_build_end()
	_build_rotate_overlay()

func _process(_delta: float) -> void:
	if touch_controls:
		var in_menu := title_panel.visible or pause_panel.visible or end_panel.visible
		touch_controls.visible = touch_controls.is_active and not in_menu
		if arena != null and touch_controls.david_ref == null:
			touch_controls.david_ref = arena.david

	# Detecta se o celular está em pé (modo retrato) e orienta a virar de lado
	if rotate_overlay:
		var vp := get_viewport().get_visible_rect().size
		rotate_overlay.visible = (vp.y > vp.x)

# ------------------------------------------------------------------ Estilos
func _panel_style(bg: Color = PARCHMENT, border: Color = Color(0.5, 0.32, 0.14)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(22)
	return sb

func _label(text: String, size: int, color: Color = INK, outline: int = 0, outline_col: Color = Color.BLACK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", outline_col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 44)
	b.add_theme_font_size_override("font_size", 18)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.55, 0.35, 0.16)
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(3)
	normal.border_color = Color(0.32, 0.19, 0.08)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.7, 0.47, 0.22)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.85, 0.62, 0.25)
	pressed.border_color = GOLD
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_color_override("font_color", Color(1, 0.96, 0.85))
	b.add_theme_color_override("font_pressed_color", Color(0.2, 0.1, 0.0))
	b.add_theme_color_override("font_hover_pressed_color", Color(0.2, 0.1, 0.0))
	b.pressed.connect(cb)
	return b

func _overlay() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	root.visible = false
	add_child(root)
	return root

func _panel_of(o: Control) -> PanelContainer:
	return o.get_child(1).get_child(0)

# ------------------------------------------------------------------ HUD
func _build_hud() -> void:
	var top := VBoxContainer.new()
	top.position = Vector2(640 - 310, 14)
	top.size = Vector2(620, 80)
	top.add_theme_constant_override("separation", 4)
	add_child(top)
	boss_name = _label("GOLIAS DE GATE — O CAMPEÃO DOS FILISTEUS", 18, Color(1, 0.93, 0.8), 6, Color(0.2, 0.08, 0.04))
	top.add_child(boss_name)
	boss_bar = HUD_WIDGETS.new()
	boss_bar.kind = 0
	boss_bar.custom_minimum_size = Vector2(620, 26)
	top.add_child(boss_bar)
	hint_label = _label("", 18, Color(1, 0.95, 0.6), 6, Color(0.25, 0.05, 0.02))
	top.add_child(hint_label)

	status = HUD_WIDGETS.new()
	status.kind = 1
	status.position = Vector2(20, 16)
	status.size = Vector2(400, 110)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)

	timer_label = _label("0:00.0", 22, Color(1, 0.97, 0.88), 6, Color(0.2, 0.1, 0.05))
	timer_label.position = Vector2(1135, 16)
	timer_label.size = Vector2(130, 30)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(timer_label)

	# Botões táteis no topo (Pausa, Alternador de Controles Touch e Tela Cheia)
	var pause_btn := _button("⏸", toggle_pause)
	pause_btn.position = Vector2(1085, 14)
	pause_btn.custom_minimum_size = Vector2(42, 34)
	pause_btn.add_theme_font_size_override("font_size", 16)
	add_child(pause_btn)

	var fs_btn := _button("⛶", toggle_fullscreen)
	fs_btn.position = Vector2(1036, 14)
	fs_btn.custom_minimum_size = Vector2(42, 34)
	fs_btn.add_theme_font_size_override("font_size", 16)
	add_child(fs_btn)

	touch_toggle_btn = _button("📱 TOUCH: OFF", _on_toggle_touch)
	touch_toggle_btn.position = Vector2(880, 14)
	touch_toggle_btn.custom_minimum_size = Vector2(148, 34)
	touch_toggle_btn.add_theme_font_size_override("font_size", 13)
	add_child(touch_toggle_btn)
	_update_touch_btn_visual()

	mute_label = _label("SOM DESLIGADO (M)", 14, Color(1, 0.8, 0.7), 4, Color.BLACK)
	mute_label.position = Vector2(1080, 52)
	mute_label.size = Vector2(180, 20)
	mute_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mute_label.visible = false
	add_child(mute_label)

	var help := _label("PC: Teclado e Mouse (A/D/Espaço)  •  Shift: Esquivar  •  P: Pausa  •  T: Controles Touch (ON/OFF)", 12, Color(1, 1, 1, 0.75), 4, Color(0, 0, 0, 0.7))
	help.position = Vector2(0, 695)
	help.size = Vector2(1280, 20)
	add_child(help)

	banner = _label("", 72, GOLD, 14, Color(0.3, 0.1, 0.02))
	banner.position = Vector2(0, 250)
	banner.size = Vector2(1280, 120)
	banner.pivot_offset = Vector2(640, 60)
	banner.visible = false
	add_child(banner)

func update_goliath_health(current: int, max_val: int) -> void:
	boss_bar.set_hp(current, max_val)

func update_goliath_state(state_name: String) -> void:
	_hint_key = state_name
	hint_label.text = HINTS.get(state_name, "")
	boss_bar.enraged = arena != null and arena.goliath.is_enraged

func update_david_health(current: int, max_val: int) -> void:
	status.set_hearts(current, max_val)

func update_stones(count: int, max_count: int) -> void:
	status.set_stones(count, max_count)

func update_charge(_ratio: float) -> void:
	pass

func set_time(t: float) -> void:
	timer_label.text = GameState.format_time(t)

func set_muted(m: bool) -> void:
	mute_label.visible = m

func _on_toggle_touch() -> void:
	if touch_controls:
		touch_controls.toggle_touch()
		_update_touch_btn_visual()

func _update_touch_btn_visual() -> void:
	if touch_toggle_btn and touch_controls:
		if touch_controls.is_active:
			touch_toggle_btn.text = "📱 TOUCH: ON"
			touch_toggle_btn.modulate = Color(1.3, 1.2, 0.4)
		else:
			touch_toggle_btn.text = "📱 TOUCH: OFF"
			touch_toggle_btn.modulate = Color(0.82, 0.82, 0.82, 0.7)

func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func show_banner(text: String, color: Color = GOLD, hold: float = 0.8) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	banner.scale = Vector2(2.2, 2.2)
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.set_parallel(false)
	tw.tween_interval(hold)
	tw.tween_property(banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): banner.visible = false)

# ------------------------------------------------------------------ Título
func _build_title() -> void:
	title_panel = _overlay()
	var panel := _panel_of(title_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(640, 0)
	panel.add_child(v)
	v.add_child(_label("DAVI & GOLIAS", 54, Color(0.75, 0.45, 0.1), 10, Color(0.25, 0.12, 0.03)))
	v.add_child(_label("O Duelo no Vale de Elá", 22, INK))
	var verse := _label("\"Tu vens a mim com espada e lança... eu, porém, vou a ti em nome do Senhor.\" — 1 Samuel 17:45", 14, Color(0.4, 0.28, 0.15))
	verse.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(verse)
	v.add_child(HSeparator.new())
	v.add_child(_label("Escolha a dificuldade (teclas 1, 2, 3):", 16, INK))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 14)
	v.add_child(hb)
	var names := ["1  Fácil", "2  Normal", "3  Difícil"]
	for i in 3:
		var b := _button(names[i], _select_difficulty.bind(i))
		b.toggle_mode = true
		hb.add_child(b)
		diff_buttons.append(b)
	var diff_desc := _label("", 14, Color(0.35, 0.22, 0.1))
	diff_desc.name = "DiffDesc"
	v.add_child(diff_desc)
	best_label = _label("", 14, Color(0.45, 0.3, 0.1))
	v.add_child(best_label)
	v.add_child(HSeparator.new())
	var controls := _label(
		"COMO JOGAR\n" +
		"A / D ou ← →: andar     W / Espaço: pular\n" +
		"Segure o CLIQUE ESQUERDO para girar a funda, solte para atirar\n" +
		"(ou segure F e ajuste a mira com W / S)\n" +
		"SHIFT ou clique direito: esquivar (rolamento invencível)\n" +
		"Pegue pedras no RIBEIRO (à esquerda) ou as que caíram no chão\n" +
		"Acerte a TESTA de Golias para causar dano crítico e deixá-lo tonto!",
		15, INK)
	v.add_child(controls)
	var start := _button("COMEÇAR  (Enter)", _start_game)
	start.custom_minimum_size = Vector2(260, 54)
	start.add_theme_font_size_override("font_size", 22)
	var c := CenterContainer.new()
	c.add_child(start)
	v.add_child(c)
	_refresh_difficulty()

func _select_difficulty(i: int) -> void:
	GameState.difficulty = i
	GameState.save_settings()
	_refresh_difficulty()

func _refresh_difficulty() -> void:
	for i in diff_buttons.size():
		diff_buttons[i].set_pressed_no_signal(i == GameState.difficulty)
	var s := GameState.get_settings()
	var desc: Label = title_panel.find_child("DiffDesc", true, false)
	if desc:
		desc.text = "%s: %d corações, %d pedras%s" % [s.name, s.david_hearts, s.stones,
			", mira assistida e testa brilhando" if s.aim_assist else ""]
	var best: float = GameState.best_times.get(GameState.difficulty, 0.0)
	best_label.text = "Recorde: %s" % (GameState.format_time(best) if best > 0.0 else "—")

func show_title() -> void:
	_refresh_difficulty()
	title_panel.visible = true

func _start_game() -> void:
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	GameState.skip_title = true
	_reload()

# ------------------------------------------------------------------ Pausa
func _build_pause() -> void:
	pause_panel = _overlay()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_panel_of(pause_panel).add_child(v)
	v.add_child(_label("PAUSA", 40, Color(0.6, 0.35, 0.1), 8, Color(0.2, 0.1, 0.03)))
	v.add_child(_label("Dica: quando Golias soca o chão, ele fica curvado.\nÉ a melhor hora para acertar a testa!", 15, INK))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	hb.add_child(_button("Continuar (P)", toggle_pause))
	hb.add_child(_button("Reiniciar (R)", restart))
	hb.add_child(_button("Menu (Esc)", go_to_menu))

func toggle_pause() -> void:
	if title_panel.visible or end_panel.visible:
		return
	var p := not get_tree().paused
	get_tree().paused = p
	pause_panel.visible = p

# ------------------------------------------------------------------ Fim
func _build_end() -> void:
	end_panel = _overlay()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(560, 0)
	_panel_of(end_panel).add_child(v)
	end_title = _label("", 48, Color(0.75, 0.45, 0.1), 10, Color(0.25, 0.12, 0.03))
	v.add_child(end_title)
	end_desc = _label("", 17, INK)
	end_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(end_desc)
	end_stats = _label("", 16, Color(0.35, 0.22, 0.1))
	v.add_child(end_stats)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 14)
	v.add_child(hb)
	hb.add_child(_button("Jogar de novo (R)", restart))
	hb.add_child(_button("Menu (Esc)", go_to_menu))

func _build_rotate_overlay() -> void:
	rotate_overlay = Control.new()
	rotate_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotate_overlay.visible = false
	add_child(rotate_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_overlay.add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)

	var icon := _label("📱 ⟳", 58, GOLD)
	v.add_child(icon)

	var msg := _label("GIRE O CELULAR DE LADO", 24, Color(1, 0.95, 0.8), 8, Color(0.2, 0.1, 0.04))
	v.add_child(msg)

	var sub := _label("O duelo foi projetado para a tela na horizontal!", 16, Color(0.9, 0.82, 0.65))
	v.add_child(sub)

func show_victory(time: float, record: bool) -> void:
	end_title.text = "VITÓRIA!"
	end_title.add_theme_color_override("font_color", Color(0.85, 0.6, 0.1))
	end_desc.text = "\"Assim Davi prevaleceu contra o filisteu com uma funda e uma pedra.\"\n— 1 Samuel 17:50\n\nO gigante caiu! O Deus de Israel deu a vitória a Davi."
	var acc := 0
	if GameState.shots > 0:
		acc = int(round(100.0 * GameState.hits / GameState.shots))
	end_stats.text = "Tempo: %s%s\nPedras lançadas: %d   •   Acertos: %d (%d%%)   •   Na testa: %d" % [
		GameState.format_time(time), "   ★ NOVO RECORDE! ★" if record else "",
		GameState.shots, GameState.hits, acc, GameState.crits]
	_show_end()

func show_game_over() -> void:
	end_title.text = "DAVI CAIU..."
	end_title.add_theme_color_override("font_color", Color(0.7, 0.2, 0.12))
	var tips := [
		"Dica: pule a onda de pedras quando Golias levantar o pé!",
		"Dica: a esquiva (Shift) deixa Davi invencível por um instante.",
		"Dica: quando Golias soca o chão, a testa dele fica baixinha. Mire nela!",
		"Dica: pegue o queijo que cai do céu para recuperar vida.",
		"Dica: pedras que erram ficam no chão — passe por cima para pegar.",
	]
	end_desc.text = "A força do gigante prevaleceu desta vez. Não desanime, tente de novo!\n\n" + tips[randi() % tips.size()]
	end_stats.text = "Vida de Golias restante: %d%%" % int(round(100.0 * boss_bar.hp / maxf(1.0, boss_bar.hp_max)))
	_show_end()

func _show_end() -> void:
	end_panel.visible = true
	var p := _panel_of(end_panel)
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.tween_property(p, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ------------------------------------------------------------------ Entrada
func restart() -> void:
	GameState.skip_title = true
	_reload()

func go_to_menu() -> void:
	GameState.skip_title = false
	_reload()

func _reload() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			_on_toggle_touch()
			return
		elif event.physical_keycode == KEY_F11:
			toggle_fullscreen()
			return

	if event.is_action_pressed("mute"):
		var bus := AudioServer.get_bus_index("Master")
		var m := not AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_mute(bus, m)
		set_muted(m)
		return
	if title_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.physical_keycode:
				KEY_1: _select_difficulty(0)
				KEY_2: _select_difficulty(1)
				KEY_3: _select_difficulty(2)
				KEY_ENTER, KEY_KP_ENTER: _start_game()
		return
	if event.is_action_pressed("restart"):
		restart()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE and (pause_panel.visible or end_panel.visible):
		go_to_menu()
	elif event.is_action_pressed("pause"):
		toggle_pause()
	elif end_panel.visible and event is InputEventKey and event.pressed and event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
		restart()
