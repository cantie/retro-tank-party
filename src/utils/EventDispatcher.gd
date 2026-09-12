extends RefCounted

var listeners := {}

class RTPEvent:
	var propagating := true
	
	func stop_propagation() -> void:
		propagating = false

class RTPEventListener:
	var object: WeakRef
	var method: String
	var args: Array
	var priority: int
	
	func _init(_object: Object, _method: String, _priority: int, _args: Array) -> void:
		object = weakref(_object)
		method = _method
		args = _args
		priority = _priority
	
	func dispatch_event(event: RTPEvent) -> bool:
		var real_object = object.get_ref()
		if not real_object:
			return false
		
		var tmp = args.duplicate()
		tmp.push_front(event)
		real_object.callv(method, tmp)
		
		return true

func subscribe(event_name: String, object: Object, method: String, priority: int, args: Array = []) -> void:
	var listener = RTPEventListener.new(object, method, priority, args)
	if not listeners.has(event_name):
		listeners[event_name] = []
	listeners[event_name].append(listener)
	listeners[event_name].sort_custom(_sort_listener)

func unsubscribe(event_name: String, object: Object, method: String) -> void:
	if not listeners.has(event_name):
		assert(false, "Cannot unsubscribe - no listeners on event %s" % event_name)
		return
	for i in range(listeners[event_name].size()):
		var listener = listeners[event_name][i]
		if listener.object.get_ref() == object and listener.method == method:
			listeners[event_name].remove_at(i)
			return
	assert(false, "Cannot unsubscribe - no matching listeners on event %s" % event_name)

func has_subscriber(event_name: String, object: Object, method: String) -> bool:
	if not listeners.has(event_name):
		return false
	
	for i in range(listeners[event_name].size()):
		var listener = listeners[event_name][i]
		if listener.object.get_ref() == object and listener.method == method:
			return true
	
	return false

func clear() -> void:
	listeners.clear()

func _sort_listener(a: RTPEventListener, b: RTPEventListener) -> bool:
	return a.priority < b.priority

func dispatch_event(event_name: String, event: RTPEvent) -> void:
	if not listeners.has(event_name):
		return
		
	var invalid := []
	var index = 0
	
	for listener in listeners[event_name].duplicate():
		if not event.propagating:
			return
		if not listener.dispatch_event(event):
			push_warning("Invalid event listener for event %s" % event_name)
			invalid.append(index)
		index += 1
	
	# Remove any invalid event listeners that we discovered
	if invalid.size() > 0:
		var old = listeners[event_name]
		listeners[event_name] = []
		for i in range(old.size()):
			if not i in invalid:
				listeners[event_name].append(old[i])
