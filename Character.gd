extends SGArea2D

var vector := SGFixed.vector2(1024, 0)
var counter := 0

func _ready() -> void:
	fixed_position.from_float(position)

func _physics_process(delta: float) -> void:
	#position += vector * 400.0 * delta
	fixed_position.iadd(vector.mulf(5))
	#sync_to_physics()
	print ("%s, %s" % [fixed_position.x, fixed_position.y])
	
	counter += 1
	if counter > 50:
		vector.x = -vector.x
		counter = 0
		
	#if overlaps_area():
	#	modulate = Color(1.0, 1.0, 1.0)
