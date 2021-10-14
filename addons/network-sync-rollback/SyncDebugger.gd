extends Node

const DebugOverlay = preload("res://addons/network-sync-rollback/debugger/DebugOverlay.tscn")

class DebugStatePrinter:
	const JSON_INDENT = "    "
	
	static func print_state_diff(local_state: Dictionary, remote_state: Dictionary) -> void:
		_print_state_diff_recursive(local_state, remote_state)
	
	static func _print_state_diff_recursive(local_state: Dictionary, remote_state: Dictionary, path: Array = []) -> void:
		for key in local_state:
			if not remote_state.has(key):
				print (" => [MISSING] %s" % _get_diff_path_string(path, key))
				print (JSON.print(local_state[key], JSON_INDENT))
				print ()
		
		for key in remote_state:
			if not local_state.has(key):
				print (" => [EXTRA] %s" % _get_diff_path_string(path, key))
				print (JSON.print(remote_state[key], JSON_INDENT))
				print ()
		
		for key in local_state:
			var local_value = local_state[key]
			
			if not remote_state.has(key):
				continue
			var remote_value = remote_state[key]
			
			if local_value is Dictionary:
				if remote_value is Dictionary:
					if local_value.hash() != remote_value.hash():
						_print_state_diff_recursive(local_value, remote_value, _extend_diff_path(path, key))
				else:
					_print_diff_value(local_value, remote_value, path, key)
			elif local_value is Array:
				if remote_value is Array:
					if local_value != remote_value:
						_print_state_diff_recursive(_convert_array_to_dictionary(local_value), _convert_array_to_dictionary(remote_value), _extend_diff_path(path, key))
				else:
					_print_diff_value(local_value, remote_value, path, key)
			elif local_value != remote_value:
				_print_diff_value(local_value, remote_value, path, key)

	static func _get_diff_path_string(path: Array, key) -> String:
		if path.size() > 0:
			return PoolStringArray(path).join(" -> ") + " -> " + str(key)
		return str(key)

	static func _extend_diff_path(path: Array, key) -> Array:
		var new_path = path.duplicate()
		new_path.append(str(key))
		return new_path

	static func _print_diff_value(local_value, remote_value, path: Array, key) -> void:
		print (" => [DIFF] %s" % _get_diff_path_string(path, key))
		print ("LOCAL: %s" % JSON.print(local_value, JSON_INDENT))
		print ("REMOTE: %s" % JSON.print(remote_value, JSON_INDENT))
		print ()
	
	static func _convert_array_to_dictionary(a: Array) -> Dictionary:
		var d := {}
		for i in range(a.size()):
			d[i] = a[i]
		return d

var _canvas_layer
var _debug_overlay
var _debug_pressed: bool = false

func _ready() -> void:
	SyncManager.connect("rollback_flagged", self, "_on_SyncManager_rollback_flagged")
	SyncManager.connect("skip_ticks_flagged", self, "_on_SyncManager_skip_ticks_flagged")
	SyncManager.connect("remote_state_mismatch", self, "_on_SyncManager_remote_state_mismatch")
	SyncManager.connect("peer_pinged_back", self, "_on_SyncManager_peer_pinged_back")
	SyncManager.connect("state_loaded", self, "_on_SyncManager_state_loaded")
	SyncManager.connect("tick_finished", self, "_on_SyncManager_tick_finished")

func create_debug_overlay(overlay_instance = null) -> void:
	if _debug_overlay != null:
		_debug_overlay.queue_free()
		_canvas_layer.remove_child(_debug_overlay)
	
	if overlay_instance == null:
		overlay_instance = DebugOverlay.instance()
	if _canvas_layer == null:
		_canvas_layer = CanvasLayer.new()
		add_child(_canvas_layer)
	
	_debug_overlay = overlay_instance
	_canvas_layer.add_child(_debug_overlay)

func show_debug_overlay(_visible: bool = true) -> void:
	if _visible and not _debug_overlay:
		create_debug_overlay()
	if _debug_overlay:
		_debug_overlay.visible = _visible

func hide_debug_overlay() -> void:
	if _debug_overlay:
		show_debug_overlay(false)

func is_debug_overlay_shown() -> bool:
	if _debug_overlay:
		return _debug_overlay.visible
	return false

func _on_SyncManager_skip_ticks_flagged(count: int) -> void:
	print ("-----")
	print ("Skipping %s local tick(s) to adjust for peer advantage" % count)

func _on_SyncManager_rollback_flagged(tick: int, peer_id: int, local_input: Dictionary, remote_input: Dictionary) -> void:
	print ("-----")
	print ("Correcting prediction on tick %s for peer %s (rollback %s tick(s))" % [tick, peer_id, SyncManager.rollback_ticks])
	print ("Received input: %s" % remote_input)
	print ("Predicted input: %s" % local_input)
	
	if _debug_overlay:
		_debug_overlay.add_message(peer_id, "%s: Rollback %s ticks" % [tick, SyncManager.rollback_ticks])

func _on_SyncManager_remote_state_mismatch(tick: int, peer_id: int, local_state: Dictionary, remote_state: Dictionary) -> void:
	print ("-----")
	print ("On tick %s, remote state from %s doesn't match local state:\n" % [tick, peer_id])
	DebugStatePrinter.print_state_diff(local_state, remote_state)
	
	if _debug_overlay:
		_debug_overlay.add_message(peer_id, "%s: State mismatch" % tick)

func _on_SyncManager_peer_pinged_back(peer: SyncManager.Peer) -> void:
	print ("-----")
	print ("Peer %s: RTT %s ms | local lag %s | remote lag %s | advantage %s" % [peer.peer_id, peer.rtt, peer.local_lag, peer.remote_lag, peer.calculated_advantage])
	if _debug_overlay:
		_debug_overlay.update_peer(peer)

func _on_SyncManager_state_loaded(rollback_ticks: int) -> void:
	pass

func _on_SyncManager_tick_finished(is_rollback: bool) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	var action_pressed = event.is_action_pressed("sync_debug")
	if action_pressed:
		if not _debug_pressed:
			_debug_pressed = true
			show_debug_overlay(not is_debug_overlay_shown())
	else:
		_debug_pressed = false
