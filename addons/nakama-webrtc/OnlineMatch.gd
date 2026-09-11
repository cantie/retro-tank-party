extends Node

# For developers to set from the outside, for example:
#   OnlineMatch.max_players = 8
#   OnlineMatch.client_version = 'v1.2'
#   OnlineMatch.ice_servers = [ ... ]
#   OnlineMatch.use_network_relay = OnlineMatch.NetworkRelay.FORCED
var min_players := 2
var max_players := 4
var client_version := 'dev'
var ice_servers = [{ "urls": ["stun:stun.l.google.com:19302"] }]

enum NetworkRelay {
	AUTO,
	FORCED,
	DISABLED
}
var use_network_relay: int = NetworkRelay.AUTO

# Nakama variables:
var nakama_socket: NakamaSocket:
	set = _set_readonly_variable
var my_session_id: String:
	set = _set_readonly_variable, get = get_my_session_id
var match_id: String:
	set = _set_readonly_variable, get = get_match_id
var matchmaker_ticket: String:
	set = _set_readonly_variable, get = get_matchmaker_ticket

# WebRTC variables:
var _webrtc_multiplayer: WebRTCMultiplayerPeer
var _webrtc_peers: Dictionary
var _webrtc_peers_connected: Dictionary

var players: Dictionary
var _next_peer_id: int

enum MatchState {
	LOBBY = 0,
	MATCHING = 1,
	CONNECTING = 2,
	WAITING_FOR_ENOUGH_PLAYERS = 3,
	READY = 4,
	PLAYING = 5,
}
var match_state: int = MatchState.LOBBY:
	set = _set_readonly_variable, get = get_match_state

enum MatchMode {
	NONE = 0,
	CREATE = 1,
	JOIN = 2,
	MATCHMAKER = 3,
}
var match_mode: int = MatchMode.NONE:
	set = _set_readonly_variable, get = get_match_mode

enum PlayerStatus {
	CONNECTING = 0,
	CONNECTED = 1,
}

enum MatchOpCode {
	WEBRTC_PEER_METHOD = 9001,
	JOIN_SUCCESS = 9002,
	JOIN_ERROR = 9003,
}

enum JoinErrorReason {
	MATCH_HAS_ALREADY_BEGUN,
	MATCH_IS_FULL,
}

const JOIN_ERROR_MESSAGES := {
	JoinErrorReason.MATCH_HAS_ALREADY_BEGUN: "Sorry! The match has already begun.",
	JoinErrorReason.MATCH_IS_FULL: "Sorry! The match is full.",
}

enum ErrorCode {
	MATCH_CREATE_FAILED,
	JOIN_MATCH_FAILED,
	START_MATCHMAKING_FAILED,
	WEBSOCKET_CONNECTION_ERROR,
	HOST_DISCONNECTED,
	MATCHMAKER_ERROR,
	CLIENT_VERSION_ERROR,
	CLIENT_JOIN_ERROR,
	WEBRTC_OFFER_ERROR,
}

const ERROR_MESSAGES := {
	ErrorCode.MATCH_CREATE_FAILED: "Failed to create match",
	ErrorCode.JOIN_MATCH_FAILED: "Unable to join match",
	ErrorCode.START_MATCHMAKING_FAILED: "Unable to join match making pool",
	ErrorCode.WEBSOCKET_CONNECTION_ERROR: "WebSocket connection error",
	ErrorCode.HOST_DISCONNECTED: "Host has disconnected",
	ErrorCode.MATCHMAKER_ERROR: "Matchmaker error",
	ErrorCode.CLIENT_VERSION_ERROR: "Client version doesn't match host",
	ErrorCode.CLIENT_JOIN_ERROR: "Client not allowed to join",
	ErrorCode.WEBRTC_OFFER_ERROR: "Unable to create WebRTC offer",
}

signal error (message)
signal error_code (code, message, extra)
signal disconnected ()

signal match_created (match_id)
signal match_joined (match_id)
signal matchmaker_matched (players)

signal player_joined (player)
signal player_left (player)
signal player_status_changed (player, status)

signal match_ready (players)
signal match_not_ready ()

signal webrtc_peer_added (webrtc_peer, player)
signal webrtc_peer_removed (webrtc_peer, player)

