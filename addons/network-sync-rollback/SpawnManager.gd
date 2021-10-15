extends Node

var spawn_records := {}
var spawned_nodes := {}
var counter := {}

var is_respawning := false

signal scene_spawned (name, spawned_node, scene, data)

func _ready() -> void:
	add_to_group('network_sync')

func setup_spawn_manager(SyncManager) -> void:
	SyncManager.connect("sync_started", self, "_on_SyncManager_sync_started")
	SyncManager.connect("sync_stopped", self, "_on_SyncManager_sync_stopped")

func reset() -> void:
	spawn_records.clear()
	spawned_nodes.clear()
	counter.clear()

func _on_SyncManager_sync_started() -> void:
	reset()

func _on_SyncManager_sync_stopped() -> void:
	reset()

func _rename_node(name: String) -> String:
	if not counter.has(name):
		counter[name] = 0
	counter[name] += 1
	return name + str(counter[name])

func _remove_colliding_node(name: String, parent: Node) -> void:
	if parent.has_node(name):
		var existing_node = parent.get_node(name)
		push_warning("Removing node %s which is in the way of new spawn" % existing_node)
		parent.remove_child(existing_node)
		existing_node.queue_free()

func spawn(name: String, parent: Node, scene: PackedScene, data: Dictionary, rename: bool = true, signal_name: String = '') -> Node:
	if not SyncManager.started:
		push_error("Refusing to spawn %s before SyncManager has started" % name)
		return null
	
	var spawned_node = scene.instance()
	if signal_name == '':
		signal_name = name
	if rename:
		name = _rename_node(name)
	_remove_colliding_node(name, parent)
	spawned_node.name = name
	parent.add_child(spawned_node)
	
	if spawned_node.has_method('_network_spawn_preprocess'):
		data = spawned_node._network_spawn_preprocess(data)
	
	if spawned_node.has_method('_network_spawn'):
		spawned_node._network_spawn(data)
	
	var spawn_record := {
		name = spawned_node.name,
		parent = parent.get_path(),
		scene = scene.resource_path,
		data = data,
		signal_name = signal_name,
	}
	
	var node_path = str(spawned_node.get_path())
	spawn_records[node_path] = spawn_record
	spawned_nodes[node_path] = spawned_node
	
	#print ("[%s] spawned: %s" % [SyncManager.current_tick, spawned_node.name])
	
	emit_signal("scene_spawned", signal_name, spawned_node, scene, data)
	
	return spawned_node

func _save_state() -> Dictionary:
	for node_path in spawned_nodes.keys().duplicate():
		var node = spawned_nodes[node_path]
		if not is_instance_valid(node):
			spawned_nodes.erase(node_path)
			spawn_records.erase(node_path)
			#print ("[SAVE %s] removing invalid: %s" % [SyncManager.current_tick, node_path])
		elif node.is_queued_for_deletion():
			if node.get_parent():
				node.get_parent().remove_child(node)
			spawned_nodes.erase(node_path)
			spawn_records.erase(node_path)
			#print ("[SAVE %s] removing deleted: %s" % [SyncManager.current_tick, node_path])
	
	return {
		spawn_records = spawn_records.duplicate(),
		counter = counter.duplicate(),
	}

func _load_state(state: Dictionary) -> void:
	spawn_records = state['spawn_records'].duplicate()
	counter = state['counter'].duplicate()
	
	# Remove nodes that aren't in the state we are loading.
	for node_path in spawned_nodes.keys().duplicate():
		if not spawn_records.has(node_path):
			var node = spawned_nodes[node_path]
			if node.has_method('_network_despawn'):
				node._network_despawn()
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()
			spawned_nodes.erase(node_path)
			#print ("[LOAD %s] de-spawned: %s" % [SyncManager.current_tick, node_path])
	
	# Spawn nodes that don't already exist.
	for node_path in spawn_records.keys():
		if spawned_nodes.has(node_path):
			var old_node = spawned_nodes[node_path]
			if not is_instance_valid(old_node) or old_node.is_queued_for_deletion():
				spawned_nodes.erase(node_path)
		
		is_respawning = true
		
		if not spawned_nodes.has(node_path):
			var spawn_record = spawn_records[node_path]
			
			var parent = get_tree().current_scene.get_node(spawn_record['parent'])
			assert(parent != null, "Can't re-spawn node when parent doesn't exist")
			var scene = load(spawn_record['scene'])
			
			var name = spawn_record['name']
			_remove_colliding_node(name, parent)
			
			var spawned_node = scene.instance()
			spawned_node.name = name
			parent.add_child(spawned_node)
			
			if spawned_node.has_method('_network_spawn'):
				spawned_node._network_spawn(spawn_record['data'])
			
			spawned_nodes[node_path] = spawned_node
			emit_signal("scene_spawned", spawn_record['signal_name'], spawned_node, scene, spawn_record['data'])
			
			#print ("[LOAD %s] re-spawned: %s" % [SyncManager.current_tick, node_path])
		
		is_respawning = false

