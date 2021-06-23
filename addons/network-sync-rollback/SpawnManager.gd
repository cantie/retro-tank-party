extends Node

var spawn_records := {}
var spawned_nodes := {}

func _ready() -> void:
	add_to_group('network_sync')
	SyncManager.connect("sync_stopped", self, "_on_SyncManager_sync_stopped")

func _on_SyncManager_sync_stopped() -> void:
	spawn_records.clear()
	spawned_nodes.clear()

func spawn(name: String, parent: Node, scene: PackedScene, data: Dictionary) -> Node:
	var spawned_node = scene.instance()
	spawned_node.name = name
	parent.add_child(spawned_node, true)
	
	if spawned_node.has_method('_network_spawn_preprocess'):
		data = spawned_node._network_spawn_preprocess(data)
	
	if spawned_node.has_method('_network_spawn'):
		spawned_node._network_spawn(data)
	
	var spawn_record := {
		name = spawned_node.name,
		parent = parent.get_path(),
		scene = scene.resource_path,
		data = data,
	}
	
	var node_path = str(spawned_node.get_path())
	spawn_records[node_path] = spawn_record
	spawned_nodes[node_path] = spawned_node
	
	return spawned_node

func _save_state() -> Dictionary:
	for node_path in spawned_nodes:
		var node = spawned_nodes[node_path]
		if not is_instance_valid(node):
			spawned_nodes.erase(node_path)
			spawn_records.erase(node_path)
		elif node.is_queued_for_deletion():
			if node.get_parent():
				node.get_parent().remove_child(node)
			spawned_nodes.erase(node_path)
			spawn_records.erase(node_path)
	
	return spawn_records.duplicate()

func _load_state(state: Dictionary) -> void:
	spawn_records = state.duplicate()
	
	# Remove nodes that aren't in the state we are loading.
	for node_path in spawned_nodes:
		if not spawn_records.has(node_path):
			var node = spawned_nodes[node_path]
			if node.has_method('_network_despawn'):
				node._network_despawn()
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()
			spawned_nodes.erase(node_path)
	
	# Spawn nodes that don't already exist.
	for node_path in spawn_records:
		if not spawned_nodes.has(node_path):
			var spawn_record = spawn_records[node_path]
			
			var parent = get_tree().current_scene.get_node(spawn_record['parent'])
			var scene = load(spawn_record['scene'])
			
			var spawned_node = scene.instance()
			spawned_node.name = spawn_record['name']
			parent.add_child(spawned_node, true)
			
			if spawned_node.has_method('_network_spawn'):
				spawned_node._network_spawn(spawn_record['data'])
			
			spawned_nodes[node_path] = spawned_node
