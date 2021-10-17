extends Node2D

onready var tank = $Tank

var start_transform: SGFixedTransform2D
var movement_vector: SGFixedVector2

func _ready() -> void:
	start_transform = SGFixedTransform2D.new()
	start_transform.x.x = -36943
	start_transform.x.y = -54132
	start_transform.y.x = 54312
	start_transform.y.y = -36943
	start_transform.origin.x = 5448767
	start_transform.origin.y = 5149583
	
	movement_vector = start_transform.x.copy()
	movement_vector.imul(SGFixed.ONE)
	movement_vector.imul(873726)
	
	reset_tank()

func reset_tank() -> void:
	tank.fixed_transform = start_transform
	tank.sync_to_physics_engine()

func move_tank() -> void:
	tank.move_and_slide(movement_vector)

func _on_Button_pressed() -> void:
	reset_tank()
	move_tank()
	print ("Position: (%s, %s)" % [tank.fixed_transform.origin.x, tank.fixed_transform.origin.y])
