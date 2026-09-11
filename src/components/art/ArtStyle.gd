extends Resource
class_name ArtStyle

@export var name := ""
@export_dir var texture_base_path := ""
@export var art_script: Script = preload("res://src/components/art/BaseArt.gd")
@export var cursor_texture: Texture2D = preload("res://assets/cursor.png")
