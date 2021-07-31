extends Node
# The following code should be identical in both the client and server

enum card_colour {
	RED, 
	GREEN, 
	BLUE, 
	YELLOW, 
	WILD,
}

enum card_type {
	CARD_0, 
	CARD_1, 
	CARD_2, 
	CARD_3, 
	CARD_4, 
	CARD_5, 
	CARD_6, 
	CARD_7, 
	CARD_8, 
	CARD_9, 
	CARD_SKIP, 
	CARD_REVERSE, 
	CARD_PLUS2, 
	CARD_PLUS4, 
	CARD_WILD,
}

enum pickup_type {
	NULL, 
	PLUS2, 
	PLUS4,
}
