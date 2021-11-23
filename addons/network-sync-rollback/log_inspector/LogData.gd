extends Node

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")

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

signal load_error (msg)

func clear() -> void:
	peer_ids.clear()
	mismatches.clear()
	max_tick = 0
	input.clear()
	state.clear()
	peer_ticks.clear()

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
				
				peer_ids.append(header['peer_id'])
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
		
		Logger.LogType.FRAME:
			pass
