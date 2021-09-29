extends Node2D

onready var character = $Character

var vector := SGFixed.vector2(65536, 0)
var counter := 0

func _physics_process(delta: float) -> void:
	# Move 5 pixels per frame.
	character.fixed_position.iadd(vector.mul(5*65536))
	
	#print ("%s, %s" % [fixed_position.x, fixed_position.y])
	character.sync_to_physics_engine()
	
	counter += 1
	if counter > 50:
		vector.x = -vector.x
		counter = 0
	
	var areas = character.get_overlapping_areas()
	if areas.size() > 0:
		character.modulate = Color(1.0, 0.0, 0.0)
	else:
		character.modulate = Color(1.0, 1.0, 1.0)
