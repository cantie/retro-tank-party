tool
extends Node

const GAME_ARGUMENTS_SETTING = 'network/rollback/log_inspector/replay_arguments'
const GAME_PORT_SETTING = 'network/rollback/log_inspector/replay_port'
const GAME_LAUNCH_WAIT_TIME_SETTING = 'network/rollback/log_inspector/replay_launch_wait_time'

var connection: StreamPeerTCP
var game_pid: int

func _launch_game() -> void:
	var args := []

	var args_string = "replay"
	if ProjectSettings.has_setting(GAME_ARGUMENTS_SETTING):
		args_string = ProjectSettings.get_setting(GAME_ARGUMENTS_SETTING)
	for arg in args_string.split(" "):
		args.push_front(arg)
	
	game_pid = OS.execute(OS.get_executable_path(), args, false)
	
	var wait_time := 0
	if ProjectSettings.has_setting(GAME_LAUNCH_WAIT_TIME_SETTING):
		wait_time = ProjectSettings.get_setting(GAME_LAUNCH_WAIT_TIME_SETTING)
	if wait_time > 0:
		OS.delay_msec(wait_time)

func connect_to_game() -> bool:
	if is_connected_to_game():
		return true
	var launched := false
	if not game_pid:
		_launch_game()
		launched = true
	if not _do_connect_to_game():
		if not launched:
			_launch_game()
			if _do_connect_to_game():
				return true
		OS.alert("Unable to connect to game")
		return false
	return true

func _do_connect_to_game() -> bool:
	if is_connected_to_game():
		return true
	
	if connection:
		connection.disconnect_from_host()
		connection = null
	
	var port = 49111
	if ProjectSettings.has_setting(GAME_PORT_SETTING):
		port = ProjectSettings.get_setting(GAME_PORT_SETTING)
	
	connection = StreamPeerTCP.new()
	return connection.connect_to_host('127.0.0.1', port) == OK

func is_connected_to_game() -> bool:
	return connection and connection.is_connected_to_host()

func send_message(msg: Dictionary) -> void:
	if not is_connected_to_game():
		push_error("ReplayClient: attempting to send message when not connected to game")
		return
	
	var data := JSON.print(msg)
	connection.put_u32(data.length())
	connection.put_data(data.to_utf8())
