extends "res://src/components/weapons/BaseBullet.gd"

onready var bullet_sprite = $BulletPivot/Sprite

var speed = 1529173 # ~23.33

const BULLET_COLORS = {
	1: Rect2(570, 584, 16, 28),
	2: Rect2(407, 308, 16, 28),
	3: Rect2(391, 308, 16, 28),
	4: Rect2(560, 348, 16, 28),
}

func _network_spawn(data: Dictionary) -> void:
	._network_spawn(data)
	bullet_sprite.region_rect = BULLET_COLORS[player_index]
	# Pre-multiply the vector.
	vector.imul(speed)

func explode(type: String) -> void:
	.explode(type)
	SyncManager.despawn(self)
	lifetime_timer.stop()

func _network_process(delta: float, _input: Dictionary) -> void:
	._network_process(delta, _input)
	fixed_position.iadd(vector)
	#sync_to_physics_engine()

func _on_LifetimeTimer_timeout() -> void:
	explode("smoke")
