extends Node2D

onready var sprite = $Sprite

func setup_visual(info: Dictionary) -> void:
	sprite.frame = info['player_index'] - 1
