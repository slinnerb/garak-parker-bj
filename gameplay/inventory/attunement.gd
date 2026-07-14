class_name Attunement
extends RefCounted
## Attunement slots — the equipped-item loadout that IS the combat deck (Phase 4).
##
## The central design rule: equipment and deckbuilding are two views of one
## system (master prompt §5). The character may carry many items, but only a
## limited number of slots' worth may be attuned; the attuned set generates the
## active deck, and the deck changes predictably whenever an item is attuned or
## removed.
##
## Slot rules:
##   - Each item costs slot_cost slots; the total may not exceed capacity.
##   - An item can't be attuned twice.
##   - Cursed items (removable == false) resist removal once attuned.
##   - Consumable items contribute `charges` copies of their card (limited use);
##     other items contribute one copy of each granted card.
##   - Passive relics grant no cards but contribute passive modifiers.
##
## Pure domain state: content is passed in only where card definitions must be
## resolved (build_deck), so slot logic stays unit-testable without a registry.

var capacity: int = 6
var _attuned: Array[ItemDefinition] = []


func _init(slot_capacity: int = 6) -> void:
	capacity = maxi(0, slot_capacity)


# ---------------------------------------------------------------------------
# Slots
# ---------------------------------------------------------------------------

func used_slots() -> int:
	var total := 0
	for item in _attuned:
		total += item.slot_cost
	return total


func free_slots() -> int:
	return capacity - used_slots()


func is_attuned(item_id: String) -> bool:
	for item in _attuned:
		if item.id == item_id:
			return true
	return false


func attuned_items() -> Array[ItemDefinition]:
	return _attuned


# ---------------------------------------------------------------------------
# Attune / remove
# ---------------------------------------------------------------------------

## True if the item can be attuned right now (not already attuned, and it fits
## the remaining slots).
func can_attune(item: ItemDefinition) -> bool:
	if item == null or is_attuned(item.id):
		return false
	return item.slot_cost <= free_slots()


## Attunes the item if it fits. Returns whether it was attuned.
func attune(item: ItemDefinition) -> bool:
	if not can_attune(item):
		return false
	_attuned.append(item)
	return true


## Cursed items refuse to leave (removable == false). Everything else can be
## unattuned freely.
func can_unattune(item_id: String) -> bool:
	var item := _find(item_id)
	return item != null and item.removable


## Removes an attuned item unless it's cursed. Returns whether it was removed.
func unattune(item_id: String) -> bool:
	if not can_unattune(item_id):
		return false
	for i in _attuned.size():
		if _attuned[i].id == item_id:
			_attuned.remove_at(i)
			return true
	return false


# ---------------------------------------------------------------------------
# Deck derivation — the point of the whole class
# ---------------------------------------------------------------------------

## Builds the combat deck from the currently attuned items. Consumables add one
## copy per charge; other items add one copy per granted card. Passive relics
## (no granted cards) add nothing here — their effect is in passive_modifiers().
## Returns fresh CardInstances each call, so the deck rebuilds on any change.
func build_deck(content) -> Array[CardInstance]:
	var deck: Array[CardInstance] = []
	if content == null:
		return deck
	for item in _attuned:
		var copies := maxi(1, item.charges) if item.category == "consumable" else 1
		for card_id in item.granted_card_ids:
			var card_def = content.get_def(ContentDefinition.TYPE_CARD, card_id)
			if card_def == null:
				continue
			for _copy in copies:
				deck.append(CardInstance.new(card_def))
	return deck


## The passive modifiers contributed by attuned relics/items. Combat application
## of these lands in a later pass; collected here so the data isn't lost.
func passive_modifiers() -> Array:
	var mods: Array = []
	for item in _attuned:
		for mod in item.passive_modifiers:
			mods.append(mod)
	return mods


func _find(item_id: String) -> ItemDefinition:
	for item in _attuned:
		if item.id == item_id:
			return item
	return null
