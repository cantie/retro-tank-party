extends Node

const NakamaWebRTCNetworkAdaptor = preload("res://addons/network-sync-rollback/NakamaWebRTCNetworkAdaptor.gd")
const Tank = preload("res://src/objects/Tank.gd")

const input_path_mapping := {
	'$': 0,
	'/root/Match/Game/Players/1': 1,
	'/root/Match/Game/Players/2': 2,
	'/root/Match/Game/Players/3': 3,
	'/root/Match/Game/Players/4': 4,
	'/root/Practice/Game/Players/1': 1,
}

class RTPMessageSerializer extends SyncManager.MessageSerializer:
	enum HeaderFlags {
		RETRO_CONTROLS = 0x01,
		HAS_INPUT_VECTOR = 0x02,
		SHOOTING = 0x04,
		USING_ABILITY = 0x08,
	}
	
	func serialize_input(all_input: Dictionary) -> PoolByteArray:
		var buffer := StreamPeerBuffer.new()
		buffer.resize(20)
		
		buffer.put_u8(all_input.size())
		for path in all_input:
			var mapped_path = input_path_mapping[path]
			buffer.put_u8(mapped_path)
			if mapped_path == 0:
				buffer.put_u32(all_input[path])
				continue
			
			var input = all_input[path]
			
			var header: int = 0
			if input.get(Tank.PlayerInput.CONTROL_SCHEME, GameSettings.ControlScheme.MODERN) == GameSettings.ControlScheme.RETRO:
				header |= HeaderFlags.RETRO_CONTROLS
			if input.has(Tank.PlayerInput.INPUT_VECTOR):
				header |= HeaderFlags.HAS_INPUT_VECTOR
			if input.get(Tank.PlayerInput.SHOOTING, false):
				header |= HeaderFlags.SHOOTING
			if input.get(Tank.PlayerInput.USING_ABILITY, false):
				header |= HeaderFlags.USING_ABILITY
			
			buffer.put_u8(header)
			buffer.put_float(input.get(Tank.PlayerInput.TURRET_ROTATION, 0.0))
			if input.has(Tank.PlayerInput.INPUT_VECTOR):
				var input_vector: Vector2 = input[Tank.PlayerInput.INPUT_VECTOR]
				buffer.put_float(input_vector.x)
				buffer.put_float(input_vector.y)
		
		buffer.resize(buffer.get_position())
		return buffer.data_array

	func unserialize_input(serialized: PoolByteArray) -> Dictionary:
		var buffer := StreamPeerBuffer.new()
		buffer.put_data(serialized)
		buffer.seek(0)
		
		var all_input := {}
		
		var path_count = buffer.get_u8()
		for path_index in range(path_count):
			var mapped_path = buffer.get_u8()
			if mapped_path == 0:
				all_input['$'] = buffer.get_u32()
				continue
			
			var input := {}
			
			var header = buffer.get_u8()
			if header & HeaderFlags.RETRO_CONTROLS:
				input[Tank.PlayerInput.CONTROL_SCHEME] = GameSettings.ControlScheme.RETRO
			if header & HeaderFlags.SHOOTING:
				input[Tank.PlayerInput.SHOOTING] = true
			if header & HeaderFlags.USING_ABILITY:
				input[Tank.PlayerInput.USING_ABILITY] = true
			
			input[Tank.PlayerInput.TURRET_ROTATION] = buffer.get_float()
			
			if header & HeaderFlags.HAS_INPUT_VECTOR:
				input[Tank.PlayerInput.INPUT_VECTOR] = Vector2(
					buffer.get_float(),
					buffer.get_float())
			
			var path = '/root/Match/Game/Players/' + str(mapped_path)
			all_input[path] = input
		
		return all_input

func _ready() -> void:
	var network_adaptor = NakamaWebRTCNetworkAdaptor.new()
	network_adaptor.max_buffered_amount = 200
	
	SyncManager.network_adaptor = network_adaptor
	SyncManager.message_serializer = RTPMessageSerializer.new()
	
	# Tweak some settings
	#SyncManager.max_buffer_size = 20
	SyncManager.debug_message_bytes = 600
	SyncManager.max_input_frames_per_message = 20
	SyncManager.max_messages_at_once = 2
	SyncManager.debug_skip_nth_message = 0
	SyncManager.interpolation = true
	SyncManager.skip_ticks_after_sync_regained = 5
	#SyncManager.message_resend_frequency = (1.0 / Engine.iterations_per_second) / 2.0
	
	SyncManager.connect("state_loaded", self, "_on_SyncManager_state_loaded")
	SyncManager.connect("tick_finished", self, "_on_SyncManager_tick_finished")

func _on_SyncManager_state_loaded(_rollback_ticks: int) -> void:
	# After loading all the positions from the end of the tick before the
	# tick we are going to re-run, we need to manually run a physics tick,
	# in order to clear the old collsion data, and set things up as they
	# were before running this tick last time.
	Physics.simulate()
	# Apparently, we actually have to run it twice, otherwise newly
	# respawned body's won't detect their collisions because the body won't
	# really be in the physics server until the next tick.
	Physics.simulate()

func _on_SyncManager_tick_finished(is_rollback: bool) -> void:
	if is_rollback:
		Physics.simulate()
