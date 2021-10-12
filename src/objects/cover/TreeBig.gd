extends SGStaticBody2D

enum TreeColors {
	GREEN,
	BROWN,
}

export (TreeColors) var tree_color: int = TreeColors.GREEN setget set_tree_color

onready var visual = $Visual

func set_tree_color(color: int) -> void:
	if visual == null:
		yield(self, "ready")
	visual = Globals.art.replace_visual("TreeBig", visual, {tree_color = tree_color})
