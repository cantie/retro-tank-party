extends Node

var _multiple_parent: Node
var _multiple_map := {}

func _ready() -> void:
	_multiple_parent = Node2D.new()
	_multiple_parent.name = '_Multiple'
	add_child(_multiple_parent)

func play(name: String, multiple: bool = false):
	var node = get_node(name)
	assert(node != null, "No sound with name " + name)
	
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		if multiple:
			return play_multiple(node)
		else:
			node.play()
		return node
	elif node is Node and node != _multiple_parent:
		var players = []
		for child in node.get_children():
			if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
				players.append(child)
		players.shuffle()
		if multiple:
			return play_multiple(players[0])
		else:
			players[0].play()
		return players[0]
	
	return null

func play_multiple(node, unique_name: String = '') -> Node:
	if not node is AudioStreamPlayer and not node is AudioStreamPlayer2D:
		return null
	
	if _multiple_map.has(unique_name):
		return _multiple_map[unique_name]
	
	var copy = node.duplicate(0)
	_multiple_map[unique_name] = copy
	copy.connect('finished', self, '_cleanup_player', [copy, unique_name])
	_multiple_parent.add_child(copy)
	copy.play()
	return copy

func _cleanup_player(node, unique_name) -> void:
	node.queue_free()
	
	if unique_name != '':
		call_deferred('_cleanup_unique_name', unique_name)

func _cleanup_unique_name(unique_name) -> void:
	_multiple_map.erase(unique_name)
