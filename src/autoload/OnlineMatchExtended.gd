extends "res://addons/nakama-webrtc/OnlineMatch.gd"

# For when we only want players that aren't spectators.

func get_active_players() -> Dictionary:
	var active_players := {}
	for session_id in players:
		var player = players[session_id]
		if not SyncManager.get_peer(player.peer_id).spectator:
			active_players[session_id] = player
	return active_players

func get_active_players_by_peer_id() -> Dictionary:
	var result := {}
	for player in get_active_players().values():
		result[player.peer_id] = player
	return result

func get_active_player_names_by_peer_id() -> Dictionary:
	var result := {}
	for session_id in get_active_players():
		result[players[session_id]['peer_id']] = players[session_id]['username']
	return result

