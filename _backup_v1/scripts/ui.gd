extends CanvasLayer

class_name GameUI

@onready var goliath_bar: ProgressBar = $TopBar/GoliathHealthBar
@onready var goliath_label: Label = $TopBar/GoliathLabel
@onready var goliath_state_label: Label = $TopBar/GoliathStateLabel

@onready var david_health_container: HBoxContainer = $BottomBar/HealthContainer
@onready var stones_label: Label = $BottomBar/StonesLabel
@onready var charge_bar: ProgressBar = $ChargeBar

@onready var victory_panel: Panel = $VictoryPanel
@onready var game_over_panel: Panel = $GameOverPanel

func _ready() -> void:
	victory_panel.visible = false
	game_over_panel.visible = false
	charge_bar.visible = false

func update_goliath_health(current: int, max_val: int) -> void:
	goliath_bar.max_value = max_val
	goliath_bar.value = current

func update_goliath_state(state_name: String) -> void:
	if goliath_state_label:
		goliath_state_label.text = state_name

func update_david_health(current: int, max_val: int) -> void:
	# Limpa e reconstrói corações
	for child in david_health_container.get_children():
		child.queue_free()
		
	for i in range(max_val):
		var heart = ColorRect.new()
		heart.custom_minimum_size = Vector2(28, 28)
		heart.color = Color(0.9, 0.2, 0.2, 1) if i < current else Color(0.25, 0.25, 0.25, 0.8)
		david_health_container.add_child(heart)

func update_stones(count: int, max_count: int) -> void:
	stones_label.text = "Pedras no Alforje: %d / %d" % [count, max_count]
	if count == 0:
		stones_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		stones_label.modulate = Color(1.0, 1.0, 1.0)

func update_charge(ratio: float) -> void:
	if ratio > 0.05:
		charge_bar.visible = true
		charge_bar.value = ratio * 100.0
	else:
		charge_bar.visible = false

func show_victory() -> void:
	victory_panel.visible = true

func show_game_over() -> void:
	game_over_panel.visible = true
