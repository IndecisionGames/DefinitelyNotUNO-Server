extends Node

var network = NetworkedMultiplayerENet.new()
var port = 31416
var max_players = 8

onready var Lobby = get_node("Lobby")

var players = 0

func _ready():
	start_server()

func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server started")

	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")

func _peer_connected(player_id):
	if players < 8:
		players += 1
		print("Player " + str(player_id) + " connected")
		rpc_id(player_id, "join_server", players-1)

func _peer_disconnected(player_id):
	players -= 1
	remove_from_lobby_local(player_id)
	print("Player " + str(player_id) + " disconnected")


#### LOBBY ####
remote func add_to_lobby(name):
	var player_id = get_tree().get_rpc_sender_id()
	Lobby.add_player(player_id, name)
	update_lobby()

remote func remove_from_lobby():
	var player_id = get_tree().get_rpc_sender_id()
	remove_from_lobby_local(player_id)

func remove_from_lobby_local(player_id):
	Lobby.remove_player(player_id)
	update_lobby()

func update_lobby():
	var names = Lobby.get_ordered_player_names()
	print("Players: " + str(names))
	for player in Lobby.get_player_ids():
		var pos = Lobby.get_player_pos(player)
		rpc_id(player, "update_lobby", pos, names)
