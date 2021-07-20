extends "res://addons/network-sync-rollback/NetworkAdaptor.gd"

#onready var OnlineMatch = get_node('/root/OnlineMatch')

const DATA_CHANNEL_ID := 42

# If buffer exceeds this value, skip sending messages (except ping backs).
var max_buffered_amount := 0

var _data_channels := {}
var _last_message_sent_hash: int
var _hashing_context: HashingContext

func _init() -> void:
	_hashing_context = HashingContext.new()

func attach_network_adaptor(sync_manager) -> void:
	if OnlineMatch:
		OnlineMatch.connect("webrtc_peer_added", self, '_on_OnlineMatch_webrtc_peer_added')
		OnlineMatch.connect("webrtc_peer_removed", self, '_on_OnlineMatch_webrtc_peer_removed')
		OnlineMatch.connect("disconnected", self, '_on_OnlineMatch_disconnected')
	else:
		push_error("Can't find OnlineMatch singleton that the NakamaWebRTCNetworkAdaptor depends on!")

func detach_network_adaptor(sync_manager) -> void:
	if OnlineMatch:
		OnlineMatch.disconnect("webrtc_peer_added", self, '_on_OnlineMatch_webrtc_peer_added')
		OnlineMatch.disconnect("webrtc_peer_removed", self, '_on_OnlineMatch_webrtc_peer_removed')
		OnlineMatch.disconnect("disconnected", self, '_on_OnlineMatch_disconnected')

func start_network_adaptor(sync_manager) -> void:
	pass

func stop_network_adaptor(sync_manager) -> void:
	pass

func _on_OnlineMatch_webrtc_peer_added(webrtc_peer: WebRTCPeerConnection, player: OnlineMatch.Player) -> void:
	print ("Peer added -- trying to re-establish the data channel")
	
	var peer_id := player.peer_id
	
	if _data_channels.has(peer_id):
		_data_channels.erase(peer_id)
	
	var data_channel = webrtc_peer.create_data_channel('SyncManager', {
		negotiated = true,
		id = DATA_CHANNEL_ID,
		#maxRetransmits = 0,
		maxPacketLifeTime = 1000,
		ordered = false,
	})
	data_channel.write_mode = WebRTCDataChannel.WRITE_MODE_BINARY
	_data_channels[peer_id] = data_channel

func _on_OnlineMatch_webrtc_peer_removed(webrtc_peer: WebRTCPeerConnection, player: OnlineMatch.Player) -> void:
	var peer_id := player.peer_id
	if _data_channels.has(peer_id):
		# Can this cause problems with re-establishing the connection?
		#_data_channels[peer_id].close()
		_data_channels.erase(peer_id)

func _on_OnlineMatch_disconnected() -> void:
	_data_channels.clear()

func send_input_tick(peer_id: int, msg: PoolByteArray) -> void:
	if _data_channels.has(peer_id) and _data_channels[peer_id].get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		var data_channel: WebRTCDataChannel = _data_channels[peer_id]
		
		# Skip sending if the data channel is over the max buffered amount.
		# Assuming the max_buffered_amount value is well tuned, this will kick
		# in when SCTP's flow control turns on, and we want to wait until it
		# turns back off before sending any more data.
		if max_buffered_amount > 0 and data_channel.get_buffered_amount() > max_buffered_amount:
			print ("[%s] Skipping send because buffer is too full (%s bytes)" % [SyncManager.current_tick, data_channel.get_buffered_amount()])
			return
		
		# Avoid sending duplicate messages. We'll let WebRTC's reliability
		# layer deal with making sure the message arrives, otherwise we can run
		# afoul of SCTP's flow control algorithm.
		var msg_hash = hash(msg)
		if msg_hash != _last_message_sent_hash:
			data_channel.put_packet(msg)
			_last_message_sent_hash = msg_hash
		else:
			print ("Skipping duplicate message")

func poll() -> void:
	for peer_id in _data_channels:
		var data_channel: WebRTCDataChannel = _data_channels[peer_id]
		var data_channel_state = data_channel.get_ready_state()
		if data_channel_state != WebRTCDataChannel.STATE_OPEN:
			# Attempt to reconnect the data channel, if necessary.
			if data_channel_state != WebRTCDataChannel.STATE_CONNECTING:
				var player = OnlineMatch.get_player_by_peer_id(peer_id)
				var webrtc_peer = OnlineMatch.get_webrtc_peer(player.session_id)
				_on_OnlineMatch_webrtc_peer_added(webrtc_peer, player)
			continue
		
		data_channel.poll()
		
		# Get all received messages.
		while data_channel.get_available_packet_count() > 0:
			var msg = data_channel.get_packet()
			emit_signal("received_input_tick", peer_id, msg)
