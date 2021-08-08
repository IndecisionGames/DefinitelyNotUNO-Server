extends Node

class Player:
	var id: int
	var name: String

var players = []
var names = {}

func add_player(player_id, player_name):
	player_name = player_name.strip_edges()

	if !names.has(player_name):
		names[player_name] = 0
	else:
		names[player_name] += 1
		player_name = player_name.substr(0,8) + " (" + str(names[player_name]) + ")"

	var player = Player.new()
	player.name = player_name
	player.id = player_id
	players.append(player)

func remove_player(player_id):
	for player in players:
		if player.id == player_id:
			players.erase(player)
			return

func get_player_names():
	var names = []
	for player in players:
		names.append(player.name)
	return names
