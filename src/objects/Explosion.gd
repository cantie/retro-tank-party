extends Node2D

onready var animation_player = $AnimationPlayer
onready var sounds = $Sounds

var animation_finished := false
var sound_finished := false

func _network_spawn(data: Dictionary) -> void:
	position = data['position']
	scale = Vector2(data['scale'], data['scale'])
	
	var anim = data['type']
	animation_player.play(anim)
	
	# @todo Can we do something like this with rollback?
	#yield(get_tree().create_timer(randf() * 0.150), "timeout")
	
	if anim == 'smoke':
		sounds.play('Miss')
	else:
		if data['scale'] > 1.0:
			sounds.play('Big')
		else:
			sounds.play('Hit')

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	visible = false
	animation_finished = true
	#if sound_finished:
	queue_free()

#func _on_Sounds_finished() -> void:
#	sound_finished = true
#	if animation_finished:
#		queue_free()

