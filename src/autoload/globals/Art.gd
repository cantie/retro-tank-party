extends Node

var art_style: ArtStyle = preload("res://mods/core/art/classic.tres")

func load_art_style(path: String) -> void:
	art_style = load(path)

func replace_visual(id: String, node: Node, info: Dictionary = {}) -> Node:
	var replacement = art_style.art_script.replace_visual(id, node, info)
	
	# Protection for badly behaving art scripts.
	if replacement == null:
		return node
	
	if node != replacement:
		var parent = node.get_parent()
		if parent:
			var orig_name = node.name
			var orig_index = node.get_index()
			
			parent.remove_child(node)
			node.queue_free()
			
			replacement.name = orig_name
			parent.add_child(replacement)
			parent.move_child(replacement, orig_index)
	
	if replacement.has_method('setup_visual'):
		replacement.setup_visual(info)
	
	return replacement

func get_tank_color(index: int) -> Color:
	return art_style.art_script.get_tank_color(index)

func get_team_color(index: int) -> Color:
	return art_style.art_script.get_team_color(index)
