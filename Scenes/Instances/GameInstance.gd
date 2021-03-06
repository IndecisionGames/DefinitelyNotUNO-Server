extends Node

const CardBase = preload("res://Common/CardBase.gd")

onready var Rules = get_node("Rules")
onready var GameState = get_node("GameState")
onready var GameServer = get_node("GameServer")
onready var Server = get_parent()

const MAX_PLAYERS = 8

var instance_id: String

var host_id: int
var player_ids = []
var player_names = []

var in_lobby_player_ids = [] # Lobby updates are sent to omly players that are in the lobby
var lobby_names = {}
var ready_clients = 0
var in_game = false

func _ready():
	host_id = -1

#
# Lobby Management
#
func add_player(player_id, player_name):
	# Validate
	if in_game:
		Server.send_error(player_id, "Game in Progress, try again later")
		return
	if player_ids.size() >= MAX_PLAYERS:
		Server.send_error(player_id, "Game is Full")
		return

	# Determine Player name
	player_name = player_name.strip_edges()
	if !lobby_names.has(player_name):
		lobby_names[player_name] = 0
	else:
		lobby_names[player_name] += 1
		player_name = player_name.substr(0,8) + " (" + str(lobby_names[player_name]) + ")"

	# Add to Game
	player_ids.append(player_id)
	player_names.append(player_name)
	if host_id == -1:
		host_id = player_id

	# Start Lobby on Client
	Server.start_lobby(player_id, instance_id, host_id == player_id)
	# Update Clients with latest Lobby
	Server.sync_lobby(in_lobby_player_ids, player_names, Rules.to_dict())
	print("%s: %s" % [instance_id, player_names])

func remove_player(player_id) -> bool:
	var idx = player_ids.find(player_id)
	player_ids.remove(idx)
	player_names.remove(idx)
	in_lobby_player_ids.erase(player_id)

	Server.sync_lobby(in_lobby_player_ids, player_names, Rules.to_dict())
	print("%s: %s" % [instance_id, player_names])
	return player_ids.size() > 0

func update_rules(rules):
	Rules.load_from_dict(rules)
	Server.sync_lobby(in_lobby_player_ids, player_names, Rules.to_dict())

func lobby():
	in_lobby_player_ids = []
	in_game = false
	for player_id in player_ids:
		Server.start_lobby(player_id, instance_id, host_id == player_id)

func client_lobby_ready(player_id):
	in_lobby_player_ids.append(player_id)
	Server.sync_lobby([player_id], player_names, Rules.to_dict())

#
# Game Setup
#
func start_game():
	in_lobby_player_ids = []
	in_game = true
	GameServer.reset_game()

	Rules.NUM_PLAYERS = player_ids.size()
	for i in range(player_ids.size()):
		Server.set_player(player_ids[i], i)

		var player = GameState.Player.new()
		player.name = player_names[i]
		GameState.players.append(player)
	
	ready_clients = 0
	print("%s: Waiting for clients to ready" % instance_id)
	Server.request_start(player_ids, Rules.to_dict())

func client_game_ready():
	ready_clients += 1
	if ready_clients == player_ids.size():
		print("%s: Starting Game" % instance_id)
		GameServer.start_game()
	else:
		print("%s: Waiting for %s clients" % [instance_id, (player_ids.size() - ready_clients)])

#
# Game To Client
#
func emit_game_won(player):
	Server.emit_game_won(player_ids, player)

func emit_game_start():
	Server.emit_game_start(player_ids, GameState.to_dict())

func emit_game_update():
	Server.emit_game_update(player_ids, GameState.to_dict())

func emit_cards_drawn(player, cards):
	var drawn_cards = []
	for card in cards:
		drawn_cards.append(card.to_dict())
	Server.emit_cards_drawn(player_ids, player, drawn_cards)

func emit_card_played(player, card):
	Server.emit_card_played(player_ids, player, card.to_dict())

func emit_event(event_type, player):
	Server.emit_event(player_ids, event_type, player)

func request_wild_pick(player):
	Server.request_wild_pick(player_ids[player], player)

#
# Client To Game
#
signal play_request(player, card)
signal draw_request(player)
signal uno_request(player)
signal wild_pick(colour)

func request_play_card(player, card):
	emit_signal("play_request", player, CardBase.new().load_from_dict(card))

func request_draw_card(player):
	emit_signal("draw_request", player)

func request_uno(player):
	emit_signal("uno_request", player)

func wild_pick(colour):
	emit_signal("wild_pick", colour)
