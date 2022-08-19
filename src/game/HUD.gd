extends Control

onready var weapon_label = $HBoxContainer/WeaponLabel
onready var ability_label = $HBoxContainer/AbilityLabel
onready var spectator_controls = $SpectatorControls

var _spectator_controls_list := {}

func _ready() -> void:
	ability_label.set_message_translation(false)

func set_weapon_label(text: String) -> void:
	weapon_label.visible = true
	weapon_label.blinking = false
	weapon_label.text = text

func clear_weapon_label() -> void:
	weapon_label.visible = false
	weapon_label.blinking = false

func set_ability_label(text: String, charges: int = 1) -> void:
	ability_label.visible = true
	ability_label.blinking = false
	ability_label.text = tr(text)
	if charges > 1:
		ability_label.text += ' (' + str(charges) + ')'

func clear_ability_label() -> void:
	ability_label.visible = false
	ability_label.blinking = false

func clear_all_labels() -> void:
	clear_weapon_label()
	clear_ability_label()

func add_spectator_control(name: String, control: Control) -> void:
	if not _spectator_controls_list.has(name):
		_spectator_controls_list[name] = control
		spectator_controls.add_child(control)

func remove_spectator_control(name: String) -> void:
	if _spectator_controls_list.has(name):
		var control = _spectator_controls_list[name]
		_spectator_controls_list.erase(name)

		spectator_controls.remove_child(control)
		control.queue_free()

func clear_spectator_controls() -> void:
	for child in _spectator_controls_list.values():
		spectator_controls.remove_child(child)
		child.queue_free()
	_spectator_controls_list.clear()
