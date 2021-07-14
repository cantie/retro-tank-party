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
	func serialize_input(input: Dictionary) -> PoolByteArray:
		var buffer := StreamPeerBuffer.new()
		buffer.resize(SyncManager.DEFAULT_MESSAGE_BUFFER_SIZE)
		
		buffer.put_u8(input.size())
		for path in input:
			var mapped_path = input_path_mapping[path]
			buffer.put_u8(mapped_path)
			if mapped_path == 0:
				buffer.put_u32(input[path])
				continue
				
			buffer.put_u8(input[path].size())
			for input_key in input[path]:
				buffer.put_8(input_key)
				
				var value = input[path][input_key]
				match input_key:
					Tank.PlayerInput.TURRET_ROTATION:
						buffer.put_float(value)
					
					Tank.PlayerInput.CONTROL_SCHEME, \
					Tank.PlayerInput.SHOOTING, \
					Tank.PlayerInput.USING_ABILITY:
						buffer.put_u8(value)
					
					Tank.PlayerInput.INPUT_VECTOR:
						buffer.put_float(value.x)
						buffer.put_float(value.y)
	
		buffer.resize(buffer.get_position())
		return buffer.data_array

	func unserialize_input(serialized: PoolByteArray) -> Dictionary:
		var buffer := StreamPeerBuffer.new()
		buffer.put_data(serialized)
		buffer.seek(0)
		
		var input := {}
		
		var path_count = buffer.get_u8()
		for path_index in range(path_count):
			var mapped_path = buffer.get_u8()
			if mapped_path == 0:
				input['$'] = buffer.get_u32()
				continue
			
			var path = '/root/Match/Game/Players/' + str(mapped_path)
			input[path] = {}
			
			var input_count = buffer.get_u8()
			for input_index in range(input_count):
				var input_key = buffer.get_8()
				
				var value
				match input_key:
					Tank.PlayerInput.TURRET_ROTATION:
						value = buffer.get_float()
					
					Tank.PlayerInput.CONTROL_SCHEME, \
					Tank.PlayerInput.SHOOTING, \
					Tank.PlayerInput.USING_ABILITY:
						value = buffer.get_u8()
					
					Tank.PlayerInput.INPUT_VECTOR:
						value = Vector2(buffer.get_float(), buffer.get_float())
				
				if value != null:
					input[path][input_key] = value
		
		return input

func _ready() -> void:
	SyncManager.network_adaptor = NakamaWebRTCNetworkAdaptor.new()
	SyncManager.message_serializer = RTPMessageSerializer.new()
	
	# Tweak some settings
	#SyncManager.max_buffer_size = 20
	SyncManager.debug_message_bytes = 150
	#SyncManager.max_input_frames_per_message = 5
	#SyncManager.max_messages_at_once = 2
	SyncManager.interpolation = true
	SyncManager.skip_ticks_after_sync_regained = 2
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
