extends SGKinematicBody2D

const TANK_BODY_COLORS = {
	1: preload("res://assets/tanks/blue_tank_body.png"),
	2: preload("res://assets/tanks/green_tank_body.png"),
	3: preload("res://assets/tanks/red_tank_body.png"),
	4: preload("res://assets/tanks/black_tank_body.png"),
}

onready var body_sprite := $BodySprite
onready var turret_sprite := $TurretPivot/TurretSprite
onready var turret_pivot := $TurretPivot
onready var bullet_start_position := $TurretPivot/BulletStartPosition
onready var collision_shape := $CollisionPolygon2D

func set_tank_color(index: int) -> void:
	body_sprite.texture = TANK_BODY_COLORS[index]
	turret_sprite.frame = index - 1
