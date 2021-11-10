extends Control

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")

onready var file_dialog = $FileDialog
onready var progress_dialog = $ProgressDialog

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

var state := {}
var input := {}

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

func load_log_file(path: String) -> void:
	var file = File.new()
	if file.open(path, File.READ) != OK:
		OS.alert("Unable to open file for reading: %s" % path)
		return
	
	progress_dialog.show_modal(true)
	progress_dialog.setup_progress(file.get_len())
	
	var header
	
	while not file.eof_reached():
		var line = file.get_line()
		progress_dialog.update_progress(file.get_position())
		#yield(get_tree(), "idle_frame")
		
		var json_result: JSONParseResult = JSON.parse(line)
		if json_result.error != OK:
			print ("Error parsing JSON: %s" % line)
			continue
		
		if header == null:
			if json_result.result['log_type'] == Logger.LogType.HEADER:
				header = json_result.result
			else:
				OS.alert("No header at the top of log: %s" % path)
				file.close()
				return
		
		add_log_entry(json_result.result, header['peer_id'])
	
	file.close()
	progress_dialog.hide()

func add_log_entry(log_entry: Dictionary, peer_id: int) -> void:
	match log_entry['log_type']:
		Logger.LogType.INPUT:
			var tick = log_entry['tick']
			var input_frame: InputFrame
			if not input.has(tick):
				input_frame = InputFrame.new(tick, log_entry['input'])
				input[tick] = input_frame
			else:
				input_frame = input[tick]
				if not input_frame.compare_input(peer_id, log_entry['input']):
					print ("Input mismatch on tick: %s" % tick)
		
		Logger.LogType.STATE:
			pass
		
		Logger.LogType.TICK:
			pass
	
