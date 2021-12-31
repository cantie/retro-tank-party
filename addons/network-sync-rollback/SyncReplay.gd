extends Node

const DummyNetworkAdaptor = preload("res://addons/network-sync-rollback/DummyNetworkAdaptor.gd")

var server: TCP_Server
var connection: StreamPeerTCP

signal setup_match (my_peer_id, peer_ids, match_info)

func _ready() -> void:
	pass

func listen(port: int = 49111) -> void:
	if server:
		push_error("SyncReplay already listening")
	else:
		server = TCP_Server.new()
		server.listen(port, "127.0.0.1")

func stop() -> void:
	if connection:
		connection.disconnect_from_host()
		connection = null
	if server:
		server.stop()
		server = null

func poll() -> void:
	if server and not connection:
		connection = server.take_connection()
	if connection and connection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		while connection.get_available_bytes() >= 4:
			var length = connection.get_u32()
			var data = connection.get_utf8_string(length)
			
			var result = JSON.parse(data)
			if result.error != OK:
				print ("SyncReplay received invalid JSON: %s" % data)
				continue
			
			process_message(result.result)

func _process(delta: float) -> void:
	poll()

func process_message(msg: Dictionary) -> void:
	if not msg.has('type'):
		push_error("SyncReplay message has no 'type' property: %s" % msg)
		return
	
	var type = msg['type']
	match type:
		"setup_match":
			var my_peer_id = msg.get('my_peer_id', 1)
			var peer_ids = msg.get('peer_ids', [])
			var match_info = msg.get('match_info', {})
			_do_setup_match(my_peer_id, peer_ids, match_info)
		
		"load_state":
			var state = msg.get('state', {})
			_do_load_state(state)
			
		_:
			push_error("SyncReplay message has unknown type: %s" % type)

func _do_setup_match(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	
	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
	SyncManager.mechanized = true
	
	# Abuse WebRTCMultiplayer in order to set our peer id.
	var faux_multiplayer = WebRTCMultiplayer.new()
	faux_multiplayer.initialize(my_peer_id)
	get_tree().set_network_peer(faux_multiplayer)
	
	for peer_id in peer_ids:
		SyncManager.add_peer(peer_id)
	
	emit_signal("setup_match", my_peer_id, peer_ids, match_info)
	
	SyncManager.start()

func _do_load_state(state: Dictionary) -> void:
	SyncManager._call_load_state(state)
