extends Node2D

onready var animation_player = $AnimationPlayer
onready var sounds = $Sounds

const MissSound = preload("res://assets/sounds/Snare__001.wav")
const HitSound = preload("res://assets/sounds/Explosion3__004.wav")
const BigSound = preload("res://assets/sounds/Explosion2__007.wav")

var sound_played := false
var data

func _save_state() -> Dictionary:
	return {
		sound_played = sound_played,
	}

func _load_state(state: Dictionary) -> void:
	sound_played = state['sound_played']

func _network_spawn(_data: Dictionary) -> void:
	data = _data
	position = data['position']
	scale = Vector2(data['scale'], data['scale'])
	
	var anim = data['type']
	animation_player.play(anim)
	
	# @todo Can we do something like this with rollback?
	#yield(get_tree().create_timer(randf() * 0.150), "timeout")

func _network_process(delta: float, input: Dictionary) -> void:
	if not sound_played:
		var anim = data['type']
		
		var sound_id = SyncManager.make_identifier(self, "Sound")
		
		if anim == 'smoke':
			SyncManager.play_sound(sound_id, MissSound)
			#sounds.play('Miss')
		else:
			if data['scale'] > 1.0:
				SyncManager.play_sound(sound_id, BigSound)
				#sounds.play('Big')
			else:
				SyncManager.play_sound(sound_id, HitSound)
			#sounds.play('Hit')
		sound_played = true

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	visible = false
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()
