extends Node

var default_bus = "Master"

var _sounds := {}

func play_sound(identifier: String, sound: AudioStream, volume_db: float = 0.0, bus: String = "", pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if _sounds.has(identifier):
		return _sounds[identifier]
	
	var node = AudioStreamPlayer.new()
	node.stream = sound
	node.volume_db = volume_db
	node.pitch_scale = pitch_scale
	node.bus = bus if bus != "" else default_bus
	
	add_child(node)
	node.play()
	
	node.connect("finished", self, "_on_audio_finished", [identifier])
	
	_sounds[identifier] = node
	return node

func _on_audio_finished(identifier: String) -> void:
	if _sounds.has(identifier):
		var node = _sounds[identifier]
		remove_child(node)
		node.queue_free()
		_sounds.erase(identifier)