class Player:
	var session_id: String
	var peer_id: int
	var username: String

	func _init(_session_id: String, _username: String, _peer_id: int) -> void:
		session_id = _session_id
		username = _username
		peer_id = _peer_id

	static func from_presence(presence: NakamaRTAPI.UserPresence, _peer_id: int) -> Player:
		return Player.new(presence.session_id, presence.username, _peer_id)

	static func from_dict(data: Dictionary) -> Player:
		return Player.new(data['session_id'], data['username'], int(data['peer_id']))

	func to_dict() -> Dictionary:
		return {
			session_id = session_id,
			username = username,
			peer_id = peer_id,
		}

static func serialize_players(_players: Dictionary) -> Dictionary:
	var result := {}
	for key in _players:
		result[key] = _players[key].to_dict()
	return result

static func unserialize_players(_players: Dictionary) -> Dictionary:
	var result := {}
	for key in _players:
		result[key] = Player.from_dict(_players[key])
	return result

func _set_readonly_variable(_value) -> void:
	pass

func _set_nakama_socket(_nakama_socket: NakamaSocket) -> void:
	if nakama_socket == _nakama_socket:
		return

	if nakama_socket:
		if nakama_socket.closed.is_connected(_on_nakama_closed):
			nakama_socket.closed.disconnect(_on_nakama_closed)
		if nakama_socket.received_error.is_connected(_on_nakama_error):
			nakama_socket.received_error.disconnect(_on_nakama_error)
		if nakama_socket.received_match_state.is_connected(_on_nakama_match_state):
			nakama_socket.received_match_state.disconnect(_on_nakama_match_state)
		if nakama_socket.received_match_presence.is_connected(_on_nakama_match_presence):
			nakama_socket.received_match_presence.disconnect(_on_nakama_match_presence)
		if nakama_socket.received_matchmaker_matched.is_connected(_on_nakama_matchmaker_matched):
			nakama_socket.received_matchmaker_matched.disconnect(_on_nakama_matchmaker_matched)

	nakama_socket = _nakama_socket
	if nakama_socket:
		nakama_socket.closed.connect(_on_nakama_closed)
		nakama_socket.received_error.connect(_on_nakama_error)
		nakama_socket.received_match_state.connect(_on_nakama_match_state)
		nakama_socket.received_match_presence.connect(_on_nakama_match_presence)
		nakama_socket.received_matchmaker_matched.connect(_on_nakama_matchmaker_matched)

func _emit_error(code: int, extra = null):
	var message = ERROR_MESSAGES[code]
	if code == ErrorCode.CLIENT_JOIN_ERROR:
		message = JOIN_ERROR_MESSAGES[extra]
	error.emit(message)
	error_code.emit(code, message, extra)

func create_match(_nakama_socket: NakamaSocket) -> void:
	leave()
	_set_nakama_socket(_nakama_socket)
	match_mode = MatchMode.CREATE

	var data = await nakama_socket.create_match_async()
	if data.is_exception():
		leave()
		_emit_error(ErrorCode.MATCH_CREATE_FAILED, data.get_exception())
	else:
		_on_nakama_match_created(data)

func join_match(_nakama_socket: NakamaSocket, _match_id: String) -> void:
	leave()
	_set_nakama_socket(_nakama_socket)
	match_mode = MatchMode.JOIN

	var data = await nakama_socket.join_match_async(_match_id)
	if data.is_exception():
		leave()
		_emit_error(ErrorCode.JOIN_MATCH_FAILED, data.get_exception())
	else:
		_on_nakama_match_join(data)

func start_matchmaking(_nakama_socket: NakamaSocket, data: Dictionary = {}) -> void:
	leave()
	_set_nakama_socket(_nakama_socket)
	match_mode = MatchMode.MATCHMAKER

	if data.has('min_count'):
		data['min_count'] = max(min_players, data['min_count'])
	else:
		data['min_count'] = min_players

	if data.has('max_count'):
		data['max_count'] = min(max_players, data['max_count'])
	else:
		data['max_count'] = max_players

	if client_version != '':
		if not data.has('string_properties'):
			data['string_properties'] = {}
		data['string_properties']['client_version'] = client_version

		var query = '+properties.client_version:' + client_version
		if data.has('query'):
			data['query'] += ' ' + query
		else:
			data['query'] = query

	match_state = MatchState.MATCHING
	var result = await nakama_socket.add_matchmaker_async(data.get('query', '*'), data['min_count'], data['max_count'], data.get('string_properties', {}), data.get('numeric_properties', {}))
	if result.is_exception():
		leave()
		_emit_error(ErrorCode.START_MATCHMAKING_FAILED, result.get_exception())
	else:
		matchmaker_ticket = result.ticket

