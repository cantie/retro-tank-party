extends "res://src/components/weapons/BaseBullet.gd"

onready var ray_cast := $RayCast2D
onready var line := $Line2D

var speed = 6116693
var growing := true
var bounced := false

var fixed_points := []

const LASER_COLORS := {
	1: Color("419fdd"),
	2: Color("2ecc71"),
	3: Color("e74c3c"),
	4: Color("5f5d55"),
}

func _ready():
	line.set_as_toplevel(true)
	line.global_position = Vector2(0, 0)

func _network_spawn(data: Dictionary) -> void:
	._network_spawn(data)
	line.default_color = LASER_COLORS[player_index]
	
	var global_fixed_position = get_global_fixed_position()
	fixed_points.append(global_fixed_position)
	line.add_point(global_fixed_position.to_float())

func can_hit(body: SGCollisionObject2D) -> bool:
	# Only allow to hit ourselves after the first bounce.
	return bounced or body != tank

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['growing'] = growing
	state['bounced'] = bounced
	state['points'] = fixed_points.duplicate()
	
	var exceptions := []
	for node in ray_cast.get_exceptions():
		if not node.is_inside_tree():
			continue
		var node_path = str(node.get_path())
		exceptions.append(node_path)
	state['exceptions'] = exceptions
	
	return state

func _load_state(state: Dictionary) -> void:
	growing = state['growing']
	bounced = state['bounced']
	
	line.clear_points()
	for fixed_point in state['points']:
		line.add_point(fixed_point.to_float())
	fixed_points = state['points'].duplicate()
	
	ray_cast.clear_exceptions()
	for node_path in state['exceptions']:
		var node = get_node(node_path)
		if node:
			ray_cast.add_exception(node)
	
	._load_state(state)

func _network_process(delta: float, input: Dictionary) -> void:
	._network_process(delta, input)
	if growing:
		var increment = vector.mul(speed)
		ray_cast.update_raycast_collision()
		if ray_cast.is_colliding():
			set_global_fixed_position(ray_cast.get_collision_point())
			#print ("[%s] collision point: (%s, %s)" % [SyncManager.current_tick, fixed_position.x, fixed_position.y])
			
			var collider = ray_cast.get_collider()
			# bit 2 = bullets
			if collider.get_collision_mask_bit(2):
				var collision_normal = ray_cast.get_collision_normal()
				#print ("[%s] collision normal: (%s, %s)" % [SyncManager.current_tick, collision_normal.x, collision_normal.y])
				if !(collision_normal.x == 0 and collision_normal.y == 0):
					vector = vector.bounce(collision_normal).normalized()
					#print ("[%s] vector: (%s, %s)" % [SyncManager.current_tick, vector.x, vector.y])
					fixed_rotation = vector.angle()
					#print ("[%s] angle: %s" % [SyncManager.current_tick, fixed_rotation])
					bounced = true
			
			ray_cast.clear_exceptions()
			ray_cast.add_exception(collider)
		else:
			set_global_fixed_position(get_global_fixed_position().add(increment))
		
		sync_to_physics_engine()
		
		var global_fixed_position = get_global_fixed_position()
		fixed_points.append(global_fixed_position)
		line.add_point(global_fixed_position.to_float())
	else:
		fixed_points.pop_front()
		line.remove_point(0)
		if fixed_points.size() == 0:
			queue_free()

func _on_LifetimeTimer_timeout() -> void:
	growing = false

