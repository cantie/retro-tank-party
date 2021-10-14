extends Node2D

func _ready() -> void:
	for i in range(0, 30):
		print(simple_hash(i))
	
	var d1 = {
		a = 1,
		b = 2,
	}
	
	var d2 = {
		a = 1,
		b = {
			x = 1,
			y = 2,
		}
	}
	
	var d2a = {
		a = 1,
		b = {
			x = 1,
			y = 2,
		}
	}
	
	var d3 = {
		a = 1,
		b = {
			x = 2,
			y = 2,
		}
	}
	
	print ("d1.hash() = %s" % d1.hash())
	print ("d2.hash() = %s" % d2.hash());
	print ("d2a.hash() = %s" % d2a.hash());
	print ("d3.hash() = %s" % d3.hash());

# From https://stackoverflow.com/a/12996028/364763
#
# License: CC BY-SA 4.0
# Author: Thomas Mueller
func simple_hash(x: int):
	x = ((x >> 16) ^ x) * 0x45d9f3b;
	x = ((x >> 16) ^ x) * 0x45d9f3b;
	x = (x >> 16) ^ x;
	return x
