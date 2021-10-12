extends SGStaticBody2D

enum TreeColors {
	GREEN,
	BROWN,
}

const TREE_COLORS = {
	TreeColors.GREEN: preload("res://assets/treeGreen_small.png"),
	TreeColors.BROWN: preload("res://assets/treeBrown_small.png"),
}

export (TreeColors) var tree_color: int = TreeColors.GREEN setget set_tree_color

onready var sprite = $Sprite

func set_tree_color(color: int) -> void:
	if sprite == null:
		yield(self, "ready")
	sprite.region_rect = TREE_COLORS[color]

