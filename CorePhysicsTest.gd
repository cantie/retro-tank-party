extends Node2D

onready var character = $Character

var rotation_speed := 0.1
var velocity: Vector2

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("player1_turn_left"):
		character.rotation -= rotation_speed
	elif Input.is_action_pressed("player1_turn_right"):
		character.rotation += rotation_speed
	
	velocity.y = 0
	velocity.x = 0
	if Input.is_action_pressed("player1_forward"):
		velocity.x = 1
	elif Input.is_action_pressed("player1_backward"):
		velocity.x = -1
	
	if velocity.x != 0:
		velocity *= 6
		velocity = velocity.rotated(character.rotation)
		#character.move_and_slide(velocity)
		var collision = character.move_and_collide(velocity)
		if collision:
			print("COLLIDES!")
			print (collision.collider)
			print ("normal: %s" % collision.normal)
			print ("remainder: %s" % collision.remainder)

