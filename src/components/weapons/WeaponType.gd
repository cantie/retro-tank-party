extends Resource
class_name WeaponType

@export var name: String = ""
@export var weapon_script: Script = preload("res://src/components/weapons/BaseWeapon.gd")
@export var bullet_scene: PackedScene = preload("res://src/objects/Bullet.tscn")
@export var damage: int = 10
