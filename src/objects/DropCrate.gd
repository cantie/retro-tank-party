extends SGStaticBody2D

var GreenTwigs = preload("res://src/objects/cosmetic/GreenTwigs.tscn")

var contents: Pickup

func _ready():
	$AnimationPlayer.play("glow")

func _network_spawn(data: Dictionary) -> void:
	set_global_fixed_position(data['fixed_position'])
	contents = load(data['contents_path'])
	sync_to_physics_engine()

func take_damage(damage: int, attacker_id: int, attack_vector: SGFixedVector2) -> void:
	open_crate()

func open_crate() -> void:
	var twigs = GreenTwigs.instance()
	twigs.position = position
	get_parent().add_child(twigs)
		
	var powerup = contents.instance()
	powerup.set_name("Powerup")
	powerup.position = position
	get_parent().add_child(powerup)
	
	queue_free()
