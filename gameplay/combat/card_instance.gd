class_name CardInstance
extends RefCounted
## A single card as it exists inside a combat (Phase 3 combat).
##
## The immutable rules live in the shared CardDefinition; this wraps one copy
## that moves between the draw pile, hand, discard, and exhaust piles. Runtime,
## per-copy state (temporary conjured cards, later: in-combat upgrades) lives
## here so the definition stays shared and unmutated.

var definition: CardDefinition
## Conjured mid-combat and never kept: removed from play entirely (not sent to
## discard) when it leaves the hand. Seeded from the definition but can also be
## forced on for cards spawned by effects/statuses.
var temporary: bool = false


func _init(card_def: CardDefinition, force_temporary: bool = false) -> void:
	definition = card_def
	temporary = force_temporary or (card_def != null and card_def.temporary)


func id() -> String:
	return definition.id if definition != null else ""


func display_name() -> String:
	return definition.display_name if definition != null else ""


func energy_cost() -> int:
	return definition.energy_cost if definition != null else 0


## Status and curse cards are unplayable clutter — they occupy the hand but have
## no play action (matches their "Unplayable" flavor). Everything else is playable.
func is_playable() -> bool:
	if definition == null:
		return false
	return definition.card_type != "status" and definition.card_type != "curse"


## True if the card leaves for the exhaust pile after being played.
func exhausts() -> bool:
	return definition != null and definition.exhaust


## True if the card stays in hand at end of turn instead of being discarded.
func retains() -> bool:
	return definition != null and definition.retain
