class_name PlayerState
extends Combatant
## The player's combat state (Phase 3 combat): a Combatant plus energy and the
## four card piles that make up the deckbuilder loop.
##
## Pile discipline: cards flow draw_pile -> hand -> discard_pile, exhaust_pile is
## a one-way sink for the combat, and temporary cards vanish instead of going to
## discard. When the draw pile empties mid-draw, the discard is shuffled back in
## using the combat RNG stream so reshuffles stay reproducible.
##
## In Phase 4 the deck is derived from attuned items; for now callers build it
## by pushing CardInstances into the draw pile.

var max_energy: int = 3
var energy: int = 3
## Cards drawn at the start of each turn.
var hand_size: int = 5

var hand: Array[CardInstance] = []
var draw_pile: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var exhaust_pile: Array[CardInstance] = []


func _init(player_id: String = "player", name: String = "Wanderer", maximum_hp: int = 70, energy_per_turn: int = 3, cards_per_turn: int = 5) -> void:
	super(player_id, name, maximum_hp)
	max_energy = maxi(0, energy_per_turn)
	energy = max_energy
	hand_size = maxi(1, cards_per_turn)


func refill_energy() -> void:
	energy = max_energy


## Puts a card at the bottom of the draw pile (used when building the deck).
func add_to_draw_pile(card: CardInstance) -> void:
	draw_pile.push_front(card)


## Draws up to `count` cards, reshuffling the discard into the draw pile when it
## runs dry. Returns how many were actually drawn (fewer if both piles empty).
func draw(count: int, rng: RngStream) -> int:
	var drawn := 0
	for _i in count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			_reshuffle_discard_into_draw(rng)
		hand.append(draw_pile.pop_back())
		drawn += 1
	return drawn


## End-of-turn cleanup: retained cards stay, temporary cards vanish, the rest go
## to discard.
func discard_hand() -> void:
	var kept: Array[CardInstance] = []
	for card in hand:
		if card.retains():
			kept.append(card)
		elif card.temporary:
			pass  # conjured card leaves play entirely
		else:
			discard_pile.append(card)
	hand = kept


## Routes a just-played card out of the hand: exhaust pile, gone (temporary), or
## discard. The card must already be removed from `hand` by the caller.
func route_played(card: CardInstance) -> void:
	if card.exhausts():
		exhaust_pile.append(card)
	elif card.temporary:
		pass  # vanishes
	else:
		discard_pile.append(card)


func total_cards() -> int:
	return hand.size() + draw_pile.size() + discard_pile.size() + exhaust_pile.size()


func _reshuffle_discard_into_draw(rng: RngStream) -> void:
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile.clear()
	rng.shuffle(draw_pile)
