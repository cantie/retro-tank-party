tool
extends Control

const LogData = preload("res://addons/godot-rollback-netcode/log_inspector/LogData.gd")
const ReplayServer = preload("res://addons/godot-rollback-netcode/log_inspector/ReplayServer.gd")

onready var file_dialog = $FileDialog
onready var progress_dialog = $ProgressDialog
onready var data_description_label = $MarginContainer/VBoxContainer/LoadToolbar/DataDescriptionLabel
onready var data_description_label_default_text = data_description_label.text
onready var mode_button = $MarginContainer/VBoxContainer/HBoxContainer/ModeButton
onready var state_input_viewer = $MarginContainer/VBoxContainer/StateInputViewer
onready var frame_viewer = $MarginContainer/VBoxContainer/FrameViewer
onready var replay_server = $ReplayServer
onready var replay_server_status_label = $MarginContainer/VBoxContainer/ReplayToolbar/ReplayStatusLabel

enum DataMode {
	STATE_INPUT,
	FRAME,
}

const LOADING_LABEL := "Loading %s..."

var log_data: LogData = LogData.new()

var _files_to_load := []

func _ready() -> void:
	state_input_viewer.set_log_data(log_data)
	frame_viewer.set_log_data(log_data)
	
	log_data.connect("load_error", self, "_on_log_data_load_error")
	log_data.connect("load_progress", self, "_on_log_data_load_progress")
	log_data.connect("load_finished", self, "_on_log_data_load_finished")
	log_data.connect("data_updated", self, "refresh_from_log_data")
	
	state_input_viewer.set_replay_server(replay_server)
	
	# Show and make full screen if the scene is being run on its own.
	if get_parent() == get_tree().root:
		visible = true
		anchor_right = 1
		anchor_bottom = 1
		margin_right = 0
		margin_bottom = 0
		setup_log_inspector()

func setup_log_inspector() -> void:
	replay_server.start_listening()

func _on_ClearButton_pressed() -> void:
	log_data.clear()
	data_description_label.text = data_description_label_default_text
	state_input_viewer.clear()
	frame_viewer.clear()

func _on_AddUserLogButton_pressed() -> void:
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.current_dir = "user://detailed_logs/"
	file_dialog.current_file = ''
	file_dialog.current_path = ''
	file_dialog.show_modal()
	file_dialog.invalidate()

func _on_AddAnyLogButton_pressed() -> void:
	var dir := Directory.new()
	
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.current_dir = dir.get_current_dir()
	file_dialog.current_file = ''
	file_dialog.current_path = ''
	file_dialog.show_modal()
	file_dialog.invalidate()

func _on_FileDialog_files_selected(paths: PoolStringArray) -> void:
	if paths.size() > 0:
		var already_loading: bool = (_files_to_load.size() > 0) or log_data.is_loading()
		for path in paths:
			_files_to_load.append(path)
		if not already_loading:
			var first_file = _files_to_load.pop_front()
			progress_dialog.set_label(LOADING_LABEL % first_file.get_file())
			progress_dialog.popup_centered()
			log_data.load_log_file(first_file)

func refresh_from_log_data() -> void:
	data_description_label.text = "%s logs (peer ids: %s) and %s ticks" % [log_data.peer_ids.size(), log_data.peer_ids, log_data.max_tick]
	if log_data.mismatches.size() > 0:
		data_description_label.text += " with %s mismatches" % log_data.mismatches.size()
	
	send_match_info_for_replay()
	state_input_viewer.refresh_from_log_data()
	frame_viewer.refresh_from_log_data()

func _on_log_data_load_error(msg) -> void:
	progress_dialog.hide()
	_files_to_load.clear()
	OS.alert(msg)

func _on_log_data_load_progress(current, total) -> void:
	progress_dialog.update_progress(current, total)

func _on_log_data_load_finished() -> void:
	if _files_to_load.size() > 0:
		var next_file = _files_to_load.pop_front()
		progress_dialog.set_label(LOADING_LABEL % next_file.get_file())
		log_data.load_log_file(next_file)
	else:
		progress_dialog.hide()

func _on_ModeButton_item_selected(index: int) -> void:
	state_input_viewer.visible = false
	frame_viewer.visible = false
	
	if index == DataMode.STATE_INPUT:
		state_input_viewer.visible = true
	elif index == DataMode.FRAME:
		frame_viewer.visible = true

func update_replay_server_status() -> void:
	match replay_server.get_status():
		ReplayServer.Status.NONE:
			replay_server_status_label.text = 'Disabled.'
		ReplayServer.Status.LISTENING:
			replay_server_status_label.text = 'Listening for connections...'
		ReplayServer.Status.CONNECTED:
			replay_server_status_label.text = 'Connected to game.'

func send_match_info_for_replay() -> void:
	if not replay_server or not replay_server.is_connected_to_game():
		return
	if not log_data or log_data.peer_ids.size() == 0:
		return
	
	var my_peer_id = log_data.peer_ids[0]
	var peer_ids = log_data.peer_ids.slice(1, log_data.peer_ids.size())

	var msg := {
		type = "setup_match",
		my_peer_id = my_peer_id,
		peer_ids = peer_ids,
		match_info = log_data.match_info,
	}
	replay_server.send_message(msg)

func _on_ReplayServer_started_listening() -> void:
	update_replay_server_status()

func _on_ReplayServer_game_connected() -> void:
	update_replay_server_status()
	send_match_info_for_replay()

func _on_ReplayServer_game_disconnected() -> void:
	update_replay_server_status()

func _on_LaunchGameButton_pressed() -> void:
	replay_server.launch_game()

func _on_DisconnectButton_pressed() -> void:
	replay_server.disconnect_from_game()
