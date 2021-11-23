tool
extends Control

const LogData = preload("res://addons/network-sync-rollback/log_inspector/LogData.gd")

onready var file_dialog = $FileDialog
onready var progress_dialog = $ProgressDialog
onready var data_description_label = $MarginContainer/VBoxContainer/HBoxContainer/DataDescriptionLabel
onready var data_description_label_default_text = data_description_label.text
onready var mode_button = $MarginContainer/VBoxContainer/HBoxContainer/ModeButton
onready var state_input_viewer = $MarginContainer/VBoxContainer/StateInputViewer

enum DataMode {
	STATE_INPUT,
	FRAME,
}

var log_data: LogData = LogData.new()

func _ready() -> void:
	state_input_viewer.set_log_data(log_data)
	
	log_data.connect("load_error", self, "_on_log_data_load_error")
	
	if mode_button.items.size() == 0:
		mode_button.add_item("State/Input", DataMode.STATE_INPUT)
		mode_button.add_item("Frame", DataMode.FRAME)
		mode_button.selected = DataMode.STATE_INPUT
	
	# Show and make full screen if the scene is being run on its own.
	if get_parent() == get_tree().root:
		visible = true
		anchor_right = 1
		anchor_bottom = 1
		margin_right = 0
		margin_bottom = 0

func _on_ClearButton_pressed() -> void:
	log_data.clear()
	data_description_label.text = data_description_label_default_text
	state_input_viewer.refresh_from_log_data()

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
	for path in paths:
		log_data.load_log_file(path)
	
	data_description_label.text = "%s logs (peer ids: %s) and %s ticks" % [log_data.peer_ids.size(), log_data.peer_ids, log_data.max_tick]
	if log_data.mismatches.size() > 0:
		data_description_label.text += " with %s mismatches" % log_data.mismatches.size()
	
	state_input_viewer.refresh_from_log_data()

func _on_log_data_load_error(msg) -> void:
	OS.alert(msg)
