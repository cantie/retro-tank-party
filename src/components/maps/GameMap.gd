extends Resource
class_name GameMap

@export var name: String
@export var has_goals := false
@export_file("*.tscn") var map_scene: String

func instance_map_scene():
	var packed_scene = load(map_scene)
	if packed_scene == null or not packed_scene is PackedScene:
		return null
	return packed_scene.instantiate()
