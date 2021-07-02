extends "res://src/components/modes/BaseManager.gd"

onready var show_score_timer := $ShowScoreTimer
onready var next_round_timer := $NextRoundTimer

var round_over := false
var match_over := false

func _get_synchronized_rpc_methods() -> Array:
	return ['_setup_new_round']

func _do_match_setup() -> void:
	._do_match_setup()
	
	game.connect("player_dead", self, "_on_game_player_dead")

func start_new_round() -> void:
	var operation = RemoteOperations.synchronized_rpc(self, "_setup_new_round")
	if yield(operation, "completed"):
		game.rpc("game_start")
	else:
		match_scene.quit_match()

func _setup_new_round() -> void:
	round_over = false
	game.game_setup(players, map_path)

func _save_state() -> Dictionary:
	return {
		round_over = round_over,
		match_over = match_over,
	}

func _load_state(state: Dictionary) -> void:
	round_over = state['round_over']
	match_over = state['match_over']

func _on_game_player_dead(player_id: int, killer_id: int) -> void:
	var my_id = get_tree().get_network_unique_id()
	if player_id == my_id:
		ui_layer.show_message("You lose!")
		game.enable_watch_camera()
	
	if not round_over and  (game.players_alive.size() == 1 or not _check_team_alive(player_id)):
		round_over = true
		var winner_id := -1
		if use_teams:
			# The other team wins
			winner_id = 1 if get_player_team(player_id) == 0 else 0
		else:
			var player_keys = game.players_alive.keys()
			winner_id = player_keys[0]

		score.increment_score(winner_id)
		match_over = score.get_score(winner_id) >= config['points_to_win']
		
		show_winner(score.get_name(winner_id))
		#rpc("show_winner", score.get_name(winner_id), score.to_dict(), is_match)

func _check_team_alive(player_id: int) -> bool:
	var team_id = get_player_team(player_id)
	for team_player_id in teams[team_id]:
		if game.players_alive.has(team_player_id):
			return true
	return false

remotesync func show_winner(winner_name: String) -> void:
	if match_over:
		ui_layer.show_message(winner_name + " WINS THE WHOLE MATCH!")
	else:
		ui_layer.show_message(winner_name + " wins this round!")
	
	show_score_timer.start()

func _on_ShowScoreTimer_timeout() -> void:
	ui_layer.show_screen("RoundScreen", {score = score.to_dict()})
	next_round_timer.start()

func _on_NextRoundTimer_timeout() -> void:
	if match_over:
		match_scene.finish_match()
	elif get_tree().is_network_server():
		start_new_round()
