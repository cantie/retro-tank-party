extends Node2D

onready var body1: SGKinematicBody2D = $KinematicBody1
onready var body2: SGKinematicBody2D = $KinematicBody2

#func _ready() -> void:
#	do_move_and_slide(500)

func do_move_and_slide(iterations: int) -> void:
	var body1_vector = body1.fixed_transform.x.copy()
	var body2_vector = body2.fixed_transform.y.copy()
	
	var amounts1 = [49152, 21627, SGFixed.ONE, SGFixed.HALF]
	var amounts2 = [SGFixed.ONE, SGFixed.HALF, 49152, 21627]
	
	for i in range(iterations):
		for x in range(4):
			body1.move_and_slide(body1_vector.mul(amounts1[x]))
			body2.move_and_slide(body2_vector.mul(amounts2[x]))

#func _process(delta: float) -> void:
#	do_move_and_slide(1)

