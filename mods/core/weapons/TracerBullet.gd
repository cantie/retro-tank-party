extends "res://src/objects/Bullet.gd"

var target_seek_speed := 21845

var target: Node2D = null

func _network_spawn_preprocess(info: Dictionary) -> Dictionary:
	var res := ._network_spawn_preprocess(info)
	res['target'] = info['target'].get_path() if info['target'] != null else null
	return res

func _network_spawn(info: Dictionary) -> void:
	._network_spawn(info)
	target = get_node(info['target']) if info['target'] != null else null

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['target'] = target.get_path() if target else null
	return state

func _load_state(state: Dictionary) -> void:
	._load_state(state)
	target = get_node(state['target']) if state['target'] != null else null

func _network_process(delta: float, input: Dictionary) -> void:
	._network_process(delta, input)
	if target and is_instance_valid(target):
		var target_vector = target.get_global_fixed_position().sub(get_global_fixed_position()).normalized()
		vector = vector.linear_interpolate(target_vector, target_seek_speed).normalized()
		fixed_rotation = vector.angle()

