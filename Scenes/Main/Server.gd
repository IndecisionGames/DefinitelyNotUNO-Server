extends Node

const CardBase = preload("res://Common/CardBase.gd")

var network = NetworkedMultiplayerENet.new()
var upnp = UPNP.new()
var port = 31416
var max_players = 8

onready var Lobby = get_node("Lobby")
onready var GameServer = get_node("GameServer")

var players = 0

func _ready():
	start_server()
	
func _exit_tree():
	upnp.delete_port_mapping(port, port)

func start_server():
	upnp.discover()
	upnp.add_port_mapping(port, port)
	
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



# Game setup
remote func start_game():
	randomize()
	GameServer.reset_game()
	Rules.NUM_PLAYERS = Lobby.players.size()
	for i in range(Lobby.players.size()):
		rpc_id(Lobby.players[i], "set_player", i)
		var player = GameState.Player.new()
		player.name = Lobby.player_names[Lobby.players[i]]
		GameState.players.append(player)

	GameServer.start_game()

# Server to Client
func emit_game_start():
	print("Starting Game")
	rpc("emit_game_start", Rules.to_dict(), GameState.to_dict())

remote func emit_game_won(player):
	rpc("emit_game_won", player)

func emit_game_update():
	rpc("emit_game_update", GameState.to_dict())

func emit_cards_drawn(player, cards):
	var drawn_cards = []
	for card in cards:
		drawn_cards.append(card.to_dict())
	rpc("emit_cards_drawn", player, drawn_cards)

func emit_card_played(player, card):
	rpc("emit_card_played", player, card.to_dict())

func request_wild_pick(player):
	rpc_id(Lobby.players[player], "request_wild_pick", player)

# Client to Server
signal play_request(player, card)
signal draw_request(player)
signal uno_request(player)
signal wild_pick(colour)

remote func request_play_card(player_id, card):
		emit_signal("play_request", player_id, CardBase.new().load_from_dict(card))

remote func request_draw_card(player_id):
		emit_signal("draw_request", player_id)

remote func request_uno(player_id):
		emit_signal("uno_request", player_id)

remote func wild_pick(colour):
		emit_signal("wild_pick", colour)
