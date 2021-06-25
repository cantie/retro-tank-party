extends Area2D

var Explosion = preload("res://src/objects/Explosion.tscn")

onready var lifetime_timer = $LifetimeTimer

var tank
var player_id: int
var player_index: int
var vector := Vector2()

var damage := 10

func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	var _tank = data['tank']
	return {
		tank = _tank.get_path(),
		player_id = _tank.get_network_master(),
		player_index = _tank.player_index,
		position = _tank.bullet_start_position.global_position,
		rotation = _tank.turret_pivot.global_rotation,
		damage = data['weapon_type'].damage,
	}

func _network_spawn(data: Dictionary) -> void:
	tank = get_node(data['tank'])
	player_id = data['player_id']
	player_index = data['player_index']
	position = data['position']
	rotation = data['rotation']
	vector = Vector2.RIGHT.rotated(rotation)
	damage = data['damage']
	lifetime_timer.start()

func _network_process(_delta: float, _input: Dictionary) -> void:
	check_collision()

func _save_state() -> Dictionary:
	return {
		position = position,
		rotation = rotation,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']
	rotation = state['rotation']

func setup_bullet(_tank, weapon_type) -> void:
	# @todo Remove this method!
	pass

func explode(type: String):
	SyncManager.spawn("Explosion", get_parent(), Explosion, {
		position = global_position,
		scale = 0.5,
		type = type,
	})

func can_hit(body: PhysicsBody2D) -> bool:
	return body != tank

func check_collision() -> void:
	for body in get_overlapping_bodies():
		_on_bullet_collision(body)

func _on_bullet_collision(body: PhysicsBody2D) -> void:
	if not can_hit(body):
		return
	
	print ("spawning an explosion")
	
	if body.has_method("take_damage"):
		body.take_damage(damage, player_id, vector.normalized())
		explode("fire")
	else:
		explode("smoke")

func _on_LifetimeTimer_timeout() -> void:
	# Overriden by child classes (namely "res://src/objects/Bullet.gd")
	pass
