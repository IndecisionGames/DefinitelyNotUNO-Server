extends Node
# The following code should be identical in both the client and server

var colour: int
var type: int

func setup(card_colour, card_type):
	colour = card_colour
	type = card_type

func to_dict():
	return {
		"colour": colour,
		"type": type,
	}

func load_from_dict(dict):
	colour = dict.get("colour")
	type = dict.get("type")
	return self

func is_in(cards):
	for i in range(cards.size()):
		if colour == cards[i].colour and type == cards[i].type:
			return i
	return -1

func _to_string():
	var colour_string = ""
	match self.colour:
		Types.card_colour.RED:
			colour_string = "red"
		Types.card_colour.GREEN:
			colour_string = "green"
		Types.card_colour.BLUE:
			colour_string = "blue"
		Types.card_colour.YELLOW:
			colour_string = "yellow"
		Types.card_colour.WILD:
			colour_string = "wild"
	return "%s %s" % [colour_string, type()]

func type() -> String:
	match self.type:
		Types.card_type.CARD_0:
			return "0"
		Types.card_type.CARD_1:
			return "1"
		Types.card_type.CARD_2:
			return "2"
		Types.card_type.CARD_3:
			return "2"
		Types.card_type.CARD_4:
			return "4"
		Types.card_type.CARD_5:
			return "5"
		Types.card_type.CARD_6:
			return "6"
		Types.card_type.CARD_7:
			return "7"
		Types.card_type.CARD_8:
			return "8"
		Types.card_type.CARD_9:
			return "9"
		Types.card_type.CARD_SKIP:
			return "Skip"
		Types.card_type.CARD_REVERSE:
			return "REVERSE"
		Types.card_type.CARD_PLUS2:
			return "+2"
		Types.card_type.CARD_PLUS4:
			return "+4"
		Types.card_type.CARD_WILD:
			return "Wild"
	return ""
