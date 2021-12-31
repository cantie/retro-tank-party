extends "res://addons/network-sync-rollback/NetworkAdaptor.gd"

func send_ping(peer_id: int, msg: Dictionary) -> void:
	pass

func send_ping_back(peer_id: int, msg: Dictionary) -> void:
	pass

func send_remote_start(peer_id: int) -> void:
	pass

func send_remote_stop(peer_id: int) -> void:
	pass

func send_input_tick(peer_id: int, msg: PoolByteArray) -> void:
	pass