func start_playing() -> void:
	assert(match_state == MatchState.READY)
	match_state = MatchState.PLAYING

func leave(close_socket: bool = false) -> void:
	# WebRTC disconnect.
	if _webrtc_multiplayer:
		_webrtc_multiplayer.close()
		multiplayer.multiplayer_peer = null

	# Nakama disconnect.
	if nakama_socket:
		if match_id:
			await nakama_socket.leave_match_async(match_id)
		elif matchmaker_ticket:
			await nakama_socket.remove_matchmaker_async(matchmaker_ticket)
		if close_socket:
			nakama_socket.close()
			_set_nakama_socket(null)

	# Initialize all the variables to their default state.
	my_session_id = ''
	match_id = ''
	matchmaker_ticket = ''
	_create_webrtc_multiplayer()
	_webrtc_peers = {}
	_webrtc_peers_connected = {}
	players = {}
	_next_peer_id = 1
	match_state = MatchState.LOBBY
	match_mode = MatchMode.NONE

func _create_webrtc_multiplayer() -> void:
	if _webrtc_multiplayer:
		if _webrtc_multiplayer.peer_connected.is_connected(_on_webrtc_peer_connected):
			_webrtc_multiplayer.peer_connected.disconnect(_on_webrtc_peer_connected)
		if _webrtc_multiplayer.peer_disconnected.is_connected(_on_webrtc_peer_disconnected):
			_webrtc_multiplayer.peer_disconnected.disconnect(_on_webrtc_peer_disconnected)

	_webrtc_multiplayer = WebRTCMultiplayerPeer.new()
	_webrtc_multiplayer.peer_connected.connect(_on_webrtc_peer_connected)
	_webrtc_multiplayer.peer_disconnected.connect(_on_webrtc_peer_disconnected)

func get_my_session_id() -> String:
	return my_session_id

func get_match_id() -> String:
	return match_id

func get_matchmaker_ticket() -> String:
	return matchmaker_ticket

func get_match_mode() -> int:
	return match_mode

func get_match_state() -> int:
	return match_state

func get_session_id(peer_id: int):
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			return session_id
	return null

func get_player_by_peer_id(peer_id: int) -> Player:
	var session_id = get_session_id(peer_id)
	if session_id:
		return players[session_id]
	return null

func get_players_by_peer_id() -> Dictionary:
	var result := {}
	for player in players.values():
		result[player.peer_id] = player
	return result

func get_player_names_by_peer_id() -> Dictionary:
	var result := {}
	for session_id in players:
		result[players[session_id]['peer_id']] = players[session_id]['username']
	return result

func get_webrtc_peer(session_id: String) -> WebRTCPeerConnection:
	return _webrtc_peers.get(session_id, null)

func get_webrtc_peer_by_peer_id(peer_id: int) -> WebRTCPeerConnection:
	var player = get_player_by_peer_id(peer_id)
	if player:
		return _webrtc_peers.get(player.session_id, null)
	return null

func _on_nakama_error(data) -> void:
	print ("ERROR:")
	print(data)
	leave()
	_emit_error(ErrorCode.WEBSOCKET_CONNECTION_ERROR, data)

func _on_nakama_closed() -> void:
	leave()
	disconnected.emit()

func _on_nakama_match_created(data: NakamaRTAPI.Match) -> void:
	match_id = data.match_id
	my_session_id = data.self_user.session_id
	var my_player = Player.from_presence(data.self_user, 1)
	players[my_session_id] = my_player
	_next_peer_id = 2

	_webrtc_multiplayer.create_mesh(1)
	multiplayer.multiplayer_peer = _webrtc_multiplayer

	match_created.emit(match_id)
	player_joined.emit(my_player)
	player_status_changed.emit(my_player, PlayerStatus.CONNECTED)

