extends SGArea2D

var vector := SGFixed.vector2(65536, 0)
var counter := 0

func _ready() -> void:
	fixed_position.from_float(position)

func _physics_process(delta: float) -> void:
	# Move 5 pixels per frame.
	fixed_position.iadd(vector.mulf(5*65536))
	
	#print ("%s, %s" % [fixed_position.x, fixed_position.y])
	sync_to_physics_engine()
	
	counter += 1
	if counter > 50:
		vector.x = -vector.x
		counter = 0
	
	var areas = get_overlapping_areas()
	if areas.size() > 0:
		modulate = Color(1.0, 0.0, 0.0)
	else:
		modulate = Color(1.0, 1.0, 1.0)
