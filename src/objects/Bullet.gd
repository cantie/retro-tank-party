extends "res://src/components/weapons/BaseBullet.gd"

onready var bullet_sprite = $BulletPivot/Sprite

var speed = 1529173 # ~23.33

func _network_spawn(data: Dictionary) -> void:
	._network_spawn(data)
	bullet_sprite.frame = player_index - 1

func explode(type: String) -> void:
	.explode(type)
	queue_free()
	lifetime_timer.stop()

func _network_process(delta: float, _input: Dictionary) -> void:
	._network_process(delta, _input)
	fixed_position.iadd(vector.mul(speed))
	sync_to_physics_engine()

func _on_LifetimeTimer_timeout() -> void:
	explode("smoke")
