extends SGArea2D

const DropCrate = preload("res://src/objects/DropCrate.tscn")

# 3932160 = 60
var crate_size = SGFixed.vector2(3932160, 3932160)

onready var collision_shape = $CollisionShape2D
onready var drop_timer = $DropTimer
onready var spawns = $Spawns

var possible_contents := []
var detector

func map_object_start(map, game):
	if is_network_master():
		possible_contents = game.possible_pickups
		detector = game.create_free_space_detector()
		drop_timer.start()

func map_object_stop(map, game):
	drop_timer.stop()
	if detector:
		detector.queue_free()
	clear()

func has_drop_crate_or_powerup() -> bool:
	return spawns.has_node("DropCrate") or spawns.has_node("Powerup")

func spawn_drop_crate() -> void:
	if not is_network_master():
		return
	if not has_drop_crate_or_powerup():
		var extents = collision_shape.shape.extents
		var fixed_global_position = get_global_fixed_position()
		var area_top_left = fixed_global_position.sub(extents)
		var area_bottom_right = fixed_global_position.add(extents)
		
		var crate_position = detector.detect_free_space(area_top_left, area_bottom_right, crate_size)
		var contents = possible_contents[randi() % possible_contents.size()]
		_do_spawn_drop_crate(crate_position, contents.resource_path)

func _on_DropTimer_timeout() -> void:
	spawn_drop_crate()

func _on_free_space_found(crate_position) -> void:
	var contents = possible_contents[randi() % possible_contents.size()]
	rpc("_do_spawn_drop_crate", crate_position, contents.resource_path)

remotesync func _do_spawn_drop_crate(_position: SGFixedVector2, pickup_path: String):
	var crate = DropCrate.instance()
	crate.name = 'DropCrate'
	spawns.add_child(crate)
	crate.set_global_fixed_position(_position)
	crate.sync_to_physics_engine()
	crate.set_contents(load(pickup_path))

func clear():
	for child in spawns.get_children():
		remove_child(child)
		child.queue_free()
