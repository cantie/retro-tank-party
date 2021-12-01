tool
extends Reference

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")

class StateData:
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

class InputData:
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

class FrameData:
	var frame: int
	var type: int
	var data: Dictionary
	var start_time: int
	var end_time: int
	
	func _init(_frame: int, _type: int, _data: Dictionary) -> void:
		frame = _frame
		type = _type
		data = _data

var peer_ids := []
var mismatches := []
var max_tick := 0
var max_frame := 0
var frame_counter := {}
var start_time: int
var end_time: int

var input := {}
var state := {}
var frames := {}

signal load_error (msg)

func clear() -> void:
	peer_ids.clear()
	mismatches.clear()
	max_tick = 0
	max_frame = 0
	start_time = 0
	end_time = 0
	input.clear()
	state.clear()
	frames.clear()

func load_log_file(path: String) -> void:
	var file = File.new()
	var error = file.open(path, File.READ)
	if file.open(path, File.READ) != OK:
		emit_signal("load_error", "Unable to open file for reading: %s" % path)
		return
	
	var header
	var line_number := 0
	
	while not file.eof_reached():
		line_number += 1
		var line = file.get_line()
		
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
					emit_signal("load_error", "Log file has data for peer_id %s, which is already loaded" % header['peer_id'])
					file.close()
					return
				
				var peer_id = header['peer_id']
				peer_ids.append(peer_id)
				frame_counter[peer_id] = 0
				frames[peer_id] = []
				continue
			else:
				emit_signal("load_error", "No header at the top of log: %s" % path)
				file.close()
				return
		
		add_log_entry(json_result.result, header['peer_id'])
	
	file.close()

func add_log_entry(log_entry: Dictionary, peer_id: int) -> void:
	var tick: int = log_entry.get('tick', 0)
	
	max_tick = int(max(max_tick, tick))
	
	match log_entry['log_type'] as int:
		Logger.LogType.INPUT:
			var input_data: InputData
			if not input.has(tick):
				input_data = InputData.new(tick, log_entry['input'])
				input[tick] = input_data
			else:
				input_data = input[tick]
				if not input_data.compare_input(peer_id, log_entry['input']):
					mismatches.append(tick)
					print ("Input mismatch on tick: %s" % tick)
		
		Logger.LogType.STATE:
			var state_data: StateData
			if not state.has(tick):
				state_data = StateData.new(tick, log_entry['state'])
				state[tick] = state_data
			else:
				state_data = state[tick]
				if not state_data.compare_state(peer_id, log_entry['state']):
					mismatches.append(tick)
					print ("State mismatch on tick: %s" % tick)
		
		Logger.LogType.FRAME:
			log_entry.erase('log_type')
			var frame_number = frame_counter[peer_id]
			var frame_data := FrameData.new(frame_number, log_entry['frame_type'], log_entry)
			frames[peer_id].append(frame_data)
			frame_counter[peer_id] += 1
			max_frame = int(max(max_frame, frame_number))
			if log_entry.has('start_time'):
				frame_data.start_time = log_entry['start_time']
				start_time = int(min(start_time, frame_data.start_time)) if start_time > 0 else frame_data.start_time
			if log_entry.has('end_time'):
				frame_data.end_time = log_entry['end_time']
				end_time = int(max(end_time, frame_data.end_time))

func get_frame(peer_id: int, frame_number: int) -> FrameData:
	if not frames.has(peer_id):
		return null
	if frame_number >= frames[peer_id].size():
		return null
	return frames[peer_id][frame_number]

func get_frame_data(peer_id: int, frame_number: int, key: String, default_value = null):
	var frame := get_frame(peer_id, frame_number)
	if frame:
		return frame.data.get(key, default_value)
	return default_value

func get_frame_by_time(peer_id: int, time: int) -> FrameData:
	if not frames.has(peer_id):
		return null
	var peer_frames: Array = frames[peer_id]
	var last_matching_frame: FrameData
	for i in range(peer_frames.size()):
		var frame: FrameData = peer_frames[i]
		if frame.start_time != 0:
			if frame.start_time <= time:
				last_matching_frame = frame
			else:
				break
	return last_matching_frame
