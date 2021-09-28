extends "res://src/objects/Bullet.gd"

var target_seek_speed := 21845

var target: Node2D = null

func _network_process(delta: float, input: Dictionary) -> void:
	._network_process(delta, input)
	if target and is_instance_valid(target):
		var target_vector = target.get_global_fixed_position().sub(get_global_fixed_position()).normalized()
		vector = vector.linear_interpolate(target_vector, target_seek_speed).normalized()
		fixed_rotation = vector.angle()

