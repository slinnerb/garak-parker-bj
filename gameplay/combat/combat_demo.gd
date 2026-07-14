class_name CombatDemo
extends RefCounted
## Builds demo combats from real content (Phase 3b/4).
##
## Until the run map (Phase 5) supplies encounters, this assembles a fight so the
## combat screen has something to show. Phase 4 wired it to the real item->deck
## path: the player's deck is derived from an Attunement (attuned items), not a
## hardcoded card list. The demo carries a handful of coastal items and attunes a
## default subset; the attunement screen lets the player change that before the
## fight, previewing the "equipment IS the deck" rule.

const DEMO_ARCHETYPE := "coastal_drifter"
const DEMO_ENEMY := "brine_soaked_villager"

## The items the demo body is carrying (a stand-in for a life's worth of
## scavenging until the run map hands out loot). More than fits the slots, so
## attunement is a real choice.
const CARRIED_ITEMS := [
	"rusted_harpoon", "oilskin_coat", "storm_lantern", "fishermans_gaff",
	"net_of_woven_hair", "tincture_of_salt", "barnacle_crusted_shield",
	"whale_ivory_charm", "abyssal_fishhook",
]

## The loadout the demo starts attuned (six 1-slot items = the default 6 slots).
const DEFAULT_ATTUNED := [
	"rusted_harpoon", "oilskin_coat", "storm_lantern",
	"fishermans_gaff", "net_of_woven_hair", "tincture_of_salt",
]


## The carried inventory the attunement screen presents.
static func carried_inventory(content) -> Inventory:
	var inv := Inventory.new()
	for item_id in CARRIED_ITEMS:
		var item: ItemDefinition = content.get_def("item", item_id)
		if item != null:
			inv.add(item)
	return inv


## A fresh attunement seeded with the default loadout.
static func default_attunement(content) -> Attunement:
	var archetype = content.get_def("body_archetype", DEMO_ARCHETYPE)
	var att := Attunement.new(archetype.base_slots if archetype != null else 6)
	for item_id in DEFAULT_ATTUNED:
		var item: ItemDefinition = content.get_def("item", item_id)
		if item != null:
			att.attune(item)
	return att


## Default demo fight (used when combat is entered directly, e.g. the screenshot
## tool). Equivalent to attuning DEFAULT_ATTUNED against DEMO_ENEMY.
static func build(content, rng: RngStream) -> CombatState:
	return build_from(content, rng, DEMO_ARCHETYPE, DEFAULT_ATTUNED, DEMO_ENEMY)


## Builds a combat from an archetype, an attuned-item list, and an enemy. The
## deck is derived from the attuned items via Attunement.build_deck, then shuffled
## with the combat RNG. Returns null if the archetype or enemy is missing.
static func build_from(content, rng: RngStream, archetype_id: String, attuned_item_ids: Array, enemy_id: String) -> CombatState:
	var archetype = content.get_def("body_archetype", archetype_id)
	var enemy_def = content.get_def("enemy", enemy_id)
	if archetype == null or enemy_def == null:
		return null

	var att := Attunement.new(archetype.base_slots)
	for item_id in attuned_item_ids:
		var item: ItemDefinition = content.get_def("item", item_id)
		if item != null:
			att.attune(item)

	var player := PlayerState.new("player", archetype.display_name, archetype.base_hp, archetype.base_energy, 5)
	var deck := att.build_deck(content)
	rng.shuffle(deck)
	for card in deck:
		player.add_to_draw_pile(card)

	var enemy := EnemyState.from_definition(enemy_def, rng)
	return CombatState.new(content, rng, player, [enemy])
