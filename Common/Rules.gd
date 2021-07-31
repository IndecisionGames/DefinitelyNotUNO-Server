extends Node
# The following code should be identical in both the client and server

var NUM_PLAYERS = 4

var INTERRUPT = false
var UNO_CARD_PENALTY = 1
# Not implemented
const PICKUP_STACKING = false
const PLAY_AFTER_DRAW = false
const DRAW_UNTIL_PLAY = false

# Generation Rules
const STARTING_HAND_SIZE = 7
const NUM_EACH_CARD = 2
const NUM_EACH_WILD_CARD = 4

const standard_types = [
	Types.card_type.CARD_0, 
	Types.card_type.CARD_1, 
	Types.card_type.CARD_2, 
	Types.card_type.CARD_3, 
	Types.card_type.CARD_4, 
	Types.card_type.CARD_5, 
	Types.card_type.CARD_6, 
	Types.card_type.CARD_7, 
	Types.card_type.CARD_8, 
	Types.card_type.CARD_9, 
	Types.card_type.CARD_SKIP, 
	Types.card_type.CARD_REVERSE, 
	Types.card_type.CARD_PLUS2
]
const standard_colours = [
	Types.card_colour.RED, 
	Types.card_colour.GREEN, 
	Types.card_colour.BLUE, 
	Types.card_colour.YELLOW
]
const wild_types = [
	Types.card_type.CARD_PLUS4, 
	Types.card_type.CARD_WILD
]

func to_dict():
	return {
		"NUM_PLAYERS": NUM_PLAYERS,
		"INTERRUPT": INTERRUPT,
		"UNO_CARD_PENALTY": UNO_CARD_PENALTY,
	}

func load_from_dict(dict):
	NUM_PLAYERS = dict.get("NUM_PLAYERS")
	INTERRUPT = dict.get("INTERRUPT")
	UNO_CARD_PENALTY = dict.get("UNO_CARD_PENALTY")
