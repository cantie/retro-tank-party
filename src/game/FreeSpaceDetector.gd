extends SGArea2D

var area_position
var area_size
var rng

func setup_free_space_detector(_area_position: SGFixedVector2, _area_size: SGFixedVector2, dimensions: SGFixedVector2, _rng) -> void:
	area_position = _area_position
	area_size = _area_size
	rng = _rng
	
	var half_dimensions = dimensions.div(65536*2)
	var shape = SGRectangleShape2D.new()
	shape.extents = half_dimensions
	$CollisionShape2D.shape = shape

func detect_free_space() -> SGFixedVector2:
	while true:
		# @todo Should we round this to even pixel values?
		set_global_fixed_position(SGFixed.vector2(
			area_position.x + (rng.randi() % int(area_size.x)),
			area_position.y + (rng.randi() % int(area_size.y))))
		sync_to_physics_engine()
		if get_overlapping_bodies().size() == 0 and get_overlapping_areas().size() == 0:
			break
	
	return get_global_fixed_position()
