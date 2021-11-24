tool
extends VBoxContainer

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")
const LogData = preload("res://addons/network-sync-rollback/log_inspector/LogData.gd")

onready var frame_number_field = $HBoxContainer/FrameNumber
onready var data_grid = $DataGrid

var log_data: LogData

var frame_type_names: Dictionary

func _ready() -> void:
	frame_type_names = _flip_dictionary(Logger.FrameType)

static func _flip_dictionary(d: Dictionary) -> Dictionary:
	var r := {}
	for k in d:
		r[d[k]] = k
	return r

func set_log_data(_log_data: LogData) -> void:
	log_data = _log_data

func refresh_from_log_data() -> void:
	frame_number_field.max_value = log_data.max_frame
	_on_FrameNumber_value_changed(frame_number_field.value)

func _on_FrameNumber_value_changed(value: float) -> void:
	var frame_number := int(value)
	
	var bbcode = '[table=%s][cell][/cell]' % [log_data.peer_ids.size() + 1]
	for peer_id in log_data.peer_ids:
		bbcode += '[cell]%s[/cell]' % peer_id
	
	bbcode += '[cell]Frame Type[/cell]'
	for peer_id in log_data.peer_ids:
		var frame_type = log_data.get_frame_data(peer_id, frame_number, 'frame_type', Logger.FrameType.INTERFRAME)
		bbcode += '[cell]%s[/cell]' % frame_type_names.get(int(frame_type), 'UNKNOWN')
	
	bbcode += '[/table]'
	data_grid.bbcode_text = bbcode
	
