extends "res://src/components/weapons/BaseBullet.gd"

onready var ray_cast := $RayCast2D
onready var line := $Line2D

var speed = 6116693
var growing := true
var bounced := false

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
	line.add_point(global_position)

func can_hit(body: SGCollisionObject2D) -> bool:
	# Only allow to hit ourselves after the first bounce.
	return bounced or body != tank

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['points'] = line.points
	state['growing'] = growing
	state['exceptions'] = ray_cast.get_exceptions()
	return state

func _load_state(state: Dictionary) -> void:
	line.points = state['points']
	growing = state['growing']
	ray_cast.set_exceptions(state['exceptions'])
	._load_state(state)

func _network_process(delta: float, input: Dictionary) -> void:
	._network_process(delta, input)
	if growing:
		var increment = vector.mulf(speed)
		ray_cast.cast_to = SGFixed.vector2(increment.length(), 0)
		ray_cast.update_raycast_collision()
		if ray_cast.is_colliding():
			set_global_fixed_position(ray_cast.get_collision_point())
			
			var collider = ray_cast.get_collider()
			# bit 2 = bullets
			if collider.get_collision_mask_bit(2):
				var collision_normal = ray_cast.get_collision_normal()
				if !(collision_normal.x == 0 and collision_normal.y == 0):
					vector = vector.bounce(collision_normal).normalized()
					fixed_rotation = vector.angle()
					bounced = true
			
			ray_cast.clear_exceptions()
			ray_cast.add_exception(collider)
		else:
			set_global_fixed_position(get_global_fixed_position().add(increment))
		
		sync_to_physics_engine()

		line.add_point(global_position)
	else:
		line.remove_point(0)
		if line.points.size() == 0:
			queue_free()

func _on_LifetimeTimer_timeout() -> void:
	growing = false

