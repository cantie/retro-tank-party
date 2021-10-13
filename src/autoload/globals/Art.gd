extends Node

var art_style_resource: ArtStyle
var art_style

var terrain_tiles: TileSet

func _ready() -> void:
	terrain_tiles = preload("res://assets/terraintiles.tres")
	load_art_style("res://mods/core/art/classic.tres")

func load_art_style(path: String) -> void:
	art_style_resource = load(path)
	art_style = art_style_resource.art_script.new()
	art_style.setup_art(art_style_resource)
	art_style.setup_terrain_tiles(terrain_tiles)

func replace_visual(id: String, node: Node, info: Dictionary = {}) -> Node:
	id = art_style.preprocess_visual_id(id, node, info)
	var replacement = art_style.replace_visual(id, node, info)
	
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
	return art_style.get_tank_color(index)

func get_team_color(index: int) -> Color:
	return art_style.get_team_color(index)
