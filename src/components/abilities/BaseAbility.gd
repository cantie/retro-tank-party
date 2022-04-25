extends Node2D

signal despawned

var tank
var ability_type

signal finished ()

func _ready() -> void:
	connect("despawned", self, "_on_despawned")

func setup_ability(_tank, _ability_type) -> void:
	tank = _tank
	ability_type = _ability_type

func attach_ability() -> void:
	pass

func detach_ability() -> void:
	pass

func mark_finished() -> void:
	emit_signal("finished")

func _on_despawned() -> void:
	mark_finished()

func use_ability() -> void:
	pass
