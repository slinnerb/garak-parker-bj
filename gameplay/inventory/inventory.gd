class_name Inventory
extends RefCounted
## The items a body is carrying this life (Phase 4).
##
## Just the bag — every item the character has found or started with. Which of
## these are equipped for combat is the Attunement's concern; the deck is derived
## from the attuned subset, not from everything carried. Lost at death with the
## rest of the body (docs/GAME_VISION.md).
##
## Holds ItemDefinition references (shared, immutable content). Ids are unique
## within the bag — the same physical item isn't carried twice.

var _items: Array[ItemDefinition] = []


## Adds an item unless an item with the same id is already carried. Returns
## whether it was added.
func add(item: ItemDefinition) -> bool:
	if item == null or has(item.id):
		return false
	_items.append(item)
	return true


## Removes the item with this id (e.g. consumed, broken, dropped). Returns
## whether something was removed.
func remove(item_id: String) -> bool:
	for i in _items.size():
		if _items[i].id == item_id:
			_items.remove_at(i)
			return true
	return false


func has(item_id: String) -> bool:
	return get_item(item_id) != null


func get_item(item_id: String) -> ItemDefinition:
	for item in _items:
		if item.id == item_id:
			return item
	return null


## All carried items, in the order they were added (stable for display).
func all() -> Array[ItemDefinition]:
	return _items


func size() -> int:
	return _items.size()
