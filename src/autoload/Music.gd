extends Node

var current_song: AudioStreamPlayer
var initial_volume_dbs := {}

func _ready() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			initial_volume_dbs[child.name] = child.volume_db

func play(song_name: String) -> void:
	var next_song = get_node_or_null(song_name)
	if !next_song or (next_song is AudioStreamPlayer and next_song.playing):
		return
	
	if current_song:
		next_song.volume_db = -40.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(current_song, "volume_db", -40.0, 1.0).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(next_song, "volume_db", initial_volume_dbs.get(next_song.name, 0.0), 1.0).set_trans(Tween.TRANS_LINEAR)
		var old_song = current_song
		tween.finished.connect(func(): _on_tween_finished(old_song))
	
	next_song.play()
	current_song = next_song

func _on_tween_finished(old_song: AudioStreamPlayer) -> void:
	if old_song != current_song:
		old_song.stop()