func _on_nakama_match_presence(data: NakamaRTAPI.MatchPresenceEvent) -> void:
	for u in data.joins:
		if u.session_id == my_session_id:
			continue

		if match_mode == MatchMode.CREATE:
			if match_state == MatchState.PLAYING:
				nakama_socket.send_match_state_async(match_id, MatchOpCode.JOIN_ERROR, JSON.stringify({
					target = u['session_id'],
					code = JoinErrorReason.MATCH_HAS_ALREADY_BEGUN,
					reason = JOIN_ERROR_MESSAGES[JoinErrorReason.MATCH_HAS_ALREADY_BEGUN],
				}))

			elif players.size() < max_players:
				var new_player = Player.from_presence(u, _next_peer_id)
				_next_peer_id += 1
				players[u.session_id] = new_player
				player_joined.emit(new_player)

				nakama_socket.send_match_state_async(match_id, MatchOpCode.JOIN_SUCCESS, JSON.stringify({
					players = serialize_players(players),
					client_version = client_version,
				}))

				_webrtc_connect_peer(new_player)
			else:
				nakama_socket.send_match_state_async(match_id, MatchOpCode.JOIN_ERROR, JSON.stringify({
					target = u['session_id'],
					code = JoinErrorReason.MATCH_IS_FULL,
					reason = JOIN_ERROR_MESSAGES[JoinErrorReason.MATCH_IS_FULL],
				}))
		elif match_mode == MatchMode.MATCHMAKER:
			player_joined.emit(players[u.session_id])
			_webrtc_connect_peer(players[u.session_id])

	for u in data.leaves:
		if u.session_id == my_session_id:
			continue
		if not players.has(u.session_id):
			continue

		var player = players[u.session_id]
		_webrtc_disconnect_peer(player)

		if player.peer_id == 1:
			leave()
			_emit_error(ErrorCode.HOST_DISCONNECTED)
		else:
			players.erase(u.session_id)
			player_left.emit(player)

			if players.size() < min_players:
				if match_state == MatchState.READY:
					match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS
					match_not_ready.emit()
			else:
				if _webrtc_peers_connected.size() == players.size() - 1:
					match_state = MatchState.READY;
					match_ready.emit(players)

func _on_nakama_match_join(data: NakamaRTAPI.Match) -> void:
	match_id = data.match_id
	my_session_id = data.self_user.session_id

	if match_mode == MatchMode.JOIN:
		match_joined.emit(match_id)
	elif match_mode == MatchMode.MATCHMAKER:
		for u in data.presences:
			if u.session_id == my_session_id:
					continue
			_webrtc_connect_peer(players[u.session_id])

func _on_nakama_matchmaker_matched(data: NakamaRTAPI.MatchmakerMatched) -> void:
	if data.is_exception():
		leave()
		_emit_error(ErrorCode.MATCHMAKER_ERROR, data.get_exception())
		return

	my_session_id = data.self_user.presence.session_id

	for u in data.users:
		players[u.presence.session_id] = Player.from_presence(u.presence, 0)
	var session_ids = players.keys();
	session_ids.sort()
	for session_id in session_ids:
		players[session_id].peer_id = _next_peer_id
		_next_peer_id += 1

	_webrtc_multiplayer.create_mesh(players[my_session_id].peer_id)
	multiplayer.multiplayer_peer = _webrtc_multiplayer

	matchmaker_matched.emit(players)
	player_status_changed.emit(players[my_session_id], PlayerStatus.CONNECTED)

	var result = await nakama_socket.join_matched_async(data)
	if result.is_exception():
		leave()
		_emit_error(ErrorCode.JOIN_MATCH_FAILED, result.get_exception())
	else:
		_on_nakama_match_join(result)

func _on_nakama_match_state(data: NakamaRTAPI.MatchData) -> void:
	var content = JSON.parse_string(data.data)
	if content == null:
		return

	if data.op_code == MatchOpCode.WEBRTC_PEER_METHOD:
		if content['target'] == my_session_id:
			var session_id = data.presence.session_id
			if not _webrtc_peers.has(session_id):
				return
			var webrtc_peer = _webrtc_peers[session_id]
			match content['method']:
				'set_remote_description':
					webrtc_peer.set_remote_description(content['type'], content['sdp'])

				'add_ice_candidate':
					if _webrtc_check_ice_candidate(content['name']):
						webrtc_peer.add_ice_candidate(content['media'], content['index'], content['name'])

				'reconnect':
					_webrtc_multiplayer.remove_peer(players[session_id]['peer_id'])
					_webrtc_reconnect_peer(players[session_id])
	if data.op_code == MatchOpCode.JOIN_SUCCESS && match_mode == MatchMode.JOIN:
		var host_client_version = content.get('client_version', '')
		if client_version != host_client_version:
			leave()
			_emit_error(ErrorCode.CLIENT_VERSION_ERROR, host_client_version)
			return

		var content_players = unserialize_players(content['players'])
		for session_id in content_players:
			if not players.has(session_id):
				players[session_id] = content_players[session_id]
				_webrtc_connect_peer(players[session_id])
				player_joined.emit(players[session_id])
				if session_id == my_session_id:
					_webrtc_multiplayer.create_mesh(players[session_id].peer_id)
					multiplayer.multiplayer_peer = _webrtc_multiplayer

					player_status_changed.emit(players[session_id], PlayerStatus.CONNECTED)
	if data.op_code == MatchOpCode.JOIN_ERROR:
		if content['target'] == my_session_id:
			leave()
			_emit_error(ErrorCode.CLIENT_JOIN_ERROR, content['code'])
			return

