extends Control

func _on_Credits_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))
