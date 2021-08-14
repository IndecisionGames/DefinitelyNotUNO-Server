extends Node

const CardBase = preload("res://Common/CardBase.gd")
const GameInstance = preload("res://Scenes/Instances/GameInstance.tscn")

const PORT = 31416
var rng = RandomNumberGenerator.new()

var network = WebSocketServer.new()
var upnp = UPNP.new()

var game_instances = {}
var id_to_lobby_code = {}

func _ready():
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")
	
	rng.randomize()
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
	print("Started server on: indecisiongames.ddns.net")
	print("Port: ", PORT)

func _process(_delta):
	if network.is_listening():
		network.poll()

# Connections
func _peer_connected(id):
	print("Player %s connected" % id)

func _peer_disconnected(id):
	print("Player %s disconnected" % id)
	var lobby_code = id_to_lobby_code[id]
	if lobby_code:
		if !game_instances[lobby_code].remove_player(id):
			# delete game if no players
			remove_child(game_instances[lobby_code])
			game_instances.erase(lobby_code)
			print("Game deleted: %s" % lobby_code)

func _get_instance():
	return game_instances[id_to_lobby_code[get_tree().get_rpc_sender_id()]]

# Lobby
remote func host_lobby(name):
	var id = get_tree().get_rpc_sender_id()
	var lobby_code = String(rng.randi_range(1000, 9999))
	print("New game created: %s" % lobby_code)

	var new_instance = GameInstance.instance()
	add_child(new_instance)

	new_instance.instance_id = lobby_code
	game_instances[lobby_code] = new_instance
	id_to_lobby_code[id] = lobby_code
	new_instance.add_player(id, name)

remote func join_lobby(name, lobby_code):
	var id = get_tree().get_rpc_sender_id()
	var instance = game_instances.get(lobby_code)

	if !instance:
		send_error(id, "Game does not exist")
		return

	id_to_lobby_code[id] = lobby_code
	instance.add_player(id, name)

func start_lobby(id, lobby_code, rules, is_host):
	rpc_id(id, "start_lobby", lobby_code, rules, is_host)

func sync_lobby(ids, names):
	for id in ids:
		rpc_id(id, "sync_lobby", names)

func sync_rules(ids, rules):
	for id in ids:
		rpc_id(id, "sync_rules", rules)

remote func update_rules(rules):
	_get_instance().update_rules(rules)

func send_error(id, msg):
	rpc_id(id, "error", msg)

# Game setup
remote func start_game():
	_get_instance().start_game()

func set_player(id, player):
	rpc_id(id, "set_player", player)

func request_start(ids, rules):
	for id in ids:
		rpc_id(id,"request_start", rules)

remote func client_ready():
	_get_instance().client_ready()

# Server to Client
func emit_game_won(ids, player):
	for id in ids:
		rpc_id(id, "emit_game_won", player)

func emit_game_start(ids, game_state):
	for id in ids:
		rpc_id(id, "emit_game_start", game_state)

func emit_game_update(ids, game_state):
	for id in ids:
		rpc_id(id, "emit_game_update", game_state)

func emit_cards_drawn(ids, player, cards):
	for id in ids:
		rpc_id(id, "emit_cards_drawn", player, cards)

func emit_card_played(ids, player, card):
	for id in ids:
		rpc_id(id, "emit_card_played", player, card)

func emit_event(ids, event_type, player):
	for id in ids:
		rpc_id(id, "emit_event", event_type, player)

func request_wild_pick(id, player):
	rpc_id(id, "request_wild_pick", player)

# Client to Server
remote func request_play_card(player, card):
	_get_instance().request_play_card(player, card)

remote func request_draw_card(player):
	_get_instance().request_draw_card(player)

remote func request_uno(player):
	_get_instance().request_uno(player)

remote func wild_pick(colour):
	_get_instance().wild_pick(colour)
