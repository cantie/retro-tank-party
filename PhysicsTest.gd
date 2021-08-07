extends Node2D

func _ready() -> void:
	var rect1 = SGPhysics2DServer.create_rectangle_shape(0, 0, 10, 10)
	var rect2 = SGPhysics2DServer.create_rectangle_shape(20, 20, 5, 5)
	var rect3 = SGPhysics2DServer.create_rectangle_shape(5, 5, 10, 10)
	
	#print ("rect1 collides with rect2: %s" % SGPhysics2DServer.shape_overlaps(rect1, rect2))
	#print ("rect1 collides with rect3: %s" % SGPhysics2DServer.shape_overlaps(rect1, rect3))
	
	#get_tree().quit()
