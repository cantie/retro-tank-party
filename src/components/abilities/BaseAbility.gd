extends Node2D

var tank
var ability_type
var charges := 1
var marked_as_finished := false

signal finished ()

func _ready() -> void:
	add_to_group('network_sync')

func setup_ability(_tank, _ability_type) -> void:
	tank = _tank
	ability_type = _ability_type
	charges = ability_type.charges

func _save_state() -> Dictionary:
	return {
		charges = charges,
	}

func _load_state(state: Dictionary) -> void:
	charges = state['charges']

func recharge_ability() -> void:
	charges = ability_type.charges

func attach_ability() -> void:
	pass

func detach_ability() -> void:
	pass

func mark_finished() -> void:
	if not marked_as_finished:
		marked_as_finished = true
		emit_signal("finished")

func get_ability_charges() -> int:
	return charges

func use_ability() -> void:
	pass
