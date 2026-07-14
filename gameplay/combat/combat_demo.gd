class_name CombatDemo
extends RefCounted
## Builds a self-contained demo combat from real content (Phase 3b).
##
## Until inventory/attunement (Phase 4) derives the deck from carried items and
## the run map (Phase 5) supplies encounters, the combat screen needs some way
## to start a fight. This assembles one from the starting body archetype: the
## deck is the cards its starting items grant (a few copies each for a playable
## size), and the opponent is a normal coastal enemy. It previews the item->deck
## idea honestly without pretending the surrounding systems exist yet.

const COPIES_PER_CARD := 3
const DEMO_ARCHETYPE := "coastal_drifter"
const DEMO_ENEMY := "brine_soaked_villager"


## Returns a ready-to-start CombatState, or null if the expected content is
## missing (which would already have failed content validation at boot).
static func build(content, rng: RngStream) -> CombatState:
	var archetype = content.get_def("body_archetype", DEMO_ARCHETYPE)
	var enemy_def = content.get_def("enemy", DEMO_ENEMY)
	if archetype == null or enemy_def == null:
		return null

	var player := PlayerState.new("player", archetype.display_name, archetype.base_hp, archetype.base_energy, 5)
	for item_id in archetype.starting_item_ids:
		var item = content.get_def("item", item_id)
		if item == null:
			continue
		for card_id in item.granted_card_ids:
			var card_def = content.get_def("card", card_id)
			if card_def == null:
				continue
			for _copy in COPIES_PER_CARD:
				player.add_to_draw_pile(CardInstance.new(card_def))
	rng.shuffle(player.draw_pile)

	var enemy := EnemyState.from_definition(enemy_def, rng)
	return CombatState.new(content, rng, player, [enemy])
