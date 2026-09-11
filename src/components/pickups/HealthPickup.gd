extends "res://src/components/pickups/Pickup.gd"
class_name HealthPickup

@export var health: int = 0

func pickup(tank) -> void:
	if tank.has_method("restore_health"):
		tank.restore_health(health)
