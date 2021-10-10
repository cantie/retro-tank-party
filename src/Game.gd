extends Node2D

var TankScene = preload("res://src/objects/Tank.tscn")
var FreeSpaceDetector = preload("res://src/game/FreeSpaceDetector.tscn")

onready var map: Node2D = $Map
onready var players_node := $Players
onready var player_camera := $PlayerCamera
onready var watch_camera := $WatchCamera
onready var hud := $CanvasLayer/HUD
# Johnny passes out random seeds!
onready var johnny := $RandomNumberGenerator

var map_scene: PackedScene
var game_started := false
var players := {}
var players_alive := {}
var possible_pickups := []
var player_start_transforms

signal game_error (message)
signal game_started ()
signal player_spawned (tank)
signal player_dead (player_id, killer_id)

class Player:
	var peer_id: int
	var name: String
	var index: int
	var team: int
	
	func _init(_peer_id: int, _name: String, _index: int, _team: int = -1):
		peer_id = _peer_id
		name = _name
		index = _index
		team = _team
	
	func to_dict() -> Dictionary:
		return {
			peer_id = peer_id,
			name = name,
			index = index,
			team = team,
		}
	
	static func from_dict(data: Dictionary) -> Player:
		return Player.new(data['peer_id'], data['name'], data['index'], data['team'])

func _get_synchronized_rpc_methods() -> Array:
	return ['respawn_player']

func _ready() -> void:
	SyncManager.connect("scene_spawned", self, "_on_SyncManager_scene_spawned")

# Initializes the game so that it is ready to really start.
func game_setup(_players: Dictionary, map_path: String, random_seed: int, _player_start_transforms = null) -> void:
	get_tree().paused = true
	
	if game_started:
		game_stop()
	
	if not load_map(map_path):
		emit_signal("game_error", "Unable to load map")
		return
	
	players = _players
	johnny.set_seed(random_seed)
	player_start_transforms = _player_start_transforms

	# Build up a list of possible contents for drawing randomly.
	for pickup_path in Modding.find_resources("pickups"):
		var pickup = load(pickup_path)
		for i in range(pickup.rarity):
			possible_pickups.append(pickup)
	
	_game_setup()

func _game_setup() -> void:
	hud.clear_all_labels()
	
	for peer_id in players:
		var player = players[peer_id]
		var start_transform = player_start_transforms[player.index - 1] if player_start_transforms and player.index <= player_start_transforms.size() else null
		respawn_player(peer_id, start_transform)
	
	var my_id: int = get_tree().get_network_unique_id()
	make_player_controlled(my_id)

func game_reset() -> void:
	if game_started:
		game_stop()
	#reload_map()
	_game_setup()

func respawn_player(peer_id: int, start_transform = null) -> void:
	if players_node.has_node(str(peer_id)):
		return
	
	if not players.has(peer_id):
		return
	var player = players[peer_id]
	players_alive[peer_id] = player
	
	var spawn_data := {
		game = self,
		player = player,
	}
	
	if start_transform:
		spawn_data['start_transform'] = start_transform
	else:
		var player_start_transforms = map.get_player_start_transforms()
		spawn_data['start_transform'] = player_start_transforms[player.index - 1]
	
	var tank = SyncManager.spawn(str(peer_id), players_node, TankScene, spawn_data, false, "Tank")

func _on_SyncManager_scene_spawned(name: String, spawned_node: Node, scene: PackedScene, data: Dictionary) -> void:
	if name == 'Tank':
		spawned_node.connect("player_dead", self, "_on_player_dead", [spawned_node])
		emit_signal("player_spawned", spawned_node)

func make_player_controlled(peer_id) -> void:
	var my_player := players_node.get_node(str(peer_id))
	if my_player and not my_player.player_controlled:
		my_player.player_controlled = true
		_setup_player_camera(my_player)
		_setup_player_listener(my_player)
	else:
		print ("Unable to make player controlled: node not found")

func get_tank(player_id: int):
	return players_node.get_node(str(player_id))

func get_my_tank():
	for peer_id in players_alive:
		var tank := players_node.get_node(str(peer_id))
		if tank.player_controlled:
			return tank
	return null

# Actually start the game on this client.
remotesync func game_start() -> void:
	game_started = true
	if map.has_method('map_start'):
		map.map_start(self)
	emit_signal("game_started")
	get_tree().paused = false
	if get_tree().is_network_server():
		SyncManager.start()

