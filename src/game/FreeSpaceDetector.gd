extends SGArea2D

var rng

func setup_free_space_detector(_rng) -> void:
	rng = _rng

func detect_free_space(area_top_left: SGFixedVector2, area_bottom_right: SGFixedVector2, dimensions: SGFixedVector2) -> SGFixedVector2:
	var area_dimensions = area_bottom_right.sub(area_top_left)
	var half_dimensions = dimensions.div(65536*2)
	
	var shape = SGRectangleShape2D.new()
	shape.extents = half_dimensions
	$CollisionShape2D.shape = shape
	
	while true:
		# @todo Figure out how to make randomness deterministic
		set_global_fixed_position(SGFixed.vector2(
			area_top_left.x + (rng.randi() % int(area_dimensions.x)),
			area_top_left.y + (rng.randi() % int(area_dimensions.y))))
		sync_to_physics_engine()
		if get_overlapping_bodies().size() == 0 and get_overlapping_areas().size() == 0:
			break
	
	return get_global_fixed_position()
