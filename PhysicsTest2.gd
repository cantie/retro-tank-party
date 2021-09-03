extends Node2D

onready var character = $Character
onready var area = $Area

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
		velocity.x = 65536
	elif Input.is_action_pressed("player1_backward"):
		velocity.x = -65536
	
	if velocity.x != 0:
		velocity.imulf(65536*6)
		velocity.rotate(character.fixed_rotation)
		#var collision = character.move_and_collide(velocity)
		#if collision:
		#	print("COLLIDES!")
		#	print (collision.collider)
		#	print ("normal: %s" % collision.normal.to_float())
		#	print ("remainder: %s" % collision.remainder.to_float())
		character.move_and_slide(velocity)
	#else:
	#	character.sync_to_physics_engine()
	
	#var overlapping_bodies = area.get_overlapping_bodies()
	#if overlapping_bodies.size() > 0 && overlapping_bodies[0] == character:
	#	character.modulate = Color(1.0, 0.0, 0.0, 1.0)
	#else:
	#	character.modulate = Color(1.0, 1.0, 1.0, 1.0)
