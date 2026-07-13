class_name CardDefinition
extends ContentDefinition
## A playable card (Phase 2 data model, registry type "card").
##
## Cards come from things, not from thin air (docs/GAME_VISION.md pillar 2):
## every real card names the physical item that granted it via
## source_item_id. The only cards allowed to exist without a source item are
## status/curse junk and transient cards tagged "generated" (conjured
## mid-combat by effects, never part of a permanent deck).
##
## Behavior is composed from CardEffectDefinition atoms — no per-card scripts.

const CARD_TYPES := ["attack", "skill", "power", "status", "curse"]
const TARGETING := ["none", "self", "enemy", "all_enemies", "random_enemy"]

var card_type: String = "skill"
var energy_cost: int = 1
var targeting: String = "none"
## The item this card was granted by. Empty only for status/curse cards and
## effect-generated cards (tags contains "generated").
var source_item_id: String = ""
var effects: Array[CardEffectDefinition] = []
var rarity: String = "common"
var exhaust: bool = false
var retain: bool = false
var temporary: bool = false
var consumable: bool = false
var universe_theme: String = ""
var art_ref: String = ""


func type_name() -> String:
	return TYPE_CARD


static func from_dict(d: Dictionary) -> CardDefinition:
	var def := CardDefinition.new()
	def._apply_base(d)
	def.card_type = str(d.get("card_type", "skill"))
	def.energy_cost = int(d.get("energy_cost", 1))
	def.targeting = str(d.get("targeting", "none"))
	def.source_item_id = str(d.get("source_item_id", ""))
	for e in to_dict_array(d.get("effects", [])):
		def.effects.append(CardEffectDefinition.from_dict(e))
	def.rarity = str(d.get("rarity", "common"))
	def.exhaust = bool(d.get("exhaust", false))
	def.retain = bool(d.get("retain", false))
	def.temporary = bool(d.get("temporary", false))
	def.consumable = bool(d.get("consumable", false))
	def.universe_theme = str(d.get("universe_theme", ""))
	def.art_ref = str(d.get("art_ref", ""))
	return def


func validate(registry) -> Array[String]:
	var problems := super.validate(registry)
	_check_in_set(card_type, CARD_TYPES, "card_type", problems)
	if energy_cost < 0 or energy_cost > 9:
		problems.append(_ctx("field 'energy_cost' must be between 0 and 9 (got %d)" % energy_cost))
	_check_in_set(targeting, TARGETING, "targeting", problems)
	if source_item_id.is_empty():
		# Core design rule: every real card originates from a physical item.
		var exempt := card_type == "status" or card_type == "curse" or tags.has("generated")
		if not exempt:
			problems.append(_ctx("field 'source_item_id' is empty (only status/curse cards or cards tagged 'generated' may lack a source item)"))
	else:
		_check_ref(registry, TYPE_ITEM, source_item_id, "source_item_id", problems)
	# Status/curse cards may be pure dead weight; everything else must act.
	if effects.is_empty() and card_type != "status" and card_type != "curse":
		problems.append(_ctx("field 'effects' is empty (only status and curse cards may do nothing)"))
	var shown_id := id if not id.is_empty() else "<no id>"
	for i in effects.size():
		problems.append_array(effects[i].validate(registry, "card:%s effect#%d" % [shown_id, i]))
	_check_in_set(rarity, RARITIES, "rarity", problems)
	return problems