func _webrtc_connect_peer(player: Player) -> void:
	if _webrtc_peers.has(player.session_id):
		return

	if match_state == MatchState.READY:
		match_not_ready.emit()

	if match_state != MatchState.PLAYING:
		match_state = MatchState.CONNECTING

	var webrtc_peer := WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": ice_servers,
	})
	webrtc_peer.session_description_created.connect(_on_webrtc_peer_session_description_created.bind(player.session_id))
	webrtc_peer.ice_candidate_created.connect(_on_webrtc_peer_ice_candidate_created.bind(player.session_id))

	_webrtc_peers[player.session_id] = webrtc_peer

	_webrtc_multiplayer.add_peer(webrtc_peer, player.peer_id)

	webrtc_peer_added.emit(webrtc_peer, player)

	if my_session_id.casecmp_to(player.session_id) < 0:
		var result = webrtc_peer.create_offer()
		if result != OK:
			_emit_error(ErrorCode.WEBRTC_OFFER_ERROR, result)

func _webrtc_disconnect_peer(player: Player) -> void:
	var webrtc_peer = _webrtc_peers[player.session_id]
	webrtc_peer_removed.emit(webrtc_peer, player)
	webrtc_peer.close()
	_webrtc_peers.erase(player.session_id)
	_webrtc_peers_connected.erase(player.session_id)

func _webrtc_reconnect_peer(player: Player) -> void:
	var old_webrtc_peer = _webrtc_peers[player.session_id]
	if old_webrtc_peer:
		webrtc_peer_removed.emit(old_webrtc_peer, player)
		old_webrtc_peer.close()

	_webrtc_peers_connected.erase(player.session_id)
	_webrtc_peers.erase(player.session_id)

	print ("Starting WebRTC reconnect...")

	_webrtc_connect_peer(player)

	player_status_changed.emit(player, PlayerStatus.CONNECTING)

	if match_state == MatchState.READY:
		match_state = MatchState.CONNECTING
		match_not_ready.emit()

func _webrtc_check_ice_candidate(name: String) -> bool:
	if use_network_relay == NetworkRelay.AUTO:
		return true

	var is_relay: bool = "typ relay" in name

	if use_network_relay == NetworkRelay.FORCED:
		return is_relay
	return !is_relay

func _on_webrtc_peer_session_description_created(type: String, sdp: String, session_id: String) -> void:
	var webrtc_peer = _webrtc_peers[session_id]
	webrtc_peer.set_local_description(type, sdp)

	nakama_socket.send_match_state_async(match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.stringify({
		method = "set_remote_description",
		target = session_id,
		type = type,
		sdp = sdp,
	}))

func _on_webrtc_peer_ice_candidate_created(media: String, index: int, name: String, session_id: String) -> void:
	if not _webrtc_check_ice_candidate(name):
		return

	nakama_socket.send_match_state_async(match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.stringify({
		method = "add_ice_candidate",
		target = session_id,
		media = media,
		index = index,
		name = name,
	}))

func _on_webrtc_peer_connected(peer_id: int) -> void:
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			_webrtc_peers_connected[session_id] = true
			print ("WebRTC peer connected: " + str(peer_id))
			player_status_changed.emit(players[session_id], PlayerStatus.CONNECTED)

	if _webrtc_peers_connected.size() == players.size() - 1:
		if players.size() >= min_players:
			match_state = MatchState.READY;
			match_ready.emit(players)
		else:
			match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS

func _on_webrtc_peer_disconnected(peer_id: int) -> void:
	print ("WebRTC peer disconnected: " + str(peer_id))

	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			if my_session_id.casecmp_to(session_id) < 0:
				nakama_socket.send_match_state_async(match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.stringify({
					method = "reconnect",
					target = session_id,
				}))

				_webrtc_reconnect_peer(players[session_id])
