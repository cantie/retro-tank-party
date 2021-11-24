tool
extends VBoxContainer

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")
const LogData = preload("res://addons/network-sync-rollback/log_inspector/LogData.gd")

onready var time_field = $HBoxContainer/Time
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
	time_field.max_value = log_data.end_time - log_data.start_time
	_on_Time_value_changed(time_field.value)

func _on_Time_value_changed(value: float) -> void:
	var time := int(value)
	
	var bbcode = '[table=%s][cell][/cell]' % [log_data.peer_ids.size() + 1]
	for peer_id in log_data.peer_ids:
		bbcode += '[cell]%s[/cell]' % peer_id
	
	var cols := {}
	for peer_id in log_data.peer_ids:
		var frame = log_data.get_frame_by_time(peer_id, log_data.start_time + time)
		if not frame:
			continue
		
		var row := {}
		row['Frame Type'] = frame_type_names.get(int(frame.data.get('frame_type', 0)), 'UNKNOWN')
		row['Tick'] = frame.data.get('tick', 0)
		row['Duration'] = frame.data.get('duration', 0)
		row['Skipped'] = frame.data.get('skipped', false)
		row['Skipped Reason'] = frame.data.get('skipped_reason', '')
		cols[peer_id] = row
	
	var v = [
		'Frame Type',
		'Tick',
		'Duration',
		'Skipped',
		'Skipped Reason'
	]
	for k in v:
		bbcode += '[cell]%s[/cell]' % k
		for peer_id in log_data.peer_ids:
			if cols.has(peer_id):
				bbcode += '[cell]%s[/cell]' % cols[peer_id][k]
			else:
				bbcode += '[cell][/cell]'
	
	bbcode += '[/table]'
	data_grid.bbcode_text = bbcode
	
