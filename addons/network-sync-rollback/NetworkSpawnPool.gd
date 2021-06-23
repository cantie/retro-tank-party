extends Node
class_name NetworkSpawnPool

var counter := 0
var pool := {}

signal spawn (name)

func _ready() -> void:
	add_to_group('network_sync')
	SyncManager.connect("sync_stopped", self, "_on_SyncManager_sync_stopped")

func _on_SyncManager_sync_stopped() -> void:
	counter = 0
	pool.clear()

func track_node(node: Node, rename: bool = true) -> void:
	counter += 1
	if rename:
		node.name = name + "--" + str(counter)
	pool[node.name] = node

func _save_state() -> Dictionary:
	for node_name in pool:
		var node = pool[node_name]
		if not is_instance_valid(node):
			pool.erase(node_name)
		elif node.is_queued_for_deletion():
			if node.get_parent():
				node.get_parent().remove_child(node)
			pool.erase(node_name)
	
	return {
		pool = pool.keys(),
		counter = counter,
	}

func _load_state(state: Dictionary) -> void:
	var previous_names = state['pool']
	
	# Remove nodes that aren't in the state we are loading.
	for node_name in pool:
		if not node_name in previous_names:
			var node = pool[node_name]
			if node.has_method('_network_despawn'):
				node._network_despawn()
			node.queue_free()
			if node.get_parent():
				node.get_parent().remove_child(node)
			pool.erase(node_name)

	counter = state['counter']
	
	# Spawn nodes that don't already exist in our pool.	
	for node_name in previous_names:
		if not pool.has(node_name):
			emit_signal("spawn", node_name)
