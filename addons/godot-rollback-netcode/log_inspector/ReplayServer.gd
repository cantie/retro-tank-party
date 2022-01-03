tool
extends Node

const GAME_ARGUMENTS_SETTING = 'network/rollback/log_inspector/replay_arguments'
const GAME_PORT_SETTING = 'network/rollback/log_inspector/replay_port'

var server: TCP_Server
var connection: StreamPeerTCP
var game_pid: int = 0

enum Status {
	NONE,
	LISTENING,
	CONNECTED,
}

signal started_listening ()
signal stopped_listening ()
signal game_connected ()
signal game_disconnected ()

func start_listening() -> void:
	if server:
		push_error("Replay server already listening")
	else:
		var port = 49111
		if ProjectSettings.has_setting(GAME_PORT_SETTING):
			port = ProjectSettings.get_setting(GAME_PORT_SETTING)
		
		server = TCP_Server.new()
		server.listen(port, "127.0.0.1")
		emit_signal("started_listening")

func stop_listening() -> void:
	if server:
		server.stop()
		server = null
		emit_signal("stopped_listening")

func disconnect_from_game(restart_listening: bool = true) -> void:
	if connection:
		connection.disconnect_from_host()
		emit_signal("game_disconnected")
		connection = null
	stop_game()
	if restart_listening:
		start_listening()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		disconnect_from_game(false)
		stop_listening()
		stop_game()

func launch_game() -> void:
	stop_game()
	
	var args := []
	
	var args_string = "replay"
	if ProjectSettings.has_setting(GAME_ARGUMENTS_SETTING):
		args_string = ProjectSettings.get_setting(GAME_ARGUMENTS_SETTING)
	for arg in args_string.split(" "):
		args.push_front(arg)
	
	game_pid = OS.execute(OS.get_executable_path(), args, false)

func stop_game() -> void:
	if game_pid != 0:
		OS.kill(game_pid)
		game_pid = 0

func is_game_started() -> bool:
	return game_pid > 0

func is_connected_to_game() -> bool:
	return connection and connection.is_connected_to_host()

func get_status() -> int:
	if is_connected_to_game():
		return Status.CONNECTED
	elif server and server.is_listening():
		return Status.LISTENING
	return Status.NONE

func send_message(msg: Dictionary) -> void:
	if not is_connected_to_game():
		push_error("Replay server: attempting to send message when not connected to game")
		return
	
	var data := JSON.print(msg)
	connection.put_u32(data.length())
	connection.put_data(data.to_utf8())

func poll() -> void:
	if connection:
		if connection.get_status() == StreamPeerTCP.STATUS_NONE or connection.get_status() == StreamPeerTCP.STATUS_ERROR:
			disconnect_from_game()
	if server and not connection and server.is_connection_available():
		connection = server.take_connection()
		stop_listening()
		emit_signal("game_connected")

func _process(delta: float) -> void:
	poll()
