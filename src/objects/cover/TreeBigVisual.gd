extends Node2D

const TREE_COLORS = [
	preload("res://assets/treeGreen_large.png"),
	preload("res://assets/treeBrown_large.png"),
]

onready var sprite = $Sprite

func setup_visual(info) -> void:
	sprite.texture = TREE_COLORS[info['tree_color']]
