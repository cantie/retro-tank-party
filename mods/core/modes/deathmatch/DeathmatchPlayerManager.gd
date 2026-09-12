extends Node

const Tank := preload("res://src/objects/Tank.gd")

@onready var respawn_timer := $RespawnTimer
@onready var weapon_timeout_timer := $WeaponTimeoutTimer
@onready var weapon_warning_timer := $WeaponWarningTimer

var player
var config: Dictionary
var game

var tank

signal weapon_warning ()
signal weapon_timeout ()
signal respawn_player (player_id)

func setup_player_manager(_player, _config: Dictionary, _game) -> void:
	player = _player
	config = _config
	game = _game
	
	if config.get('weapon_timeout', 0) != 0:
		weapon_timeout_timer.wait_ticks = config['weapon_timeout']
		weapon_warning_timer.wait_ticks = config['weapon_timeout'] - 60
	
	game.player_dead.connect(self._on_game_player_dead)

func shutdown_player_manager() -> void:
	weapon_timeout_timer.stop()
	weapon_warning_timer.stop()
	game.player_dead.disconnect(self._on_game_player_dead)
	set_player_tank(null)

func set_player_tank(_tank) -> void:
	if tank != null && is_instance_valid(tank):
		tank.weapon_type_changed.disconnect(self._on_tank_weapon_type_changed)
	
	tank = _tank
	if tank:
		tank.weapon_type_changed.connect(self._on_tank_weapon_type_changed)

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	# We only care about the death of the player we're managing.
	if player_id != player.peer_id:
		return
	
	set_player_tank(null)
	weapon_timeout_timer.stop()
	weapon_warning_timer.stop()

func start_respawn_timer() -> void:
	respawn_timer.start()

func _on_RespawnTimer_timeout() -> void:
	respawn_player.emit(player.peer_id)

func _on_tank_weapon_type_changed(weapon_type: WeaponType, old_weapon_type: WeaponType) -> void:
	if config.get('weapon_timeout', 0) == 0:
		return
	if weapon_type != Tank.BaseWeaponType:
		weapon_warning_timer.start()
		weapon_timeout_timer.start()

func _on_WeaponTimeoutTimer_timeout() -> void:
	if tank:
		tank.set_weapon_type(Tank.BaseWeaponType)
	weapon_timeout.emit()

func _on_WeaponWarningTimer_timeout() -> void:
	weapon_warning.emit()

