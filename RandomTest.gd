extends Node2D

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	print (rng.seed)
	print (rng.state)
	print (rng.randi())
	print ("-------\n")
	
	var original_state = rng.state
	for i in range(0, 5):
		print (rng.randi())
	print ("\n")
	
	rng.state = original_state
	for i in range(0, 5):
		print (rng.randi())
	print ("\n")
	
