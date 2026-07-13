class_name ItemDefinition
extends ContentDefinition
## Definition for a physical item (Phase 2 data model).
##
## Items are the heart of the deck: every real card is granted by a physical
## item the character carries (see docs/GAME_VISION.md), so an item either
## grants cards, carries passive modifiers, or is a quest marker — an item
## that does none of those is dead data and fails validation.
##
## Pure data + validation, per the ContentDefinition pattern: from_dict()
## coerces defensively, validate() reports problems, registry may be null.

## Broad gameplay role. Open-ended content lives in tags; the category set is
## closed because systems (slots, curses, shops) branch on it.
const CATEGORIES := ["weapon", "defensive", "tool", "charm", "relic", "consumable", "forbidden", "quest", "soulbound"]

var category: String = ""
## Inventory slots consumed while carried (0..4). Only quest items may be
## weightless — everything else competes for the body's limited slots.
var slot_cost: int = 1
var granted_card_ids: Array[String] = []
## Always-on effects while carried; each entry needs at least a "kind" key.
var passive_modifiers: Array[Dictionary] = []
var cursed: bool = false
var removable: bool = true
## Uses before the item is spent. -1 means unlimited; consumables must set a
## positive count (a consumable that never runs out isn't a consumable).
var charges: int = -1
var rarity: String = "common"
var universe_availability: Array[String] = ["*"]
var art_ref: String = ""


func type_name() -> String:
	return ContentDefinition.TYPE_ITEM


static func from_dict(d: Dictionary) -> ItemDefinition:
	var def := ItemDefinition.new()
	def._apply_base(d)
	def.category = str(d.get("category", ""))
	def.slot_cost = int(d.get("slot_cost", 1))
	def.granted_card_ids = ContentDefinition.to_string_array(d.get("granted_card_ids", []))
	def.passive_modifiers = ContentDefinition.to_dict_array(d.get("passive_modifiers", []))
	def.cursed = bool(d.get("cursed", false))
	def.removable = bool(d.get("removable", true))
	def.charges = int(d.get("charges", -1))
	def.rarity = str(d.get("rarity", "common"))
	def.universe_availability = ContentDefinition.to_string_array(d.get("universe_availability", ["*"]))
	def.art_ref = str(d.get("art_ref", ""))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	_check_in_set(category, CATEGORIES, "category", problems)
	if slot_cost < 0 or slot_cost > 4:
		problems.append(_ctx("slot_cost %d out of range (0..4)" % slot_cost))
	elif slot_cost == 0 and category != "quest":
		problems.append(_ctx("slot_cost 0 is only allowed for quest items"))
	for card_id in granted_card_ids:
		if card_id.is_empty():
			# _check_ref skips empty ids, so catch the malformed entry here.
			problems.append(_ctx("granted_card_ids contains an empty id"))
		else:
			_check_ref(registry, ContentDefinition.TYPE_CARD, card_id, "granted_card_ids", problems)
	for i in passive_modifiers.size():
		var kind = passive_modifiers[i].get("kind", "")
		if not (kind is String) or (kind as String).is_empty():
			problems.append(_ctx("passive_modifiers[%d] is missing a non-empty String 'kind'" % i))
	# An item must do something: grant cards, modify passively, or mark a quest.
	if granted_card_ids.is_empty() and passive_modifiers.is_empty() and category != "quest":
		problems.append(_ctx("item grants no cards and has no passive_modifiers (only quest items may be inert)"))
	if category == "consumable":
		if charges < 1:
			problems.append(_ctx("consumable items require charges >= 1 (got %d)" % charges))
	elif charges != -1 and charges < 1:
		problems.append(_ctx("charges must be -1 (unlimited) or >= 1 (got %d)" % charges))
	_check_in_set(rarity, ContentDefinition.RARITIES, "rarity", problems)
	_check_universe_availability(registry, universe_availability, problems)
	return problems
