extends Node2D

func _ready() -> void:
	for i in range(0, 30):
		print(simple_hash(i))

# From https://stackoverflow.com/a/12996028/364763
#
# License: CC BY-SA 4.0
# Author: Thomas Mueller
func simple_hash(x: int):
	x = ((x >> 16) ^ x) * 0x45d9f3b;
	x = ((x >> 16) ^ x) * 0x45d9f3b;
	x = (x >> 16) ^ x;
	return x
