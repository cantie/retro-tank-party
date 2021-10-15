extends SGFixedNode2D

onready var animation_player := $AnimationPlayer

func _network_spawn(data: Dictionary) -> void:
	fixed_position = data['fixed_position']

func _on_Timer_timeout() -> void:
	animation_player.play('Dissolve')

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == 'Dissolve':
		queue_free()
