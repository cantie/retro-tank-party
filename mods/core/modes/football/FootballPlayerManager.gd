extends Node

const Tank := preload("res://src/objects/Tank.gd")

onready var respawn_timer := $RespawnTimer

var player
var config: Dictionary
var game

signal respawn_player (player_id)

func setup_player_manager(_player, _config: Dictionary, _game) -> void:
	player = _player
	config = _config
	game = _game

func shutdown_player_manager() -> void:
	pass

func start_respawn_timer() -> void:
	respawn_timer.start()

func _on_RespawnTimer_timeout() -> void:
	emit_signal("respawn_player", player.peer_id)


