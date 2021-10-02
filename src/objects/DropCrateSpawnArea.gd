extends SGArea2D

const DropCrate = preload("res://src/objects/DropCrate.tscn")

# 3932160 = 60
var crate_size = SGFixed.vector2(3932160, 3932160)

onready var collision_shape = $CollisionShape2D
onready var drop_timer = $DropTimer
onready var spawns = $Spawns
onready var rng = $RandomNumberGenerator

var possible_contents := []
var detector

func map_object_start(map, game):
	rng.set_seed(game.generate_random_seed())
	possible_contents = game.possible_pickups
	detector = game.create_free_space_detector(rng)
	drop_timer.start()

func map_object_stop(map, game):
	drop_timer.stop()
	if detector:
		detector.queue_free()
		detector = null
	clear()

func has_drop_crate_or_powerup() -> bool:
	return spawns.has_node("DropCrate") or spawns.has_node("Powerup")

func spawn_drop_crate() -> void:
	if not has_drop_crate_or_powerup():
		var extents = collision_shape.shape.extents
		var fixed_global_position = get_global_fixed_position()
		var area_top_left = fixed_global_position.sub(extents)
		var area_bottom_right = fixed_global_position.add(extents)
		
		var crate_position = detector.detect_free_space(area_top_left, area_bottom_right, crate_size)
		var contents = possible_contents[rng.randi() % possible_contents.size()]
		
		SyncManager.spawn('DropCrate', spawns, DropCrate, {
			fixed_position = crate_position,
			contents_path = contents.resource_path,
		}, false)

func _on_DropTimer_timeout() -> void:
	spawn_drop_crate()

func clear():
	for child in spawns.get_children():
		spawns.remove_child(child)
		child.queue_free()
