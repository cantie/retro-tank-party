extends Resource
class_name Pickup

@export_String) var name := ''
@export_String) var letter := 'P'
@export_int) var rarity := 20
@export_PackedScene) var pickup_scene

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
