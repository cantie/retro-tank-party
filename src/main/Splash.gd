extends Control

func _on_MadeInGodotVideo_finished() -> void:
	get_tree().change_scene_to_file("res://src/main/Title.tscn")
