extends Node
# The following code should be identical in both the client and server

const CardBase = preload("res://Common/CardBase.gd")

onready var Server = get_parent()

# Server only GameState values
var deck = []
var play_pile = []
var wild_opening: bool
var empty_game_state

var rng = RandomNumberGenerator.new()

func _ready():
	Server.connect("play_request", self, "_play_card")
	Server.connect("draw_request", self, "_draw_cards")
	Server.connect("uno_request", self, "_on_uno_request")
	Server.connect("wild_pick", self, "_on_wild_pick")
	empty_game_state = GameState.to_dict()

func reset_game():
	GameState.load_from_dict(empty_game_state)

# Generation
func start_game():
	randomize()
	_generate_deck()
	_generate_hands()

	GameState.current_player = rng.randi_range(0, Rules.NUM_PLAYERS-1)
	_play_card(GameState.current_player, _draw()[0], true)
	Server.emit_game_start()

func _generate_deck():
	deck = []
	for colour in standard_colours:
		for type in standard_cards:
			for _i in range(standard_cards[type]):
				var new_card = CardBase.new()
				new_card.setup(colour, type)
				deck.append(new_card)

	for type in wild_cards:
		for _i in range(wild_cards[type]):
			var new_card = CardBase.new()
			new_card.setup(Types.card_colour.WILD, type)
			deck.append(new_card)

	deck.shuffle()

func _generate_hands():
	for i in range(Rules.NUM_PLAYERS):
		GameState.players[i].cards = _draw(STARTING_HAND_SIZE)

# Generation Rules
const STARTING_HAND_SIZE = 7

const standard_colours = [
	Types.card_colour.RED,
	Types.card_colour.GREEN,
	Types.card_colour.BLUE,
	Types.card_colour.YELLOW
]

const standard_cards = {
	Types.card_type.CARD_0: 1,
	Types.card_type.CARD_1: 2,
	Types.card_type.CARD_2: 2,
	Types.card_type.CARD_3: 2,
	Types.card_type.CARD_4: 2,
	Types.card_type.CARD_5: 2,
	Types.card_type.CARD_6: 2,
	Types.card_type.CARD_7: 2,
	Types.card_type.CARD_8: 2,
	Types.card_type.CARD_9: 2,
	Types.card_type.CARD_SKIP: 2,
	Types.card_type.CARD_REVERSE: 2,
	Types.card_type.CARD_PLUS2: 2,
}

const wild_cards = {
	Types.card_type.CARD_PLUS4: 4,
	Types.card_type.CARD_WILD: 4,
}

# Game
func _play_card(player, card: CardBase, opening_card = false):
	if !opening_card and !GameState.is_playable(player, card):
		print("this card can not be played")
		return

	# Lock to prevent other players from playing
	GameState.play_in_progress = true
	Server.emit_game_update()

	if player != GameState.current_player:
		Server.emit_event(Types.event.JUMP_IN, player)

	GameState.current_player = player
	GameState.current_card_type  = card.type
	GameState.current_card_colour = card.colour

	# Card specific OnPlay effects
	if GameState.current_card_type == Types.card_type.CARD_SKIP:
		Server.emit_event(Types.event.SKIP, GameState.current_player)
		GameState.skip_required = true

	if GameState.current_card_type == Types.card_type.CARD_REVERSE:
		Server.emit_event(Types.event.REVERSE, GameState.current_player)
		GameState.play_order_clockwise = !GameState.play_order_clockwise

	if GameState.current_card_type == Types.card_type.CARD_PLUS2 or GameState.current_card_type == Types.card_type.CARD_PLUS4:
		if GameState.pickup_required:
			Server.emit_event(Types.event.STACK_CARD, GameState.current_player)
		GameState.pickup_required = true

		if GameState.current_card_type == Types.card_type.CARD_PLUS2:
			GameState.pickup_type = Types.pickup_type.PLUS2
			GameState.pickup_count += 2

		if GameState.current_card_type == Types.card_type.CARD_PLUS4:
			GameState.pickup_type = Types.pickup_type.PLUS4
			GameState.pickup_count += 4

	if GameState.current_card_colour == Types.card_colour.WILD:
		GameState.waiting_action = true
		Server.request_wild_pick(player)

	play_pile.append(card)
	# TODO: Rework Opening Card special cases
	if opening_card:
		GameState.play_in_progress = false
		# Special cases
		if GameState.skip_required: # Skip shoud move to the next turn but only skip 1 player
			GameState.skip_required = false
			_turn_end()
		if GameState.current_card_colour == Types.card_colour.WILD: # Picking Wild should not end the turn
			wild_opening = true
		return

	var idx = card.is_in(GameState.get_current_player().cards)
	GameState.get_current_player().cards.remove(idx)
	Server.emit_card_played(GameState.current_player, card)
	_turn_end()

func _draw_cards(player):
	var forced_pickup = GameState.pickup_count > 0
	var cards = _draw(max(1,GameState.pickup_count))
	GameState.players[player].cards.append_array(cards)
	Server.emit_cards_drawn(player, cards)

	GameState.players[player].uno_status = false
	GameState.pickup_required = false
	GameState.pickup_type = Types.pickup_type.NULL
	GameState.pickup_count = 0
	
	# Allow player to play newly drawn card
	if Rules.PLAY_AFTER_DRAW and !forced_pickup and GameState.is_playable(player, cards[0]):
		GameState.play_in_progress = false
		Server.emit_game_update()
		return 

	_turn_end()

func _turn_end():
	# Prevent turn end if waiting for input
	if GameState.waiting_action:
		Server.emit_game_update()
		return

	# Automatic Uno Penalty 
	if GameState.get_current_player().cards.size() == 1 && !GameState.get_current_player().uno_status:
		var cards = _draw(Rules.UNO_CARD_PENALTY)
		Server.emit_event(Types.event.UNO_PENALTY, GameState.current_player)
		GameState.get_current_player().cards.append_array(cards)
		Server.emit_cards_drawn(GameState.current_player, cards)

	var turn_increment = 1

	# Card specific OnTurnEnd effects
	if GameState.skip_required:
		GameState.skip_required = false
		turn_increment = 2

	for _i in range(turn_increment):
		if GameState.play_order_clockwise:
			GameState.current_player += 1
		else:
			GameState.current_player -= 1

		if GameState.current_player >= Rules.NUM_PLAYERS:
			GameState.current_player -= Rules.NUM_PLAYERS
		if GameState.current_player < 0:
			GameState.current_player += Rules.NUM_PLAYERS

	GameState.play_in_progress = false
	Server.emit_game_update()
	_check_win()

func _draw(num_to_draw = 1):
	var drawn = []
	for _i in range(num_to_draw):
		if len(deck) <= 1:	# refresh cards with play_pile if running out
			while play_pile.size() > 1:
				deck.append(play_pile.pop_front())
			deck.shuffle()

		drawn.append(deck.pop_front())
	return drawn

func _check_win():
	for i in range(GameState.players.size()):
		if GameState.players[i].cards.size() == 0:
			GameState.play_in_progress = true
			Server.emit_game_won(i)
			return

# Player signals
func _on_wild_pick(colour):
	GameState.waiting_action = false
	GameState.current_card_colour = colour
	if wild_opening:
		wild_opening = false
		Server.emit_game_update()
		return
	_turn_end()

func _on_uno_request(player):
	GameState.players[player].uno_status = true
	Server.emit_event(Types.event.UNO, player)
	Server.emit_game_update()
