extends Node
# The following code should be identical in both the client and server

var NUM_PLAYERS = 4

var UNO_CARD_PENALTY = 2
var PLAY_AFTER_DRAW = true
var JUMP_IN = false
var STACK_PLUS4_ON_PLUS2 = false
# Not implemented
const DRAW_UNTIL_PLAY = false
const ROTATE_HANDS_0 = false
const SWAP_HANDS_7 = false

func to_dict():
	return {
		"NUM_PLAYERS": NUM_PLAYERS,
		"UNO_CARD_PENALTY": UNO_CARD_PENALTY,
		"PLAY_AFTER_DRAW": PLAY_AFTER_DRAW, 
		"JUMP_IN": JUMP_IN,
		"STACK_PLUS4_ON_PLUS2": STACK_PLUS4_ON_PLUS2,
	}

func load_from_dict(dict):
	NUM_PLAYERS = dict.get("NUM_PLAYERS")
	UNO_CARD_PENALTY = dict.get("UNO_CARD_PENALTY")
	PLAY_AFTER_DRAW = dict.get("PLAY_AFTER_DRAW")
	JUMP_IN = dict.get("JUMP_IN")
	STACK_PLUS4_ON_PLUS2 = dict.get("STACK_PLUS4_ON_PLUS2")
