extends VBoxContainer

const LogData = preload("res://addons/network-sync-rollback/log_inspector/LogData.gd")
const FrameDataGraphPeer = preload("res://addons/network-sync-rollback/log_inspector/FrameDataGraphPeer.tscn")

onready var peers_container = $PeersContainer
onready var scroll_bar = $ScrollBar

var cursor_time: int = -1 setget set_cursor_time

var log_data: LogData

signal cursor_time_changed (cursor_time)

func set_log_data(_log_data: LogData) -> void:
	log_data = _log_data

func refresh_from_log_data() -> void:
	scroll_bar.max_value = log_data.end_time - log_data.start_time
	
	# Make sure we have graphs for every peer.
	for peer_id in log_data.frames:
		if not peers_container.has_node(str(peer_id)):
			var peer_data_graph = FrameDataGraphPeer.instance()
			peer_data_graph.name = str(peer_id)
			peers_container.add_child(peer_data_graph)
			peer_data_graph.set_peer_id(peer_id)
			peer_data_graph.set_log_data(log_data)
			peer_data_graph.connect("cursor_time_changed", self, "_on_peer_data_graph_cursor_time_changed")

func _on_ScrollBar_value_changed(value: float) -> void:
	for peer_graph in peers_container.get_children():
		peer_graph.start_time = int(value)

func set_cursor_time(_cursor_time: int) -> void:
	if cursor_time != _cursor_time:
		cursor_time = _cursor_time
		emit_signal("cursor_time_changed", cursor_time)
	
	# We have to always do this in order to sync up all the peers.
	for peer_graph in peers_container.get_children():
		peer_graph.cursor_time = cursor_time

func _on_peer_data_graph_cursor_time_changed(_cursor_time: int) -> void:
	set_cursor_time(_cursor_time)
