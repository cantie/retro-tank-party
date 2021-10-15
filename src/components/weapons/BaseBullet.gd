extends SGArea2D

var Explosion = preload("res://src/objects/Explosion.tscn")

onready var lifetime_timer = $LifetimeTimer

var tank
var player_id: int
var player_index: int
var vector := SGFixed.vector2(0, 0)

var damage := 10

func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	var _tank = data['tank']
	return {
		tank = _tank.get_path(),
		player_id = _tank.get_network_master(),
		player_index = _tank.player_index,
		fixed_transform = _tank.bullet_start_position.get_global_fixed_transform().copy(),
		damage = data['weapon_type'].damage,
	}

func _network_spawn(data: Dictionary) -> void:
	tank = get_node(data['tank'])
	player_id = data['player_id']
	player_index = data['player_index']
	set_global_fixed_transform(data['fixed_transform'])
	vector = fixed_transform.x.copy()
	damage = data['damage']
	lifetime_timer.start()
	sync_to_physics_engine()

func _network_process(_delta: float, _input: Dictionary) -> void:
	check_collision()

func _save_state() -> Dictionary:
	return {
		fixed_transform = fixed_transform.copy(),
		vector = vector.copy(),
	}

func _load_state(state: Dictionary) -> void:
	fixed_transform = state['fixed_transform'].copy()
	vector = state['vector'].copy()
	sync_to_physics_engine()

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	position = lerp(old_state['fixed_transform'].get_origin().to_float(), new_state['fixed_transform'].get_origin().to_float(), weight)
	rotation = lerp_angle(SGFixed.to_float(old_state['fixed_transform'].get_rotation()), SGFixed.to_float(new_state['fixed_transform'].get_rotation()), weight)

func explode(type: String):
	if is_queued_for_deletion():
		return
	
	SyncManager.spawn("Explosion", get_parent(), Explosion, {
		position = global_position,
		scale = 0.5,
		type = type,
	})

func can_hit(body: SGCollisionObject2D) -> bool:
	return body != tank

func check_collision() -> void:
	for body in get_overlapping_bodies():
		_on_bullet_collision(body)

func _on_bullet_collision(body: SGCollisionObject2D) -> void:
	if not can_hit(body):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage, player_id, vector.normalized())
		explode("fire")
	else:
		explode("smoke")

func _on_LifetimeTimer_timeout() -> void:
	# Overriden by child classes (namely "res://src/objects/Bullet.gd")
	pass
