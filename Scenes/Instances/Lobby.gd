extends Node

var players = []
var names = []
var player_names = {} # map from player id to player name

func add_player(player_id, name):
	name = name.strip_edges()

	var duplicate_index = 1
	var original_name = name
	while name in names:
		name = original_name.substr(0,8) + " (" + str(duplicate_index) + ")"
		duplicate_index += 1

	players.append(player_id)
	player_names[player_id] = name
	names.append(name)

func remove_player(player_id):
	var player_index = players.find(player_id)
	if player_index == -1:
		return

	players.remove(player_index)
	player_names.erase(player_id)

func get_ordered_player_names():
	var names = []
	for player in players:
		names.append(player_names[player])
	return names

func get_player_pos(player_id):
	return players.find(player_id)

func get_player_ids():
	return players
