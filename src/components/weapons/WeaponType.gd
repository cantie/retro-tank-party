extends Resource
class_name WeaponType

@export_String) var name := ""
@export_Script) var weapon_script: Script = preload("res://src/components/weapons/BaseWeapon.gd")
@export_PackedScene) var bullet_scene: PackedScene = preload("res://src/objects/Bullet.tscn")
@export_int) var damage := 10
