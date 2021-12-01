tool
extends Control

const Logger = preload("res://addons/network-sync-rollback/Logger.gd")
const LogData = preload("res://addons/network-sync-rollback/log_inspector/LogData.gd")

export (int) var peer_id := 0 setget set_peer_id
export (int) var start_time := 0 setget set_start_time

var cursor_time := -1 setget set_cursor_time

const FRAME_TYPE_COLOR = {
	Logger.FrameType.INTERFRAME: Color(0.7, 0.7, 0.7),
	Logger.FrameType.TICK: Color(0.0, 0.75, 0.0),
	Logger.FrameType.INTERPOLATION_FRAME: Color(0.0, 0.0, 0.5),
}

var log_data: LogData
var _font: Font

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

func _ready() -> void:
	_font = DynamicFont.new()
	_font.font_data = load("res://addons/network-sync-rollback/log_inspector/monogram_extended.ttf")
	_font.size = 16

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
	if frame == null:
		return
	
	var tick_numbers_to_draw := []
	
	while frame.start_time <= absolute_end_time:
		var frame_rect = Rect2(
			Vector2(frame.start_time - absolute_start_time, 0),
			Vector2(frame.end_time - frame.start_time, rect_size.y))
		frame_rect = frame_rect.clip(Rect2(Vector2.ZERO, rect_size))
		if frame_rect.size.x == 0:
			frame_rect.size.x = 1
		if frame_rect.position.x >= 0:
			var skipped: bool = frame.data.get('skipped', false)
			var frame_color: Color
			
			if skipped:
				frame_color = Color(1.0, 1.0, 0.0)
				if frame_rect.size.x <= 1.0:
					frame_rect.size.x = 3
					frame_rect.position.x -= 1.5
			else:
				frame_color = FRAME_TYPE_COLOR[frame.type]
			
			draw_rect(frame_rect, frame_color)
			
			if frame.type == Logger.FrameType.TICK and frame.data.has('tick') and not skipped:
				tick_numbers_to_draw.append([frame_rect.position + (frame_rect.size / 2.0) - Vector2(3, 0), str(frame.data['tick'])])
				
		
		# Move on to the next frame.
		if frame.frame < log_data.frames[peer_id].size() - 1:
			frame = log_data.frames[peer_id][frame.frame + 1]
		else:
			break
	
	if cursor_time >= start_time and cursor_time <= start_time + rect_size.x:
		draw_line(
			Vector2(cursor_time - start_time, 0),
			Vector2(cursor_time - start_time, rect_size.y),
			Color(1.0, 0.0, 0.0),
			3.0)
	
	for tick_number_to_draw in tick_numbers_to_draw:
		draw_string(_font, tick_number_to_draw[0], tick_number_to_draw[1], Color(1.0, 1.0, 1.0))
