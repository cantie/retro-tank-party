extends Node2D

onready var character = $Character
onready var area = $Area
onready var ray_cast = $Character/SGRayCast2D
onready var spot = $Spot

var rotation_speed = SGFixed.from_float(0.1)
var velocity = SGFixed.vector2(0, 0)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("player1_turn_left"):
		#character.fixed_rotation -= rotation_speed
		character.rotate_and_slide(-rotation_speed)
	elif Input.is_action_pressed("player1_turn_right"):
		#character.fixed_rotation += rotation_speed
		character.rotate_and_slide(rotation_speed)
	#character.sync_to_physics_engine()
	
	velocity.y = 0
	velocity.x = 0
	if Input.is_action_pressed("player1_forward"):
		velocity.x = SGFixed.ONE
	elif Input.is_action_pressed("player1_backward"):
		velocity.x = SGFixed.NEG_ONE
	
	if velocity.x != 0:
		velocity.imul(SGFixed.ONE*6)
		velocity.rotate(character.fixed_rotation)
		var collision = character.move_and_collide(velocity)
		if collision:
			print("COLLIDES!")
			print (collision.collider)
			print ("normal: %s" % collision.normal.to_float())
			print ("remainder: %s" % collision.remainder.to_float())
			print ("slide remainder: %s" % collision.remainder.slide(collision.normal).to_float())
			print ("slide remainedr (float): %s" % collision.remainder.to_float().slide(collision.normal.to_float()))
		#character.move_and_slide(velocity)
	
		ray_cast.update_raycast_collision()
		var overlapping_bodies = area.get_overlapping_bodies()
		
		if ray_cast.is_colliding() or (overlapping_bodies.size() > 0 && overlapping_bodies[0] == character):
			character.modulate = Color(1.0, 0.0, 0.0, 1.0)
		else:
			character.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		if ray_cast.is_colliding():
			spot.rect_position = ray_cast.get_collision_point().to_float() - Vector2(5, 5)
