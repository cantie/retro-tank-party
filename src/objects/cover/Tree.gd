extends SGStaticBody2D

enum TreeColors {
	GREEN,
	BROWN,
}

const COLOR_NAMES = {
	TreeColors.GREEN: "green",
	TreeColors.BROWN: "brown",
}

@export var visual_id: String = ""
@export var tree_color: int = TreeColors.GREEN:
	set = set_tree_color

@onready var visual = $Visual

func _ready() -> void:
	visual = Globals.art.replace_visual(visual_id, visual, {
		color = COLOR_NAMES[tree_color]
	})

func set_tree_color(color: int) -> void:
	if color != tree_color:
		tree_color = color
		if visual == null:
			await self.ready
		visual = Globals.art.replace_visual(visual_id, visual, {
			color = COLOR_NAMES[tree_color]
		})
