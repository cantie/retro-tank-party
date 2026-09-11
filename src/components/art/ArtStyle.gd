extends Resource
class_name ArtStyle

@export_String) var name := ""
@export_String, DIR) var texture_base_path := ""
@export_Script) var art_script: Script = preload("res://src/components/art/BaseArt.gd")
@export_Texture) var cursor_texture: Texture = preload("res://assets/cursor.png")
