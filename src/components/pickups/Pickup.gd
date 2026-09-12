extends Resource
class_name Pickup

@export var name: String = ''
@export var letter: String = 'P'
@export var rarity: int = 20
@export var pickup_scene: PackedScene

func get_default_pickup_scene() -> PackedScene:
	return preload("res://src/objects/pickups/Pickup.tscn")

func get_pickup_machine_name() -> String:
	var fn = resource_path.get_basename()
	var parts = fn.split('/')
	return parts[parts.size() - 1]

func get_pickup_scene() -> PackedScene:
	if pickup_scene == null:
		return get_default_pickup_scene()
	return pickup_scene

# This needs to be overridden by the child resource class.
func pickup(tank) -> void:
	pass
