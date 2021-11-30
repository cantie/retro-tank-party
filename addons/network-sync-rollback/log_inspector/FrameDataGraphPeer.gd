extends Control

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")
const LogData = preload("res://addons/network-sync-rollback/log_inspector/LogData.gd")

export (int) var peer_id := 0 setget set_peer_id
export (int) var start_time := 0 setget set_start_time

var cursor_time := -1 setget set_cursor_time

const FRAME_TYPE_COLOR = {
	Logger.FrameType.INTERFRAME: Color(0.7, 0.7, 0.7),
	Logger.FrameType.TICK: Color(0.0, 0.0, 0.5),
	Logger.FrameType.INTERPOLATION_FRAME: Color(1.0, 1.0, 0.0),
}

var log_data: LogData

signal cursor_time_changed (cursor_time)

func set_log_data(_log_data: LogData) -> void:
	log_data = _log_data

func set_peer_id(_peer_id: int) -> void:
	if peer_id != _peer_id:
		peer_id = _peer_id
		update()

func set_start_time(_start_time: int) -> void:
	if start_time != _start_time:
		start_time = _start_time
		update()

func set_cursor_time(_cursor_time: int) -> void:
	if cursor_time != _cursor_time:
		cursor_time = _cursor_time
		update()
		emit_signal("cursor_time_changed", cursor_time)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			set_cursor_time(int(start_time + event.position.x))

func _draw() -> void:
	if peer_id == 0:
		return
	
	var absolute_start_time := log_data.start_time + start_time
	var absolute_end_time := absolute_start_time + rect_size.x
	var frame: LogData.FrameData = log_data.get_frame_by_time(peer_id, absolute_start_time)
	if frame == null and log_data.frames[peer_id].size() > 0:
		frame = log_data.frames[peer_id][0]
	var next_frame: LogData.FrameData
	
	while frame.start_time <= absolute_end_time:
		if frame.frame < log_data.frames[peer_id].size() - 1:
			next_frame = log_data.frames[peer_id][frame.frame + 1]
		else:
			next_frame = null
		
		var frame_rect = Rect2(
			Vector2(frame.start_time - absolute_start_time, 0),
			Vector2(next_frame.start_time - absolute_start_time if next_frame else rect_size.x, rect_size.y))
		frame_rect = frame_rect.clip(Rect2(Vector2.ZERO, rect_size))
		
		if frame_rect.position.x >= 0 and frame_rect.size.x > 0:
			draw_rect(frame_rect, FRAME_TYPE_COLOR[frame.type])
		
		# Move on to the next frame.
		if next_frame == null:
			break
		frame = next_frame
	
	if cursor_time >= start_time and cursor_time <= start_time + rect_size.x:
		draw_line(
			Vector2(cursor_time - start_time, 0),
			Vector2(cursor_time - start_time, rect_size.y),
			Color(1.0, 0.0, 0.0),
			3.0)