func game_stop() -> void:
	if map.has_method('map_stop'):
		map.map_stop(self)
	
	game_started = false
	
	players_alive.clear()
	watch_camera.current = true
	
	for child in players_node.get_children():
		players_node.remove_child(child)
		child.queue_free()

func load_map(path: String) -> bool:
	var new_map_scene = load(path)
	if not new_map_scene or not new_map_scene is PackedScene:
		return false
	
	map_scene = new_map_scene
	reload_map()
	
	return true

func reload_map() -> void:
	if not map_scene:
		return
	
	var map_index = map.get_index()
	remove_child(map)
	map.queue_free()
	
	map = map_scene.instance()
	map.name = 'Map'
	add_child(map)
	move_child(map, map_index)
	
	_setup_watch_camera()

func _setup_watch_camera() -> void:
	var viewport_rect = get_viewport_rect()
	var map_rect = map.get_map_rect()
	
	watch_camera.global_position = map_rect.position + (map_rect.size / 2)
	# Yes, on non-square maps, this will zoom differently on the X and Y,
	# but so far, no one has ever noticed this.
	watch_camera.zoom.x = max(1.0, map_rect.size.x / viewport_rect.size.x)
	watch_camera.zoom.y = max(1.0, map_rect.size.y / viewport_rect.size.y)

func _setup_player_camera(my_player) -> void:
	my_player.camera = player_camera
	player_camera.global_position = my_player.global_position
	watch_camera.current = false
	player_camera.current = true
	
	# Enable positional audio when the player_camera is enabled.
	Globals.use_positional_audio = true
	
	if map.has_method('get_map_rect'):
		var map_rect = map.get_map_rect()
		
		player_camera.limit_left = map_rect.position.x
		player_camera.limit_top = map_rect.position.y
		player_camera.limit_right = map_rect.end.x
		player_camera.limit_bottom = map_rect.end.y

func _setup_player_listener(my_player) -> void:
	var listener = Listener2D.new()
	my_player.add_child(listener)
	listener.make_current()

func kill_player(player_id) -> void:
	var player_node = players_node.get_node(str(player_id))
	if player_node:
		if player_node.has_method("die"):
			player_node.die()
		else:
			# If there is no die method, we do the most important things it
			# would have done.
			player_node.queue_free()
			_on_player_dead(-1, player_node)

func remove_player(player_id) -> void:
	players.erase(player_id)
	kill_player(player_id)

func enable_watch_camera(enable: bool = true) -> void:
	player_camera.current = not enable
	watch_camera.current = enable
	
	# Disable positional audio when the watch camera is enabled.
	Globals.use_positional_audio = not enable

func _on_player_dead(killer_id, tank) -> void:
	var peer_id = tank.get_network_master()
	# Ensure this will only ever be called once per player
	if players_alive.has(peer_id):
		players_alive.erase(peer_id)
		
		var player_node = players_node.get_node(str(peer_id))
		if player_node and player_node.player_controlled:
			hud.clear_all_labels()
		
		emit_signal("player_dead", peer_id, killer_id)

# From https://stackoverflow.com/a/12996028/364763
#
# License: CC BY-SA 4.0
# Author: Thomas Mueller
func _simple_integer_hash(x: int):
	x = ((x >> 16) ^ x) * 0x45d9f3b;
	x = ((x >> 16) ^ x) * 0x45d9f3b;
	x = (x >> 16) ^ x;
	return x

func generate_random_seed() -> int:
	return _simple_integer_hash(johnny.randi())

func create_free_space_detector(area: SGFixedRect2, dimensions: SGFixedVector2, rng: NetworkRandomNumberGenerator):
	var detector = FreeSpaceDetector.instance()
	detector.setup_free_space_detector(area, dimensions, rng)
	add_child(detector)
	return detector

func _save_state() -> Dictionary:
	var serialized_players_alive := {}
	for peer_id in players_alive:
		serialized_players_alive[peer_id] = players_alive[peer_id].to_dict()
	return {
		game_started = game_started,
		players_alive = serialized_players_alive,
	}

func _load_state(state: Dictionary) -> void:
	game_started = state['game_started']
	var serialized_players_alive = state['players_alive']
	for peer_id in serialized_players_alive:
		players_alive[peer_id] = Player.from_dict(serialized_players_alive[peer_id])
