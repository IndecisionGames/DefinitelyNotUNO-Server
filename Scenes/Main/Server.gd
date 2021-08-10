extends Node

const CardBase = preload("res://Common/CardBase.gd")

const PORT = 31416

var network = WebSocketServer.new()
var upnp = UPNP.new()

onready var Lobby = get_node("Lobby")
onready var GameServer = get_node("GameServer")

var max_players = 8
var players = 0

var ready_clients = 0

func _ready():
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")
	start_server()
	
func _exit_tree():
	upnp.delete_port_mapping(PORT, "TCP")

func start_server():
	upnp.discover()
	upnp.add_port_mapping(PORT, PORT, "", "TCP")
	print()
	
	network.listen(PORT, PoolStringArray(), true)
	get_tree().set_network_peer(network)
	print("Server started")
	print("IP: ", upnp.query_external_address())
	print("Port: ", PORT)

func _process(_delta):
	if network.is_listening():
		network.poll()

func _peer_connected(player_id):
	if players < 8:
		players += 1
		print("Player " + str(player_id) + " connected")
		rpc_id(player_id, "join_server", players-1, players==1)

func _peer_disconnected(player_id):
	players -= 1
	Lobby.remove_player(player_id)
	print("Player " + str(player_id) + " disconnected")
	update_lobby()

# Lobby
remote func join_lobby(name):
	var player_id = get_tree().get_rpc_sender_id()
	Lobby.add_player(player_id, name)
	update_lobby()

func update_lobby():
	var names = Lobby.get_player_names()
	print("Players: " + str(names))
	rpc("update_lobby", names)

remote func update_rules(rules):
	Rules.load_from_dict(rules)
	rpc("sync_rules", rules)


# Game setup
remote func start_game():
	GameServer.reset_game()
	Rules.NUM_PLAYERS = Lobby.players.size()
	for i in range(Lobby.players.size()):
		rpc_id(Lobby.players[i].id, "set_player", i)

		var player = GameState.Player.new()
		player.name = Lobby.players[i].name
		GameState.players.append(player)
	
	print("Waiting for clients to ready")
	ready_clients = 0
	rpc("request_start", Rules.to_dict())

remote func client_ready():
	ready_clients += 1
	if ready_clients == players:
		print("Starting Game")
		GameServer.start_game()
	else:
		print("Waiting for %s clients" % (ready_clients - players))

func emit_game_won(player):
	rpc("emit_game_won", player)

# Server to Client
func emit_game_start():
	rpc("emit_game_start", GameState.to_dict())

func emit_game_update():
	rpc("emit_game_update", GameState.to_dict())

func emit_cards_drawn(player, cards):
	var drawn_cards = []
	for card in cards:
		drawn_cards.append(card.to_dict())
	rpc("emit_cards_drawn", player, drawn_cards)

func emit_card_played(player, card):
	rpc("emit_card_played", player, card.to_dict())

func emit_event(event_type, player):
	rpc("emit_event", event_type, player)

func request_wild_pick(player):
	rpc_id(Lobby.players[player].id, "request_wild_pick", player)

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
