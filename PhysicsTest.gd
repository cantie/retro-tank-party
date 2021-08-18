extends Node2D

func _ready() -> void:
	#transform *= $Character.transform.affine_inverse()
	
	pass
	#var rect1 = SGPhysics2DServer.create_rectangle_shape(0, 0, 10, 10)
	#var rect2 = SGPhysics2DServer.create_rectangle_shape(20, 20, 5, 5)
	#var rect3 = SGPhysics2DServer.create_rectangle_shape(5, 5, 10, 10)
	
	#print ("rect1 collides with rect2: %s" % SGPhysics2DServer.shape_overlaps(rect1, rect2))
	#print ("rect1 collides with rect3: %s" % SGPhysics2DServer.shape_overlaps(rect1, rect3))
	
	#get_tree().quit()
	#update()

#func _draw() -> void:
#	var rect1_extents = $Character/SGCollisionShape2D.shape.get_extents().to_float()
#	draw_rect(Rect2(Vector2.ZERO, rect1_extents), Color(1.0, 1.0, 1.0, 1.0), true)
#
#	var rect2_extents = $Area/SGCollisionShape2D.shape.get_extents().to_float()
#	var rect2 = Rect2($Area/SGCollisionShape2D.global_position - rect2_extents, rect2_extents * 2.0)
#	#var transform2 = $Area/SGCollisionShape2D.global_transform * $Character/SGCollisionShape2D.global_transform.affine_inverse()
#	var transform2 = $Character/SGCollisionShape2D.global_transform.affine_inverse() * $Area/SGCollisionShape2D.global_transform
#	rect2 = transform2.xform(rect2)
#	draw_rect(rect2, Color(1.0, 1.0, 1.0, 1.0), true)
