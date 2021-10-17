extends "res://addons/gut/test.gd"

func test_deterministic_move_and_slide() -> void:
	var MoveAndSlide1 = load("res://test/unit/physics/SGKinematicBody2D/MoveAndSlide1.tscn")
	
	# Run the same scene 10 times and make sure we get the same result.
	for i in range(10):
		var scene = MoveAndSlide1.instance()
		add_child(scene)
		
		scene.do_move_and_slide(500)
		
		assert_eq(scene.body1.fixed_position.x, 16464848)
		assert_eq(scene.body1.fixed_position.y, 3703768)
		assert_eq(scene.body2.fixed_position.x, 21854071)
		assert_eq(scene.body2.fixed_position.y, 3212580)
		
		remove_child(scene)
		scene.queue_free()
