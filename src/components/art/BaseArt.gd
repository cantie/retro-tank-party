extends Reference

var art_style_resource
var texture_replace_cache := {}

func setup_art(_art_style_resource) -> void:
	art_style_resource = _art_style_resource

func setup_terrain_tiles(terrain_tiles: TileSet) -> void:
	if art_style_resource.texture_base_path != "":
		var texture_path = art_style_resource.texture_base_path + '/terraintiles.png'
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path)
			for tile_id in terrain_tiles.get_tiles_ids():
				terrain_tiles.tile_set_texture(tile_id, texture)

func _replace_sprite_texture(id: String, node: Node) -> void:
	if node.has_node(@"Sprite"):
		var sprite: Sprite = node.get_node(@"Sprite")
		if texture_replace_cache.has(id):
			var texture = texture_replace_cache[id]
			if texture != null and sprite.texture != texture:
				sprite.texture = texture
		else:
			var texture_path: String = art_style_resource.texture_base_path + '/' + id + ".png"
			if sprite.texture.resource_path == texture_path:
				texture_replace_cache[id] = sprite.texture
			elif not ResourceLoader.exists(texture_path):
				texture_replace_cache[id] = null
			else:
				var texture = load(texture_path)
				texture_replace_cache[id] = texture
				sprite.texture = texture

func preprocess_visual_id(id: String, node: Node, info: Dictionary = {}) -> String:
	match id:
		'TankBody', 'TankTurret', 'TankBullet':
			return id + str(info['player_index'])
		'Explosion':
			return id + str(info['type'])
		'TreeBig', 'TreeSmall':
			return id + '_' + info['color']
	return id

func replace_visual(id: String, node: Node, info: Dictionary = {}) -> Node:
	if node == null:
		return null
	
	if art_style_resource.texture_base_path != "":
		_replace_sprite_texture(id, node)
	
	return node

func get_tank_color(index: int) -> Color:
	return Color()

func get_team_color(index: int) -> Color:
	return Color()
