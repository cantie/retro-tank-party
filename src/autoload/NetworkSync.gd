extends Node

const NakamaWebRTCNetworkAdaptor = preload("res://addons/network-sync-rollback/NakamaWebRTCNetworkAdaptor.gd")

func _ready() -> void:
	# Configure the input path mappings for SyncManager.
	SyncManager.update_input_path_mapping({
		'$': 0,
		'/root/Match/Game/Players/1': 1,
		'/root/Match/Game/Players/2': 2,
		'/root/Match/Game/Players/3': 3,
		'/root/Match/Game/Players/4': 4,
	})
	
	SyncManager.network_adaptor = NakamaWebRTCNetworkAdaptor.new()
	
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
