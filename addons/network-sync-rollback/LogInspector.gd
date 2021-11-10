extends Control

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")

const JSON_INDENT = "    "

onready var file_dialog = $FileDialog
onready var progress_dialog = $ProgressDialog
onready var data_description_label = $VBoxContainer/HBoxContainer/DataDescriptionLabel
onready var tick_number_field = $VBoxContainer/HBoxContainer2/TickNumber
onready var input_data_label = $VBoxContainer/GridContainer/InputPanel/InputDataLabel
onready var input_mismatches_data_label = $VBoxContainer/GridContainer/InputMismatchesPanel/InputMismatchesDataLabel
onready var state_data_label = $VBoxContainer/GridContainer/StatePanel/StateDataLabel
onready var state_mismatches_data_label = $VBoxContainer/GridContainer/StateMismatchesPanel/StateMismatchesDataLabel

class StateFrame:
	var tick: int
	var state: Dictionary
	var state_hash: int
	var mismatches := {}
	
	func _init(_tick: int, _state: Dictionary) -> void:
		tick = _tick
		state = _state
		state_hash = state.hash()
	
	func compare_state(peer_id: int, peer_state: Dictionary) -> bool:
		if state_hash == peer_state.hash():
			return true
		
		mismatches[peer_id] = peer_state
		return false

class InputFrame:
	var tick: int
	var input: Dictionary
	var input_hash: int
	var mismatches := {}
	
	func _init(_tick: int, _input: Dictionary) -> void:
		tick = _tick
		input = sort_dictionary(_input)
		input_hash = input.hash()
	
	static func sort_dictionary(d: Dictionary) -> Dictionary:
		var keys = d.keys()
		keys.sort()
		
		var ret := {}
		for key in keys:
			var val = d[key]
			if val is Dictionary:
				val = sort_dictionary(val)
			ret[key] = val
		
		return ret
	
	func compare_input(peer_id: int, peer_input: Dictionary) -> bool:
		var sorted_peer_input = sort_dictionary(peer_input)
		if sorted_peer_input.hash() == input_hash:
			return true
		
		mismatches[peer_id] = sorted_peer_input
		return false

var peer_ids := []
var mismatches := []
var max_tick := 0

var input := {}
var state := {}
var peer_ticks := {}

func _ready() -> void:
	var dir = Directory.new()
	file_dialog.current_dir = dir.get_current_dir()

func _on_AddLogButton_pressed() -> void:
	file_dialog.show_modal(true)
	file_dialog.invalidate()

func _on_FileDialog_files_selected(paths: PoolStringArray) -> void:
	for path in paths:
		load_log_file(path)
	
	data_description_label.text = "%s logs (peer ids: %s) and %s ticks" % [peer_ids.size(), peer_ids, max_tick]
	if mismatches.size() > 0:
		data_description_label.text += " with %s mismatches" % mismatches.size()
	
	tick_number_field.max_value = max_tick
	_on_TickNumber_value_changed(tick_number_field.value)

func load_log_file(path: String) -> void:
	var file = File.new()
	if file.open(path, File.READ) != OK:
		OS.alert("Unable to open file for reading: %s" % path)
		return
	
	progress_dialog.show_modal(true)
	progress_dialog.setup_progress(file.get_len())
	
	var header
	var line_number := 0
	
	while not file.eof_reached():
		line_number += 1
		var line = file.get_line()
		progress_dialog.update_progress(file.get_position())
		#yield(get_tree(), "idle_frame")
		
		if line == "\n":
			continue
		
		var json_result: JSONParseResult = JSON.parse(line)
		if json_result.error != OK:
			print ("Error parsing JSON in %s on line %s: %s" % [path, line_number, line])
			continue
		
		if header == null:
			if json_result.result['log_type'] == Logger.LogType.HEADER:
				header = json_result.result
				header['peer_id'] = int(header['peer_id'])
				if header['peer_id'] in peer_ids:
					OS.alert("Log file has data for peer_id %s, which is already loaded" % header['peer_id'])
					file.close()
					return
				
				peer_ids.append(header['peer_id'])
				continue
			else:
				OS.alert("No header at the top of log: %s" % path)
				file.close()
				return
		
		add_log_entry(json_result.result, header['peer_id'])
	
	file.close()
	progress_dialog.hide()

func add_log_entry(log_entry: Dictionary, peer_id: int) -> void:
	var tick: int = log_entry.get('tick', 0)
	
	max_tick = int(max(max_tick, tick))
	
	match log_entry['log_type'] as int:
		Logger.LogType.INPUT:
			var input_frame: InputFrame
			if not input.has(tick):
				input_frame = InputFrame.new(tick, log_entry['input'])
				input[tick] = input_frame
			else:
				input_frame = input[tick]
				if not input_frame.compare_input(peer_id, log_entry['input']):
					mismatches.append(tick)
					print ("Input mismatch on tick: %s" % tick)
		
		Logger.LogType.STATE:
			var state_frame: StateFrame
			if not state.has(tick):
				state_frame = StateFrame.new(tick, log_entry['state'])
				state[tick] = state_frame
			else:
				state_frame = state[tick]
				if not state_frame.compare_state(peer_id, log_entry['state']):
					mismatches.append(tick)
					print ("State mismatch on tick: %s" % tick)
		
		Logger.LogType.TICK:
			pass

func _on_TickNumber_value_changed(value: float) -> void:
	var tick: int = int(value)
	
	var input_frame = input.get(tick, null)
	var state_frame = state.get(tick, null)
	
	if input_frame:
		input_data_label.text = JSON.print(input_frame.input, JSON_INDENT)
	else:
		input_data_label.text = ''
	
	if state_frame:
		state_data_label.text = JSON.print(state_frame.state, JSON_INDENT)
	else:
		state_data_label.text = ''
