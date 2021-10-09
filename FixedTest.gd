extends Node2D

func _ready() -> void:
	test_float_conversion()
	print ("-----")
	test_int_conversion()
	print ("-----")
	test_multiplication()
	print ("-----")
	test_division()
	print ("-----")
	
	test_fixed_vector2()
	
	get_tree().quit()

func test_float_conversion():
	var a: float = 2.4
	var b: int = SGFixed.from_float(a)
	var c: float = SGFixed.to_float(b)
	
	print ("a: %s" % a)
	print ("b: %s" % b)
	print ("c: %s" % c)

func test_int_conversion():
	var a: float = 2
	var b: int = SGFixed.from_int(a)
	var c: float = SGFixed.to_int(b)
	
	print ("a: %s" % a)
	print ("b: %s" % b)
	print ("c: %s" % c)

func test_multiplication():
	var a: int = SGFixed.from_float(2.5)
	var b: int = SGFixed.from_float(2.5)
	var c: int = SGFixed.mul(a, b)
	
	print ("[fixed] 2.5 * 2.5 = %s" % SGFixed.to_float(c))
	print ("[float] 2.5 * 2.5 = %s" % (2.5 * 2.5))

func test_division():
	var a: int = SGFixed.from_int(15)
	var b: int = SGFixed.from_int(2)
	var c: int = SGFixed.div(a, b)
	
	print ("[fixed] 15 / 2 = %s" % SGFixed.to_float(c))
	print ("[float] 15 / 2 = %s" % (15.0 / 2.0))

func test_fixed_vector2():
	var a := SGFixed.vector2(1024, 1024)
	var b := SGFixed.vector2(2048, 2048)
	var c: SGFixedVector2 = a.add(b);
	
	print ("(1, 1) + (2, 2) = %s" % c.to_float())
