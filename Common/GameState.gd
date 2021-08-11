extends Node
# The following code should be identical in both the client and server

const CardBase = preload("res://Common/CardBase.gd")

class Player:
	var name: String
	var cards = []
	var uno_status: bool

var players = []

# Play Checks
var current_player: int
var current_card_type: int
var current_card_colour: int
var play_in_progress = false

# Wild
var waiting_action = false
# Reverse
var play_order_clockwise = true
# Skip
var skip_required = false
# Plus2 / Plus4
var pickup_required = false
var pickup_type = 0
var pickup_count = 0

func is_playable(player, proposed_card: CardBase) -> bool:
	if play_in_progress or waiting_action:
		return false

	if player != current_player:
		if Rules.JUMP_IN:
			# TODO: Stop from affecting player who has started turn. Otherwise someone could play mid/post draw
			if proposed_card.type == current_card_type and proposed_card.colour == current_card_colour:
				return true
		return false

	if pickup_required:
		# Require matching Plus 2
		if pickup_type == Types.pickup_type.PLUS2:
			if proposed_card.type == Types.card_type.CARD_PLUS2 or (Rules.STACK_PLUS4_ON_PLUS2 and Types.card_type.CARD_PLUS4):
				return true
		# Require matching Plus 4
		if pickup_type == Types.pickup_type.PLUS4:
			if proposed_card.type == Types.card_type.CARD_PLUS4:
				return true
		return false

	if proposed_card.type == current_card_type:
		return true
	if proposed_card.colour == current_card_colour or proposed_card.colour == Types.card_colour.WILD:
		return true

	return false

func get_current_player():
	return players[current_player]

# TODO: improve player and card storage and to_dict conversion
func to_dict():
	var players_dict = []
	for player in players:
		var card_dict = []
		for card in player.cards:
			card_dict.append(card.to_dict())
		players_dict.append(
			{ 
				"name": player.name,
				"cards": card_dict,
				"uno_status": player.uno_status,
			}
		)

	return {
		"current_player": current_player,
		"current_card_type": current_card_type,
		"current_card_colour": current_card_colour,
		"play_in_progress": play_in_progress,
		"waiting_action": waiting_action,
		"play_order_clockwise": play_order_clockwise,
		"skip_required": skip_required,
		"pickup_required": pickup_required,
		"pickup_type": pickup_type,
		"pickup_count": pickup_count,
		"players": players_dict,
	}

func load_from_dict(dict):
	current_player = dict.get("current_player")
	current_card_type = dict.get("current_card_type")
	current_card_colour = dict.get("current_card_colour")
	play_in_progress = dict.get("play_in_progress")
	waiting_action = dict.get("waiting_action")
	play_order_clockwise = dict.get("play_order_clockwise")
	skip_required = dict.get("skip_required")
	pickup_required = dict.get("pickup_required")
	pickup_type = dict.get("pickup_type")
	pickup_count = dict.get("pickup_count")

	var players_dict = dict.get("players")
	players = []
	for player in players_dict:
		var new_player = Player.new()
		new_player.name = player.get("name")
		new_player.uno_status = player.get("uno_status")
		
		var card_dict = player.get("cards")
		for card in card_dict:
			new_player.cards.append(CardBase.new().load_from_dict(card))

		players.append(new_player)
